import 'package:flutter/material.dart';

/// البيانات التجريبية v3.6 — تدعم النظامين (كورسات كاملة / نظام ساعات)
/// وثلاث فترات: صباحي / ظهر / مسائي
/// مع سياسات مالية معتمدة: الاستحقاق بالجلسة المنفذة + دفتر ثلاثي + فصل المعتمد عن المصروف + قفل مالي

// ============================ النظامان ============================
const kSystems = ['كورس كامل', 'نظام ساعات'];

/// سجل المواد الموحّد — يغذي كل القوائم المنزلقة لضمان توحيد التسمية
/// الإدارة تضيف له مواد جديدة من شاشة إنشاء دورة أو إضافة مدرس
final kSubjectNames = <String>[
  'اللغة الإنجليزية', 'الرياضيات', 'الفيزياء', 'الألمانية', 'المحاسبة', 'التأسيس', 'المحادثة',
];

void addSubjectIfNew(String name) {
  final n = name.trim();
  if (n.isNotEmpty && !kSubjectNames.contains(n)) kSubjectNames.add(n);
}
const kPeriods = ['صباحي', 'ظهر', 'مسائي'];

/// أنواع الدورات (منهجية/لغات/تقوية/تثقيفية/تخصصية) — قابلة للإضافة من الإدارة
final kCourseTypes = <String>['منهجية مدرسية', 'لغات', 'تقوية', 'تثقيفية', 'تخصصية'];

void addCourseTypeIfNew(String name) {
  final n = name.trim();
  if (n.isNotEmpty && !kCourseTypes.contains(n)) kCourseTypes.add(n);
}

// ============================ الطلاب ============================
class StudentMaterial {
  final String subject, teacher, period, schedule, grade, financial;
  final int attendancePct;
  StudentMaterial(this.subject, this.teacher, this.period, this.schedule,
      this.attendancePct, this.grade, this.financial);
}

class Student {
  final String code, name, level, phone, guardian, status;
  final double totalFee;    // المبلغ الإجمالي للدورة/الساعات
  final double balanceDue;  // المتبقي
  final List<StudentMaterial> materials;
  Student(this.code, this.name, this.level, this.phone, this.guardian,
      this.status, this.totalFee, this.balanceDue, this.materials);
  int get attendanceAvg => materials.isEmpty
      ? 0
      : (materials.map((m) => m.attendancePct).reduce((a, b) => a + b) /
              materials.length)
          .round();
}

