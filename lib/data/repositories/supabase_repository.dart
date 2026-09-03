import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/models.dart';
import 'institute_repository.dart';

/// Supabase-backed repository.
///
/// To activate:
///  1. Run `supabase/schema.sql` in your Supabase SQL editor.
///  2. In `main.dart`, call:
///       await Supabase.initialize(url: '...', anonKey: '...');
///  3. Override `repositoryProvider` with `SupabaseInstituteRepository()`.
class SupabaseInstituteRepository implements InstituteRepository {
  SupabaseClient get _db => Supabase.instance.client;

  @override
  Future<List<Student>> getStudents() async {
    final rows = await _db.from('students').select().order('created_at');
    return rows.map((r) => Student.fromMap(r)).toList();
  }

  @override
  Future<List<Subject>> getSubjects() async {
    final rows = await _db.from('subjects').select().order('name_en');
    return rows.map((r) => Subject.fromMap(r)).toList();
  }

  @override
  Future<List<Teacher>> getTeachers() async {
    final rows = await _db.from('teachers').select().order('name');
    return rows.map((r) => Teacher.fromMap(r)).toList();
  }

  @override
  Future<List<StudyGroup>> getGroups() async {
    final rows = await _db.from('groups_with_counts').select();
    return rows.map((r) => StudyGroup.fromMap(r)).toList();
  }

  @override
  Future<List<Registration>> getRegistrations() async {
    final rows =
        await _db.from('registrations').select().order('created_at', ascending: false);
    return rows.map((r) => Registration.fromMap(r)).toList();
  }

  @override
  Future<List<DiscountRule>> getDiscountRules() async {
    final rows =
        await _db.from('discount_rules').select().order('created_at');
    return rows.map((r) => DiscountRule.fromMap(r)).toList();
  }

  @override
  Future<void> updateSubjectPricing({
    required String subjectId,
    required double basePrice,
    required int totalHours,
    required int durationMonths,
  }) async {
    await _db.from('subjects').update({
      'base_price': basePrice,
      'total_hours': totalHours,
      'duration_months': durationMonths,
    }).eq('id', subjectId);
  }

  @override
  Future<void> updateTeacherSessionPrice({
    required String teacherId,
    required double sessionPrice,
  }) async {
    await _db
        .from('teachers')
        .update({'session_price': sessionPrice}).eq('id', teacherId);
  }

  @override
  Future<void> updateGroupPriceOverride({
    required String groupId,
    double? priceOverride,
  }) async {
    await _db
        .from('groups')
        .update({'price_override': priceOverride}).eq('id', groupId);
  }

  @override
  Future<DiscountRule> addDiscountRule({
    required DiscountScope scope,
    required String targetId,
    required DiscountType type,
    required double value,
    String note = '',
  }) async {
    final row = await _db
        .from('discount_rules')
        .insert({
          'scope': scope.name,
          'target_id': targetId,
          'type': type.name,
          'value': value,
          'note': note,
          'active': true,
        })
        .select()
        .single();
    return DiscountRule.fromMap(row);
  }

  @override
  Future<void> setDiscountRuleActive(String ruleId, bool active) async {
    await _db
        .from('discount_rules')
        .update({'active': active}).eq('id', ruleId);
  }

  @override
  Future<void> deleteDiscountRule(String ruleId) async {
    await _db.from('discount_rules').delete().eq('id', ruleId);
  }

  @override
  Future<Student> addStudent({
    required String name,
    required String phone,
    String guardianName = '',
    String guardianPhone = '',
  }) async {
    final row = await _db
        .from('students')
        .insert({
          'name': name,
          'phone': phone,
          'guardian_name': guardianName,
          'guardian_phone': guardianPhone,
        })
        .select()
        .single();
    return Student.fromMap(row);
  }

  @override
  Future<RegistrationResult> register({
    required String studentId,
    required String groupId,
    required double price,
    required double discount,
    required double amountPaid,
  }) async {
    // Uses the `register_student` Postgres function (see schema.sql) so the
    // capacity check + insert happen atomically inside the database.
    try {
      final row = await _db.rpc('register_student', params: {
        'p_student_id': studentId,
        'p_group_id': groupId,
        'p_price': price,
        'p_discount': discount,
        'p_amount_paid': amountPaid,
      });
      return RegistrationSuccess(
          Registration.fromMap(Map<String, dynamic>.from(row as Map)));
    } on PostgrestException catch (e) {
      return RegistrationFailure(e.message);
    }
  }
}
