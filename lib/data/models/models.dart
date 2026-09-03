/// Core domain models for the Smart Institute ERP.
/// كل النماذج الأساسية لنظام المعهد الذكي.
library;

class Student {
  final String id;
  final String name;
  final String barcode;
  final String phone;
  final String guardianName;
  final String guardianPhone;
  final DateTime createdAt;

  const Student({
    required this.id,
    required this.name,
    required this.barcode,
    required this.phone,
    this.guardianName = '',
    this.guardianPhone = '',
    required this.createdAt,
  });

  Student copyWith({String? name, String? phone, String? guardianName, String? guardianPhone}) =>
      Student(
        id: id,
        name: name ?? this.name,
        barcode: barcode,
        phone: phone ?? this.phone,
        guardianName: guardianName ?? this.guardianName,
        guardianPhone: guardianPhone ?? this.guardianPhone,
        createdAt: createdAt,
      );

  factory Student.fromMap(Map<String, dynamic> m) => Student(
        id: m['id'] as String,
        name: m['name'] as String,
        barcode: m['barcode'] as String,
        phone: (m['phone'] ?? '') as String,
        guardianName: (m['guardian_name'] ?? '') as String,
        guardianPhone: (m['guardian_phone'] ?? '') as String,
        createdAt: DateTime.parse(m['created_at'] as String),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'barcode': barcode,
        'phone': phone,
        'guardian_name': guardianName,
        'guardian_phone': guardianPhone,
        'created_at': createdAt.toIso8601String(),
      };
}

class Subject {
  final String id;
  final String nameAr;
  final String nameEn;
  final double basePrice; // full-course price
  final int durationMonths;
  final int totalHours; // full-course hours

  const Subject({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.basePrice,
    required this.durationMonths,
    this.totalHours = 0,
  });

  String name(bool arabic) => arabic ? nameAr : nameEn;

  Subject copyWith({double? basePrice, int? totalHours, int? durationMonths}) =>
      Subject(
        id: id,
        nameAr: nameAr,
        nameEn: nameEn,
        basePrice: basePrice ?? this.basePrice,
        durationMonths: durationMonths ?? this.durationMonths,
        totalHours: totalHours ?? this.totalHours,
      );