final kStudents = <Student>[
  Student('ST-1042', 'أحمد خالد العمر', 'إنجليزي B2', '0991 234 567', 'خالد العمر', 'نشط', 180000, 0, [
    StudentMaterial('الإنجليزية B2', 'أ. سامر الحلبي', 'مسائي', 'سبت وأربعاء 5:00م', 96, '88 / 100', 'مسدّد'),
    StudentMaterial('المحادثة', 'أ. سامر الحلبي', 'مسائي', 'اثنين 7:00م', 90, '—', 'مسدّد'),
  ]),
  Student('ST-1043', 'مريم السيد', 'رياضيات تاسع', '0992 345 678', 'وليد السيد', 'نشط', 160000, 25000, [
    StudentMaterial('الرياضيات', 'أ. محمد العلي', 'مسائي', 'أحد وثلاثاء 4:00م', 82, '76 / 100', 'قسط متأخر'),
    StudentMaterial('الفيزياء', 'أ. ليلى نصار', 'مسائي', 'ثلاثاء 6:00م', 74, '81 / 100', 'مسدّد جزئيًا'),
  ]),
  Student('ST-1044', 'يوسف الحسن', 'ألماني A1', '0993 456 789', 'سامر الحسن', 'نشط', 170000, 0, [
    StudentMaterial('الألمانية A1', 'أ. كريم يوسف', 'مسائي', 'خميس 5:00م', 100, '—', 'مسدّد'),
  ]),
  Student('ST-1045', 'سارة العبد الله', 'دبلوم محاسبة', '0994 567 890', 'فهد العبد الله', 'نشط', 220000, 0, [
    StudentMaterial('المحاسبة', 'أ. هدى الزين', 'مسائي', 'سبت واثنين 6:30م', 94, '90 / 100', 'مسدّد'),
  ]),
  Student('ST-1046', 'عمر الحمصي', 'فيزياء بكلوريا', '0995 111 222', 'أنس الحمصي', 'نشط', 200000, 40000, [
    StudentMaterial('الفيزياء', 'أ. ليلى نصار', 'ظهر', 'ثلاثاء 1:00 ظهرًا', 88, '85 / 100', 'قسط ثالث متبقٍ'),
  ]),
  Student('ST-1047', 'لينا فاروق', 'إنجليزي A2', '0996 333 444', 'نادر فاروق', 'نشط', 150000, 0, [
    StudentMaterial('الإنجليزية A2', 'أ. رنا خالد', 'صباحي', 'أحد وثلاثاء 10:00ص', 91, '79 / 100', 'مسدّد'),
  ]),
  Student('ST-1048', 'خالد المطيع', 'رياضيات تاسع', '0997 555 666', 'مازن المطيع', 'متوقف', 160000, 60000, [
    StudentMaterial('الرياضيات', 'أ. محمد العلي', 'مسائي', 'أحد وثلاثاء 4:00م', 45, '40 / 100', 'متعثر — مراجعة'),
  ]),
  Student('ST-1049', 'نور الهدى', 'تأسيس قراءة', '0998 777 888', 'عمر الهدى', 'نشط', 120000, 0, [
    StudentMaterial('التأسيس والقراءة', 'أ. رنا خالد', 'صباحي', 'سبت وثلاثاء 10:00ص', 98, 'ممتاز', 'مسدّد'),
  ]),
  Student('ST-1050', 'زين مروان', 'محادثة — ساعات', '0999 999 000', 'مروان قاسم', 'نشط', 30000, 15000, [
    StudentMaterial('المحادثة (ساعات)', 'أ. سامر الحلبي', 'ظهر', 'اثنين 1:30 ظهرًا', 85, '—', 'دفعة جلسة أخيرة'),
  ]),
  Student('ST-1051', 'رهف السعيد', 'ألماني A1', '0993 121 212', 'غسان السعيد', 'قائمة انتظار', 170000, 0, []),
  Student('ST-1052', 'طلال الأحمد', 'دبلوم محاسبة', '0994 343 434', 'ياسر الأحمد', 'نشط', 220000, 0, [
    StudentMaterial('المحاسبة', 'أ. هدى الزين', 'مسائي', 'سبت واثنين 6:30م', 89, '87 / 100', 'مسدّد'),
  ]),
  Student('ST-1053', 'هبة سعيد', 'إنجليزي B2', '0991 565 656', 'سامر سعيد', 'نشط', 180000, 30000, [
    StudentMaterial('الإنجليزية B2', 'أ. سامر الحلبي', 'مسائي', 'سبت وأربعاء 5:00م', 93, '91 / 100', 'قسط أول مدفوع'),
  ]),
];

// ============================ المدرسون ============================
class Teacher {
  final String name, subject, payrollType;
  final int groups, enrolled, capacity, waiting, rate;
  final double rating, earned, paidOut;
  // الحقول الجديدة v3.3
  final String degree, mobile, whatsapp, nationalId;
  final bool worksGov, worksOther;
  final double mgmtRating; // تقييم الإدارة (خمس نجوم — يظهر للإدارة فقط)
  Teacher(this.name, this.subject, this.groups, this.enrolled, this.capacity,
      this.waiting, this.rating, this.payrollType, this.rate, this.earned, this.paidOut,
      {this.degree = 'جامعة اربع سنوات', this.mobile = '', this.whatsapp = '',
       this.nationalId = '', this.worksGov = false, this.worksOther = false,
       this.mgmtRating = 4.5});
  double get occupancy => capacity == 0 ? 0 : enrolled / capacity;
  double get balance => earned - paidOut;
}

