import '../models/models.dart';

/// Result of attempting a registration.
sealed class RegistrationResult {
  const RegistrationResult();
}

class RegistrationSuccess extends RegistrationResult {
  final Registration registration;
  const RegistrationSuccess(this.registration);
}

class RegistrationFailure extends RegistrationResult {
  final String reason;
  const RegistrationFailure(this.reason);
}

/// Abstraction over the data source.
/// Swap [MockInstituteRepository] with [SupabaseInstituteRepository]
/// once your Supabase project credentials are configured — the UI never changes.
abstract class InstituteRepository {
  Future<List<Student>> getStudents();
  Future<List<Subject>> getSubjects();
  Future<List<Teacher>> getTeachers();
  Future<List<StudyGroup>> getGroups();
  Future<List<Registration>> getRegistrations();

  Future<Student> addStudent({
    required String name,
    required String phone,
    String guardianName,
    String guardianPhone,
  });

  /// Atomically registers a student into a group (capacity-safe).
  Future<RegistrationResult> register({
    required String studentId,
    required String groupId,
    required double price,
    required double discount,
    required double amountPaid,
  });
}
