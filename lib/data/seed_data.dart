import 'models/models.dart';

/// Seed data used by the in-memory mock repository so the app is
/// fully usable before connecting Supabase.
class SeedData {
  static final subjects = <Subject>[
    const Subject(id: 'sub-phy', nameAr: 'فيزياء', nameEn: 'Physics', basePrice: 200000, durationMonths: 3),
    const Subject(id: 'sub-math', nameAr: 'رياضيات', nameEn: 'Mathematics', basePrice: 220000, durationMonths: 3),
    const Subject(id: 'sub-chem', nameAr: 'كيمياء', nameEn: 'Chemistry', basePrice: 180000, durationMonths: 3),
    const Subject(id: 'sub-en', nameAr: 'لغة إنجليزية', nameEn: 'English', basePrice: 150000, durationMonths: 4),
    const Subject(id: 'sub-ar', nameAr: 'لغة عربية', nameEn: 'Arabic', basePrice: 140000, durationMonths: 4),
    const Subject(id: 'sub-bio', nameAr: 'علوم / أحياء', nameEn: 'Biology', basePrice: 190000, durationMonths: 3),
  ];

  static final teachers = <Teacher>[
    const Teacher(id: 't-ahmad', name: 'أ. أحمد الحسن', specialization: 'Physics'),
    const Teacher(id: 't-khaled', name: 'أ. خالد يوسف', specialization: 'Physics'),
    const Teacher(id: 't-samer', name: 'أ. سامر ديب', specialization: 'Mathematics'),
    const Teacher(id: 't-rana', name: 'أ. رنا عبود', specialization: 'Mathematics'),
    const Teacher(id: 't-lina', name: 'أ. لينا قصار', specialization: 'Chemistry'),
    const Teacher(id: 't-maya', name: 'أ. مايا نصر', specialization: 'English'),
    const Teacher(id: 't-omar', name: 'أ. عمر شهاب', specialization: 'Arabic'),
    const Teacher(id: 't-hiba', name: 'أ. هبة زين', specialization: 'Biology'),
  ];

  // ISO days: 1=Mon 2=Tue 3=Wed 4=Thu 5=Fri 6=Sat 7=Sun
  static final groups = <StudyGroup>[
    // Physics — two teachers, different prices (VIP concept)
    const StudyGroup(
      id: 'g-phy-a', subjectId: 'sub-phy', teacherId: 't-ahmad', label: 'A',
      schedule: [TimeSlot(dayOfWeek: 7, hour: 16), TimeSlot(dayOfWeek: 2, hour: 16), TimeSlot(dayOfWeek: 4, hour: 16)],
      maxCapacity: 20, enrolledCount: 14,
    ),
    const StudyGroup(
      id: 'g-phy-vip', subjectId: 'sub-phy', teacherId: 't-khaled', label: 'VIP',
      schedule: [TimeSlot(dayOfWeek: 1, hour: 18), TimeSlot(dayOfWeek: 3, hour: 18)],
      maxCapacity: 10, enrolledCount: 9, priceOverride: 250000,
    ),
    // Math
    const StudyGroup(
      id: 'g-math-a', subjectId: 'sub-math', teacherId: 't-samer', label: 'A',
      schedule: [TimeSlot(dayOfWeek: 7, hour: 16), TimeSlot(dayOfWeek: 3, hour: 16)],
      maxCapacity: 25, enrolledCount: 25, // full — demonstrates capacity guard
    ),
    const StudyGroup(
      id: 'g-math-b', subjectId: 'sub-math', teacherId: 't-rana', label: 'B',
      schedule: [TimeSlot(dayOfWeek: 6, hour: 10), TimeSlot(dayOfWeek: 2, hour: 18)],
      maxCapacity: 25, enrolledCount: 11,
    ),
    // Chemistry
    const StudyGroup(
      id: 'g-chem-a', subjectId: 'sub-chem', teacherId: 't-lina', label: 'A',
      schedule: [TimeSlot(dayOfWeek: 1, hour: 16), TimeSlot(dayOfWeek: 4, hour: 18)],
      maxCapacity: 20, enrolledCount: 8,
    ),
    // English
    const StudyGroup(
      id: 'g-en-a', subjectId: 'sub-en', teacherId: 't-maya', label: 'A',
      schedule: [TimeSlot(dayOfWeek: 6, hour: 12), TimeSlot(dayOfWeek: 7, hour: 12)],
      maxCapacity: 30, enrolledCount: 19,
    ),
    // Arabic
    const StudyGroup(
      id: 'g-ar-a', subjectId: 'sub-ar', teacherId: 't-omar', label: 'A',
      schedule: [TimeSlot(dayOfWeek: 2, hour: 14), TimeSlot(dayOfWeek: 5, hour: 14)],
      maxCapacity: 30, enrolledCount: 6,
    ),
    // Biology
    const StudyGroup(
      id: 'g-bio-a', subjectId: 'sub-bio', teacherId: 't-hiba', label: 'A',
      schedule: [TimeSlot(dayOfWeek: 7, hour: 16), TimeSlot(dayOfWeek: 5, hour: 10)],
      maxCapacity: 20, enrolledCount: 13,
    ),
  ];

  static final students = <Student>[
    Student(id: 's-1001', name: 'محمد العلي', barcode: 'ST-1001', phone: '0931111111',
        guardianName: 'علي العلي', guardianPhone: '0941111111',
        createdAt: DateTime(2026, 8, 10)),
    Student(id: 's-1002', name: 'سارة خليل', barcode: 'ST-1002', phone: '0932222222',
        guardianName: 'خليل خليل', guardianPhone: '0942222222',
        createdAt: DateTime(2026, 8, 12)),
    Student(id: 's-1003', name: 'يزن حمود', barcode: 'ST-1003', phone: '0933333333',
        createdAt: DateTime(2026, 8, 20)),
    Student(id: 's-1004', name: 'ليان مراد', barcode: 'ST-1004', phone: '0934444444',
        guardianName: 'مراد مراد', guardianPhone: '0944444444',
        createdAt: DateTime(2026, 8, 25)),
  ];

  static final registrations = <Registration>[
    Registration(
      id: 'r-1', studentId: 's-1001', groupId: 'g-phy-a',
      price: 200000, amountPaid: 200000, receiptNumber: 'RC-2026-0001',
      createdAt: DateTime(2026, 8, 30, 10, 15),
    ),
    Registration(
      id: 'r-2', studentId: 's-1002', groupId: 'g-math-b',
      price: 220000, discount: 20000, amountPaid: 100000, receiptNumber: 'RC-2026-0002',
      createdAt: DateTime(2026, 9, 1, 12, 40),
    ),
    Registration(
      id: 'r-3', studentId: 's-1001', groupId: 'g-en-a',
      price: 150000, amountPaid: 150000, receiptNumber: 'RC-2026-0003',
      createdAt: DateTime(2026, 9, 2, 9, 5),
    ),
  ];
}