  factory Subject.fromMap(Map<String, dynamic> m) => Subject(
        id: m['id'] as String,
        nameAr: m['name_ar'] as String,
        nameEn: m['name_en'] as String,
        basePrice: (m['base_price'] as num).toDouble(),
        durationMonths: (m['duration_months'] as num).toInt(),
        totalHours: (m['total_hours'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name_ar': nameAr,
        'name_en': nameEn,
        'base_price': basePrice,
        'duration_months': durationMonths,
        'total_hours': totalHours,
      };
}

class Teacher {
  final String id;
  final String name;
  final String specialization;

  /// Price per single session for this teacher — set by administration.
  final double sessionPrice;

  const Teacher({
    required this.id,
    required this.name,
    required this.specialization,
    this.sessionPrice = 0,
  });

  Teacher copyWith({double? sessionPrice}) => Teacher(
        id: id,
        name: name,
        specialization: specialization,
        sessionPrice: sessionPrice ?? this.sessionPrice,
      );

  factory Teacher.fromMap(Map<String, dynamic> m) => Teacher(
        id: m['id'] as String,
        name: m['name'] as String,
        specialization: (m['specialization'] ?? '') as String,
        sessionPrice: (m['session_price'] as num?)?.toDouble() ?? 0,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'specialization': specialization,
        'session_price': sessionPrice,
      };
}

/// A weekly time slot: dayOfWeek (1 = Monday .. 7 = Sunday, ISO) + start hour/minute.
class TimeSlot {
  final int dayOfWeek; // ISO 8601: 1=Mon ... 7=Sun
  final int hour; // 0-23
  final int minute;
  final int durationMinutes;

  const TimeSlot({
    required this.dayOfWeek,
    required this.hour,
    this.minute = 0,
    this.durationMinutes = 90,
  });

  int get startTotal => hour * 60 + minute;
  int get endTotal => startTotal + durationMinutes;

  /// True when two slots overlap on the same day — the heart of conflict detection.
  bool overlaps(TimeSlot other) =>
      dayOfWeek == other.dayOfWeek &&
      startTotal < other.endTotal &&
      other.startTotal < endTotal;

  factory TimeSlot.fromMap(Map<String, dynamic> m) => TimeSlot(
        dayOfWeek: (m['day_of_week'] as num).toInt(),
        hour: (m['hour'] as num).toInt(),
        minute: (m['minute'] as num?)?.toInt() ?? 0,
        durationMinutes: (m['duration_minutes'] as num?)?.toInt() ?? 90,
      );

  Map<String, dynamic> toMap() => {
        'day_of_week': dayOfWeek,
        'hour': hour,
        'minute': minute,
        'duration_minutes': durationMinutes,
      };
}

/// The beating heart of the system: subject + teacher + schedule + price.
class StudyGroup {
  final String id;
  final String subjectId;
  final String teacherId;
  final List<TimeSlot> schedule;
  final int maxCapacity;
  final int enrolledCount;
  final double? priceOverride; // null => use subject basePrice
  final String label; // e.g. "VIP", "A", "Evening"

  const StudyGroup({
    required this.id,
    required this.subjectId,
    required this.teacherId,
    required this.schedule,
    required this.maxCapacity,
    this.enrolledCount = 0,
    this.priceOverride,
    this.label = '',
  });

  bool get isFull => enrolledCount >= maxCapacity;
  int get seatsLeft => maxCapacity - enrolledCount;

  double effectivePrice(Subject subject) => priceOverride ?? subject.basePrice;

  StudyGroup copyWith({int? enrolledCount}) => StudyGroup(
        id: id,
        subjectId: subjectId,
        teacherId: teacherId,
        schedule: schedule,
        maxCapacity: maxCapacity,
        enrolledCount: enrolledCount ?? this.enrolledCount,
        priceOverride: priceOverride,
        label: label,
      );

  factory StudyGroup.fromMap(Map<String, dynamic> m) => StudyGroup(
        id: m['id'] as String,
        subjectId: m['subject_id'] as String,
        teacherId: m['teacher_id'] as String,
        schedule: ((m['schedule'] ?? []) as List)
            .map((e) => TimeSlot.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList(),
        maxCapacity: (m['max_capacity'] as num).toInt(),
        enrolledCount: (m['enrolled_count'] as num?)?.toInt() ?? 0,
        priceOverride: (m['price_override'] as num?)?.toDouble(),
        label: (m['label'] ?? '') as String,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'subject_id': subjectId,
        'teacher_id': teacherId,
        'schedule': schedule.map((s) => s.toMap()).toList(),
        'max_capacity': maxCapacity,
        'enrolled_count': enrolledCount,
        'price_override': priceOverride,
        'label': label,
      };
}

/// What a discount rule applies to.
enum DiscountScope { student, group, subject, teacher }

/// How the discount value is interpreted.
enum DiscountType { percent, fixed }

/// A discount rule defined by administration.
/// Scope + targetId identify WHO/WHAT gets the discount:
///   - student  → a specific student gets it on every registration
///   - group    → anyone registering in that group
///   - subject  → anyone registering in any group of that subject
///   - teacher  → anyone registering with that teacher
class DiscountRule {
  final String id;
  final DiscountScope scope;
  final String targetId;
  final DiscountType type;
  final double value; // percent (0-100) or fixed amount
  final String note;
  final bool active;
  final DateTime createdAt;

  const DiscountRule({
    required this.id,
    required this.scope,
    required this.targetId,
    required this.type,
    required this.value,
    this.note = '',
    this.active = true,
    required this.createdAt,
  });

  DiscountRule copyWith({bool? active, double? value, String? note}) =>
      DiscountRule(
        id: id,
        scope: scope,
        targetId: targetId,
        type: type,
        value: value ?? this.value,
        note: note ?? this.note,
        active: active ?? this.active,
        createdAt: createdAt,
      );

  /// Discount amount in currency for a given base price.
  double amountFor(double price) =>
      type == DiscountType.percent ? price * value / 100.0 : value;

  factory DiscountRule.fromMap(Map<String, dynamic> m) => DiscountRule(
        id: m['id'] as String,
        scope: DiscountScope.values.byName(m['scope'] as String),
        targetId: m['target_id'] as String,
        type: DiscountType.values.byName(m['type'] as String),
        value: (m['value'] as num).toDouble(),
        note: (m['note'] ?? '') as String,
        active: (m['active'] ?? true) as bool,
        createdAt: DateTime.parse(m['created_at'] as String),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'scope': scope.name,
        'target_id': targetId,
        'type': type.name,
        'value': value,
        'note': note,
        'active': active,
        'created_at': createdAt.toIso8601String(),
      };
}

class Registration {
  final String id;
  final String studentId;
  final String groupId;
  final double price;
  final double discount;
  final double amountPaid;
  final String receiptNumber;
  final DateTime createdAt;

  const Registration({
    required this.id,
    required this.studentId,
    required this.groupId,
    required this.price,
    this.discount = 0,
    required this.amountPaid,
    required this.receiptNumber,
    required this.createdAt,
  });

  double get netPrice => price - discount;
  double get remaining => netPrice - amountPaid;

  factory Registration.fromMap(Map<String, dynamic> m) => Registration(
        id: m['id'] as String,
        studentId: m['student_id'] as String,
        groupId: m['group_id'] as String,
        price: (m['price'] as num).toDouble(),
        discount: (m['discount'] as num?)?.toDouble() ?? 0,
        amountPaid: (m['amount_paid'] as num).toDouble(),
        receiptNumber: m['receipt_number'] as String,
        createdAt: DateTime.parse(m['created_at'] as String),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'student_id': studentId,
        'group_id': groupId,
        'price': price,
        'discount': discount,
        'amount_paid': amountPaid,
        'receipt_number': receiptNumber,
        'created_at': createdAt.toIso8601String(),
      };
}
