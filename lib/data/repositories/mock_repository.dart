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