final kTeachers = <Teacher>[
  Teacher('أ. سامر الحلبي', 'اللغة الإنجليزية', 2, 22, 28, 4, 4.8, 'لكل جلسة', 15000, 180000, 120000, degree: 'ماجستير تأهيل وتخصص', mobile: '0991111222', whatsapp: '0991111222', nationalId: '01234567891', worksOther: true, mgmtRating: 4.8),
  Teacher('أ. رنا خالد', 'الإنجليزية / التأسيس', 2, 19, 22, 0, 4.9, 'لكل جلسة', 12000, 150000, 100000, degree: 'دبلوم تأهيل تربوي', mobile: '0992222333', whatsapp: '0992222333', nationalId: '02345678912', mgmtRating: 4.9),
  Teacher('أ. محمد العلي', 'الرياضيات', 1, 14, 14, 5, 4.6, 'لكل جلسة', 18000, 210000, 150000, degree: 'جامعة خمس سنوات', mobile: '0993333444', whatsapp: '0993333444', nationalId: '03456789123', worksGov: true, mgmtRating: 4.6),
  Teacher('أ. ليلى نصار', 'الفيزياء', 1, 8, 12, 1, 4.7, 'نسبة 40%', 0, 96000, 60000, degree: 'دكتوراه', mobile: '0994444555', whatsapp: '0994444555', nationalId: '04567891234', worksGov: true, worksOther: true, mgmtRating: 4.7),
  Teacher('أ. كريم يوسف', 'الألمانية', 1, 6, 10, 0, 4.5, 'لكل جلسة', 15000, 54000, 30000, degree: 'ماجستير تأهيل أكاديمي', mobile: '0995555666', whatsapp: '0995555666', nationalId: '05678912345', mgmtRating: 4.5),
  Teacher('أ. هدى الزين', 'المحاسبة', 1, 11, 15, 2, 4.8, 'ثابت + حوافز', 0, 132000, 90000, degree: 'جامعة اربع سنوات', mobile: '0996666777', whatsapp: '0996666777', nationalId: '06789123456', mgmtRating: 4.8),
];

// ==================== المجموعات: النظامان + 3 فترات ====================
class Group {
  final String name, subject, teacher, room, days, status, period, system;
  final int enrolled, capacity, waiting, price, sessionsDone, sessionsTotal, installments;
  final String type;
  final double teacherPct; // نسبة المعلم — يحددها المدير العام عند الاعتماد
  final bool financeLocked; // قفل مالي بعد إغلاق الدورة
  Group(this.name, this.subject, this.teacher, this.period, this.enrolled,
      this.capacity, this.waiting, this.status, this.room, this.days,
      this.price, this.sessionsDone, this.sessionsTotal, this.system, this.installments,
      {this.type = '', this.teacherPct = 0, this.financeLocked = false});
  int get seatsLeft => capacity - enrolled;
  double get fill => capacity == 0 ? 0 : enrolled / capacity;
  bool get isHoursSystem => system == 'نظام ساعات';
  int get executedSessions => sessionsDone < 0 ? 0 : (sessionsDone > sessionsTotal ? sessionsTotal : sessionsDone);
  double get sessionUnitPrice => isHoursSystem ? price.toDouble() : (sessionsTotal == 0 ? 0 : price / sessionsTotal);
  // ===== الإيراد التعاقدي الكامل =====
  double get revenue => isHoursSystem ? price * sessionsTotal * enrolled : price * enrolled;
  // ===== الاعتراف المالي يكون على الجلسات المنفذة فقط =====
  double get accruedRevenue => sessionUnitPrice * executedSessions * enrolled;
  double get deferredRevenue => revenue > accruedRevenue ? revenue - accruedRevenue : 0;
  // ===== استحقاق المدرس: إجمالي تعاقدي مقابل مستحق منفذ =====
  double get teacherComp => teacherPct <= 0 ? 0 : revenue * teacherPct / 100;
  double get accruedTeacherComp => teacherPct <= 0 ? 0 : accruedRevenue * teacherPct / 100;
  double get remainingTeacherComp => teacherComp > accruedTeacherComp ? teacherComp - accruedTeacherComp : 0;
  double get instituteNet => revenue - teacherComp;
  double get instituteNetAccrued => accruedRevenue - accruedTeacherComp;
  double get instituteMarginPct => accruedRevenue == 0 ? 0 : instituteNetAccrued / accruedRevenue * 100;
}

