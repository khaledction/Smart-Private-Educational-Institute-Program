import 'package:uuid/uuid.dart';

import '../models/models.dart';
import '../seed_data.dart';
import 'institute_repository.dart';

/// In-memory repository seeded with demo data.
/// Perfect for development, demos and UI work — no backend needed.
class MockInstituteRepository implements InstituteRepository {
  final _uuid = const Uuid();

  final List<Student> _students = List.of(SeedData.students);
  final List<Subject> _subjects = List.of(SeedData.subjects);
  final List<Teacher> _teachers = List.of(SeedData.teachers);
  final List<StudyGroup> _groups = List.of(SeedData.groups);
  final List<Registration> _registrations = List.of(SeedData.registrations);
  final List<DiscountRule> _discountRules = List.of(SeedData.discountRules);

  int _receiptCounter = 3;
  int _barcodeCounter = 1004;

  @override
  Future<List<Student>> getStudents() async => List.unmodifiable(_students);

  @override
  Future<List<Subject>> getSubjects() async => List.unmodifiable(_subjects);

  @override
  Future<List<Teacher>> getTeachers() async => List.unmodifiable(_teachers);

  @override
  Future<List<StudyGroup>> getGroups() async => List.unmodifiable(_groups);

  @override
  Future<List<Registration>> getRegistrations() async =>
      List.unmodifiable(_registrations);

  @override
  Future<List<DiscountRule>> getDiscountRules() async =>
      List.unmodifiable(_discountRules);

  // ── Administration: pricing ────────────────────────────────────────────

  @override
  Future<void> updateSubjectPricing({
    required String subjectId,
    required double basePrice,
    required int totalHours,
    required int durationMonths,
  }) async {
    final i = _subjects.indexWhere((s) => s.id == subjectId);
    if (i == -1) return;
    _subjects[i] = _subjects[i].copyWith(
      basePrice: basePrice,
      totalHours: totalHours,
      durationMonths: durationMonths,
    );
  }

  @override
  Future<void> updateTeacherSessionPrice({
    required String teacherId,
    required double sessionPrice,
  }) async {
    final i = _teachers.indexWhere((t) => t.id == teacherId);
    if (i == -1) return;
    _teachers[i] = _teachers[i].copyWith(sessionPrice: sessionPrice);
  }

  @override
  Future<void> updateGroupPriceOverride({
    required String groupId,
    double? priceOverride,
  }) async {
    final i = _groups.indexWhere((g) => g.id == groupId);
    if (i == -1) return;
    final g = _groups[i];
    _groups[i] = StudyGroup(
      id: g.id,
      subjectId: g.subjectId,
      teacherId: g.teacherId,
      schedule: g.schedule,
      maxCapacity: g.maxCapacity,
      enrolledCount: g.enrolledCount,
      priceOverride: priceOverride,
      label: g.label,
    );
  }

  // ── Administration: discounts ──────────────────────────────────────────

  @override
  Future<DiscountRule> addDiscountRule({
    required DiscountScope scope,
    required String targetId,
    required DiscountType type,
    required double value,
    String note = '',
  }) async {
    final rule = DiscountRule(
      id: _uuid.v4(),
      scope: scope,
      targetId: targetId,
      type: type,
      value: value,
      note: note,
      createdAt: DateTime.now(),
    );
    _discountRules.add(rule);
    return rule;
  }

  @override
  Future<void> setDiscountRuleActive(String ruleId, bool active) async {
    final i = _discountRules.indexWhere((r) => r.id == ruleId);
    if (i != -1) _discountRules[i] = _discountRules[i].copyWith(active: active);
  }

  @override
  Future<void> deleteDiscountRule(String ruleId) async {
    _discountRules.removeWhere((r) => r.id == ruleId);
  }

  @override
  Future<Student> addStudent({
    required String name,
    required String phone,
    String guardianName = '',
    String guardianPhone = '',
  }) async {
    _barcodeCounter++;
    final student = Student(
      id: _uuid.v4(),
      name: name,
      barcode: 'ST-$_barcodeCounter',
      phone: phone,
      guardianName: guardianName,
      guardianPhone: guardianPhone,
      createdAt: DateTime.now(),
    );
    _students.add(student);
    return student;
  }

  @override
  Future<RegistrationResult> register({
    required String studentId,
    required String groupId,
    required double price,
    required double discount,
    required double amountPaid,
  }) async {
    final idx = _groups.indexWhere((g) => g.id == groupId);
    if (idx == -1) return const RegistrationFailure('group_not_found');

    final group = _groups[idx];
    if (group.isFull) return const RegistrationFailure('group_full');

    final duplicate = _registrations
        .any((r) => r.studentId == studentId && r.groupId == groupId);
    if (duplicate) return const RegistrationFailure('already_registered');

    _receiptCounter++;
    final registration = Registration(
      id: _uuid.v4(),
      studentId: studentId,
      groupId: groupId,
      price: price,
      discount: discount,
      amountPaid: amountPaid,
      receiptNumber: 'RC-2026-${_receiptCounter.toString().padLeft(4, '0')}',
      createdAt: DateTime.now(),
    );
    _registrations.add(registration);
    _groups[idx] = group.copyWith(enrolledCount: group.enrolledCount + 1);
    return RegistrationSuccess(registration);
  }
}