final kGroups = <Group>[
  Group('إنجليزي B2 — مسائي أ', 'اللغة الإنجليزية', 'أ. سامر الحلبي', 'مسائي', 12, 14, 4, 'running', 'قاعة 2', 'سبت + أربعاء • 5:00م', 180000, 8, 24, 'كورس كامل', 3, type: 'لغات', teacherPct: 30),
  Group('إنجليزي A2 — صباحي ب', 'اللغة الإنجليزية', 'أ. رنا خالد', 'صباحي', 10, 12, 0, 'running', 'قاعة 1', 'أحد + ثلاثاء • 10:00ص', 150000, 6, 24, 'كورس كامل', 2),
  Group('رياضيات تاسع — مسائي', 'الرياضيات', 'أ. محمد العلي', 'مسائي', 14, 14, 5, 'running', 'قاعة 3', 'أحد + ثلاثاء • 4:00م', 160000, 10, 20, 'كورس كامل', 2, type: 'منهجية مدرسية', teacherPct: 30),
  Group('فيزياء بكلوريا — ظهر', 'الفيزياء', 'أ. ليلى نصار', 'ظهر', 8, 12, 1, 'running', 'مختبر 1', 'ثلاثاء • 1:00 ظهرًا', 200000, 5, 16, 'كورس كامل', 2, type: 'تخصصية', teacherPct: 40),
  Group('ألماني A1 — مسائي', 'الألمانية', 'أ. كريم يوسف', 'مسائي', 6, 10, 0, 'open', 'قاعة 2', 'خميس • 5:00م', 170000, 0, 20, 'كورس كامل', 3),
  Group('محاسبة — دبلوم مسائي', 'المحاسبة', 'أ. هدى الزين', 'مسائي', 11, 15, 2, 'open', 'قاعة 4', 'سبت + اثنين • 6:30م', 220000, 2, 24, 'كورس كامل', 4),
  Group('تأسيس قراءة — صباحي', 'التأسيس', 'أ. رنا خالد', 'صباحي', 9, 10, 0, 'running', 'قاعة 1', 'سبت + ثلاثاء • 10:00ص', 120000, 7, 18, 'كورس كامل', 2),
  Group('محادثة إنجليزي — ساعات', 'المحادثة', 'أ. سامر الحلبي', 'ظهر', 10, 12, 1, 'running', 'قاعة 2', 'حسب حجز الطالب • 1:30 ظهرًا', 15000, 4, 12, 'نظام ساعات', 0, type: 'لغات', teacherPct: 25),
  Group('رياضيات — جلسات مساعدة', 'الرياضيات', 'أ. محمد العلي', 'مسائي', 5, 8, 0, 'open', 'قاعة 3', 'حسب حجز الطالب • 6:00م', 20000, 0, 10, 'نظام ساعات', 0),
];

Teacher? teacherByName(String name) {
  for (final t in kTeachers) {
    if (t.name == name) return t;
  }
  return null;
}

bool marginNeedsWarning(double teacherPct) => (100 - teacherPct) > 70;

double approvedCompForCourse(String course) =>
    kCompNotices.where((n) => n.course == course).fold<double>(0, (s, n) => s + n.amount);

double paidCompForCourse(String course) =>
    kCompNotices.where((n) => n.course == course).fold<double>(0, (s, n) => s + n.paidAmount);

double pendingCompForCourse(String course) =>
    approvedCompForCourse(course) - paidCompForCourse(course);

double approvedCompForTeacher(String teacher) =>
    kCompNotices.where((n) => n.teacher == teacher).fold<double>(0, (s, n) => s + n.amount);

double paidCompForTeacher(String teacher) =>
    kCompNotices.where((n) => n.teacher == teacher).fold<double>(0, (s, n) => s + n.paidAmount);

double pendingCompForTeacher(String teacher) =>
    approvedCompForTeacher(teacher) - paidCompForTeacher(teacher);


// ==================== طلبات التسجيل وقوائم الانتظار ====================
class RegRequest {
  final String student, subject, teacher, date, period;
  String status;
  RegRequest(this.student, this.subject, this.teacher, this.period, this.date, this.status);
}

final kRequests = <RegRequest>[
  RegRequest('رهف السعيد — ST-1051', 'الألمانية A1', 'أ. كريم يوسف', 'مسائي', '2026-09-03', 'معلق'),
  RegRequest('هبة سعيد — ST-1053', 'الرياضيات تاسع', 'أ. محمد العلي', 'مسائي', '2026-09-03', 'معلق'),
  RegRequest('عمر الحمصي — ST-1046', 'المحادثة (ساعات)', 'أ. سامر الحلبي', 'ظهر', '2026-09-02', 'معلق'),
  RegRequest('لينا فاروق — ST-1047', 'المحاسبة (دبلوم)', 'أ. هدى الزين', 'مسائي', '2026-09-01', 'معتمد'),
  RegRequest('طلال الأحمد — ST-1052', 'الفيزياء بكلوريا', 'أ. ليلى نصار', 'ظهر', '2026-09-01', 'معتمد'),
  RegRequest('نور الهدى — ST-1049', 'المحادثة (ساعات)', 'أ. سامر الحلبي', 'صباحي', '2026-08-31', 'مرفوض'),
];

class WaitingEntry {
  final String student, subject, teacher, period, since;
  WaitingEntry(this.student, this.subject, this.teacher, this.period, this.since);
}

final kWaiting = <WaitingEntry>[
  WaitingEntry('مريم السيد — ST-1043', 'الرياضيات تاسع', 'أ. محمد العلي', 'مسائي', 'منذ 6 أيام'),
  WaitingEntry('هبة سعيد — ST-1053', 'الرياضيات تاسع', 'أ. محمد العلي', 'مسائي', 'منذ 4 أيام'),
  WaitingEntry('أحمد خالد — ST-1042', 'الألمانية A1', 'أ. كريم يوسف', 'مسائي', 'منذ 3 أيام'),
  WaitingEntry('زين مروان — ST-1050', 'الفيزياء بكلوريا', 'أ. ليلى نصار', 'ظهر', 'منذ يومين'),
  WaitingEntry('عمر الحمصي — ST-1046', 'المحادثة (ساعات)', 'أ. سامر الحلبي', 'ظهر', 'منذ يوم'),
];

// ============================ الجدولة (3 فترات) ============================
class SessionSlot {
  final int day; // 0=سبت .. 5=خميس
  final String period, group, room, time;
  SessionSlot(this.day, this.period, this.group, this.room, this.time);
}

final kWeekDays = ['السبت', 'الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس'];

final kSessions = <SessionSlot>[
  SessionSlot(0, 'مسائي', 'إنجليزي B2', 'قاعة 2', '5:00م'),
  SessionSlot(0, 'صباحي', 'تأسيس قراءة', 'قاعة 1', '10:00ص'),
  SessionSlot(0, 'مسائي', 'محاسبة — دبلوم', 'قاعة 4', '6:30م'),
  SessionSlot(1, 'صباحي', 'إنجليزي A2', 'قاعة 1', '10:00ص'),
  SessionSlot(1, 'مسائي', 'رياضيات تاسع', 'قاعة 3', '4:00م'),
  SessionSlot(1, 'ظهر', 'محادثة إنجليزي — ساعات', 'قاعة 2', '1:30 ظهرًا'),
  SessionSlot(2, 'صباحي', 'تأسيس قراءة', 'قاعة 1', '10:00ص'),
  SessionSlot(2, 'ظهر', 'فيزياء بكلوريا', 'مختبر 1', '1:00 ظهرًا'),
  SessionSlot(2, 'مسائي', 'رياضيات تاسع', 'قاعة 3', '4:00م'),
  SessionSlot(2, 'مسائي', 'محاسبة — دبلوم', 'قاعة 4', '6:30م'),
  SessionSlot(3, 'مسائي', 'إنجليزي B2', 'قاعة 2', '5:00م'),
  SessionSlot(3, 'ظهر', 'محادثة إنجليزي — ساعات', 'قاعة 2', '1:30 ظهرًا'),
  SessionSlot(4, 'مسائي', 'ألماني A1', 'قاعة 2', '5:00م'),
  SessionSlot(4, 'مسائي', 'رياضيات — جلسات مساعدة', 'قاعة 3', '6:00م'),
];

// ============================ الحضور ============================
class AttendanceSummary {
  final String group;
  final int present, absent, late, excused;
  AttendanceSummary(this.group, this.present, this.absent, this.late, this.excused);
}

final kAttendance = <AttendanceSummary>[
  AttendanceSummary('إنجليزي B2 — مسائي أ', 11, 1, 0, 0),
  AttendanceSummary('رياضيات تاسع — مسائي', 12, 1, 1, 0),
  AttendanceSummary('فيزياء بكلوريا — ظهر', 7, 0, 0, 1),
  AttendanceSummary('إنجليزي A2 — صباحي ب', 10, 0, 0, 0),
  AttendanceSummary('محاسبة — دبلوم مسائي', 9, 1, 0, 1),
  AttendanceSummary('تأسيس قراءة — صباحي', 9, 0, 0, 0),
  AttendanceSummary('محادثة إنجليزي — ساعات', 9, 0, 1, 0),
];

// ============================ الامتحانات ============================
class Exam {
  final String title, group, type, date, status;
  final double avg;
  Exam(this.title, this.group, this.type, this.date, this.avg, this.status);
}

final kExams = <Exam>[
  Exam('كويز الوحدة 3', 'إنجليزي B2', 'كويز', '2026-08-29', 82, 'منتهي'),
  Exam('امتحان منتصف الفصل', 'رياضيات تاسع', 'منتصف', '2026-09-06', 0, 'قادم'),
  Exam('كويز المحاسبة المالية', 'محاسبة — دبلوم', 'كويز', '2026-09-08', 0, 'قادم'),
  Exam('اختبار تحديد مستوى', 'ألماني A1', 'تحديد', '2026-09-10', 0, 'قادم'),
  Exam('نهائي منتصف المدة', 'فيزياء بكلوريا', 'نهائي', '2026-09-14', 0, 'مجدول'),
  Exam('تقييم القراءة الأول', 'تأسيس قراءة', 'تقييم', '2026-08-27', 91, 'منتهي'),
];

// ============================ المالية ============================
class Invoice {
  final String student, number, due, status;
  final double total, paid;
  final int installments;
  Invoice(this.student, this.number, this.total, this.paid, this.installments, this.due, this.status);
}

final kInvoices = <Invoice>[
  Invoice('هبة سعيد', 'INV-2026-018', 180000, 60000, 3, '2026-09-15', 'جزئي'),
  Invoice('مريم السيد', 'INV-2026-011', 160000, 135000, 2, '2026-09-02', 'متأخر'),
  Invoice('عمر الحمصي', 'INV-2026-014', 200000, 160000, 2, '2026-09-20', 'جزئي'),
  Invoice('خالد المطيع', 'INV-2026-009', 160000, 100000, 2, '2026-08-25', 'متأخر'),
  Invoice('زين مروان', 'INV-2026-016', 30000, 15000, 1, '2026-09-18', 'جزئي'),
  Invoice('سارة العبد الله', 'INV-2026-013', 220000, 220000, 1, '2026-08-28', 'مسدد'),
  Invoice('لينا فاروق', 'INV-2026-015', 150000, 150000, 1, '2026-08-30', 'مسدد'),
  Invoice('طلال الأحمد', 'INV-2026-017', 220000, 220000, 1, '2026-09-01', 'مسدد'),
];

class Discount {
  final String name, scope, target, duration, by;
  final double pct;
  Discount(this.name, this.scope, this.target, this.pct, this.duration, this.by);
}

final kDiscounts = <Discount>[
  Discount('عرض إطلاق الموسم', 'دورة كاملة', 'إنجليزي B2', 10, 'حتى نهاية الشهر', 'الإدارة'),
  Discount('خصم الأخوة', 'طالب محدد', 'عائلة السعيد (3 طلاب)', 15, 'دائم', 'الإدارة'),
  Discount('السداد المبكر', 'مجموعة محددة', 'محاسبة — دبلوم مسائي', 5, '30 يومًا', 'المحاسب'),
  Discount('متفوقون', 'طالب محدد', 'نور الهدى — ST-1049', 20, 'أول 12 جلسة', 'المدير'),
];

// ============================ المحاسبة ============================
class SubjectAccount {
  final String subject;
  final double revenue, cost;
  SubjectAccount(this.subject, this.revenue, this.cost);
  double get net => revenue - cost;
}

final kSubjectAccounts = <SubjectAccount>[
  SubjectAccount('اللغة الإنجليزية', 1260000, 330000),
  SubjectAccount('الرياضيات', 224000, 180000),
  SubjectAccount('الفيزياء', 160000, 96000),
  SubjectAccount('الألمانية', 102000, 54000),
  SubjectAccount('المحاسبة', 242000, 132000),
  SubjectAccount('التأسيس', 108000, 108000),
];

class Expense {
  final String category, desc, date, by;
  final double amount;
  Expense(this.category, this.desc, this.amount, this.date, this.by);
}

final kExpenses = <Expense>[
  Expense('إيجار', 'إيجار المقر — أيلول', 500000, '2026-09-01', 'المدير'),
  Expense('مرافق', 'كهرباء وماء وإنترنت', 145000, '2026-09-02', 'المحاسب'),
  Expense('مخزون', 'طباعة ملازم إنجليزي B2 (30 نسخة)', 120000, '2026-09-03', 'المحاسب'),
  Expense('صيانة', 'صيانة أجهزة التكييف', 95000, '2026-08-28', 'المنسق'),
  Expense('نثريات', 'قرطاسية ومستلزمات مكتبية', 35000, '2026-08-30', 'الاستقبال'),
  Expense('رواتب', 'رواتب الإدارة — أغسطس', 850000, '2026-08-31', 'المحاسب'),
  Expense('تسويق', 'حملة إعلانية على السوشيال ميديا', 150000, '2026-08-25', 'المدير'),
];

class Payout {
  final String name, role, status;
  final double gross, deductions, net;
  Payout(this.name, this.role, this.gross, this.deductions, this.net, this.status);
}

final kTeacherPayouts = <Payout>[
  Payout('أ. سامر الحلبي', 'مستخلص أغسطس', 180000, 30000, 150000, 'مدفوع'),
  Payout('أ. محمد العلي', 'مستخلص أغسطس', 210000, 60000, 150000, 'مدفوع'),
  Payout('أ. رنا خالد', 'مستخلص أغسطس', 150000, 50000, 100000, 'مدفوع'),
  Payout('أ. ليلى نصار', 'مستخلص أغسطس', 96000, 36000, 60000, 'معلق'),
];

final kStaffPayouts = <Payout>[
  Payout('غيداء العلي', 'موظفة استقبال — راتب', 400000, 0, 400000, 'مدفوع'),
  Payout('أحمد النجار', 'محاسب — راتب', 550000, 25000, 525000, 'مدفوع'),
  Payout('سلمى حداد', 'منسقة أكاديمية — راتب', 480000, 0, 480000, 'معلق'),
];

// ============================ المخزون ============================
class InventoryItem {
  final String item, category;
  final int qty, min;
  final double unitCost;
  final bool isAsset;
  InventoryItem(this.item, this.category, this.qty, this.min, this.unitCost, [this.isAsset = false]);
  bool get low => qty <= min;
}

final kInventory = <InventoryItem>[
  InventoryItem('كتاب إنجليزي B2', 'كتب', 24, 10, 25000),
  InventoryItem('ملازم رياضيات تاسع', 'ملازم', 8, 15, 8000),
  InventoryItem('كتب ألماني A1', 'كتب', 15, 10, 30000),
  InventoryItem('أقلام حبر أزرق', 'مكتبية', 120, 50, 1500),
  InventoryItem('ماركرات سبورة', 'مكتبية', 6, 20, 3000),
  InventoryItem('جهاز عرض Epson', 'أجهزة', 4, 1, 2500000, true),
  InventoryItem('ملفات بلاستيك', 'مكتبية', 60, 30, 2000),
  InventoryItem('ورق طباعة A4', 'مكتبية', 3, 10, 45000),
];

// ============================ الإشعارات ============================
class NotificationItem {
  final String title, body, time, type;
  NotificationItem(this.title, this.body, this.time, this.type);
}

final kNotifications = <NotificationItem>[
  NotificationItem('طلب تسجيل جديد', 'رهف السعيد طلبت الألمانية A1 — مسائي مع أ. كريم يوسف', 'قبل 10 دقائق', 'request'),
  NotificationItem('مجموعة مكتملة', 'رياضيات تاسع وصلت السعة — 5 طلاب في قائمة الانتظار', 'قبل ساعة', 'waiting'),
  NotificationItem('قسط متأخر', 'مريم السيد — القسط الثاني استحق 2026-09-02', 'قبل 3 ساعات', 'payment'),
  NotificationItem('نقص مخزون', 'ملازم رياضيات تاسع: 8 فقط (الحد الأدنى 15)', 'اليوم 9:00ص', 'stock'),
  NotificationItem('غياب متكرر', 'خالد المطيع غاب 3 جلسات متتالية — إنذار مبكر', 'أمس', 'absence'),
];

// ============================ لوحة القيادة ============================
final kRevenueMonths = <(String, double)>[
  ('نيسان', 2.1), ('أيار', 2.4), ('حزيران', 1.8),
  ('تموز', 2.9), ('آب', 3.2), ('أيلول', 2.7),
];

final kSubjectDistribution = <(String, double, Color)>[
  ('إنجليزي', 41, Color(0xFF0284C7)),
  ('رياضيات', 14, Color(0xFF7C3AED)),
  ('محاسبة', 11, Color(0xFF15803D)),
  ('تأسيس', 9, Color(0xFFB45309)),
  ('فيزياء', 8, Color(0xFFDB2777)),
  ('ألماني', 6, Color(0xFF475569)),
];


// ==================== إشعارات تعويض المدرسين (المدير العام → المحاسبة) ====================
class CompNotice {
  final String date, teacher, degree, course, system;
  final int hours, students;
  final double pct, amount;
  String status; // معتمد / مصروف
  CompNotice(this.date, this.teacher, this.degree, this.course, this.system,
      this.hours, this.students, this.pct, this.amount, this.status);
  double get paidAmount => status == 'مصروف' ? amount : 0;
  double get pendingAmount => amount - paidAmount;
}

final kCompNotices = <CompNotice>[
  CompNotice('2026-09-03', 'أ. سامر الحلبي', 'ماجستير تأهيل وتخصص', 'إنجليزي B2 — مسائي أ', 'كورس كامل', 8, 12, 30, 216000, 'معتمد'),
  CompNotice('2026-09-02', 'أ. محمد العلي', 'جامعة خمس سنوات', 'رياضيات تاسع — مسائي', 'كورس كامل', 10, 14, 30, 336000, 'معتمد'),
  CompNotice('2026-09-01', 'أ. ليلى نصار', 'دكتوراه', 'فيزياء بكلوريا — ظهر', 'كورس كامل', 5, 8, 40, 200000, 'مصروف'),
  CompNotice('2026-08-30', 'أ. سامر الحلبي', 'ماجستير تأهيل وتخصص', 'محادثة إنجليزي — ساعات', 'نظام ساعات', 4, 10, 25, 150000, 'معتمد'),
];

class AuditEntry {
  final String time, user, action, target, details;
  AuditEntry(this.time, this.user, this.action, this.target, this.details);
}

final kAuditLog = <AuditEntry>[
  AuditEntry('2026-09-05 09:10', 'المدير العام', 'اعتماد مالي', 'إنجليزي B2 — مسائي أ', 'اعتماد نسبة 30% وفق سياسة السقف الأعلى 50% وربط المستحق بالجلسات المنفذة فقط.'),
  AuditEntry('2026-09-05 09:20', 'المحاسب', 'فصل قيود', 'فيزياء بكلوريا — ظهر', 'تم فصل المستحق عن المصروف: 200,000 ل.س صُرفت فعليًا وتم إغلاق قيدها.'),
  AuditEntry('2026-09-05 09:35', 'المدير العام', 'مراجعة هامش', 'محادثة إنجليزي — ساعات', 'الهامش الحالي 75% — ظهر تنبيه قبل الاعتماد وتمت الموافقة بعد المراجعة.'),
  AuditEntry('2026-09-05 09:50', 'مدير الدورات', 'دفتر ثلاثي', 'رياضيات تاسع — مسائي', 'تم اعتماد دفتر الدورة الثلاثي: تعاقدي / محقق / مصروف.'),
];

void addAudit(String action, String target, String details, {String user = 'المدير العام'}) {
  kAuditLog.insert(0, AuditEntry('2026-09-05 11:30', user, action, target, details));
}
