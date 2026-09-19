import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import 'data/app_session.dart';
import 'data/mock_data.dart';
import 'data/registration_store.dart';
import 'data/student_store.dart';
import 'screens/accounting.dart';
import 'screens/attendance.dart';
import 'screens/courses.dart';
import 'screens/dashboard.dart';
import 'screens/exams.dart';
import 'screens/finance.dart';
import 'screens/inventory.dart';
import 'screens/registration.dart';
import 'screens/reports.dart';
import 'screens/schedule.dart';
import 'screens/settings.dart';
import 'screens/students.dart';
import 'screens/teachers.dart';
import 'theme.dart';
import 'widgets/ui.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    await windowManager.ensureInitialized();
    const options = WindowOptions(
      size: Size(1500, 940),
      minimumSize: Size(1220, 760),
      center: true,
      title: 'معهدّي — نظام إدارة المعاهد التعليمية الذكي',
    );
    await windowManager.waitUntilReadyToShow(options, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }
  await RegistrationStore.instance.init();
  await StudentStore.instance.init();
  runApp(const MaehdiApp());
}

class MaehdiApp extends StatelessWidget {
  const MaehdiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'معهدّي',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      locale: const Locale('ar'),
      builder: (context, child) => Directionality(textDirection: TextDirection.rtl, child: child!),
      home: const _AuthGate(),
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppSession.instance,
      builder: (context, _) {
        if (!AppSession.instance.isLoggedIn) {
          return const _LoginScreen();
        }
        return const MainShell();
      },
    );
  }
}

class _LoginScreen extends StatelessWidget {
  const _LoginScreen();

  @override
  Widget build(BuildContext context) {
    final users = [
      (
        label: AppSession.managementUser,
        icon: Icons.admin_panel_settings,
        color: AppTheme.purple,
        note: 'صلاحيات مطلقة: لوحة القيادة + الدورات + الطلاب + المحاسبة + الاعتماد النهائي',
      ),
      (
        label: AppSession.coursesUser,
        icon: Icons.auto_stories,
        color: AppTheme.seed,
        note: 'إنشاء وتعديل الدورات فقط، وكل دورة جديدة تحفظ بانتظار موافقة الإدارة',
      ),
      (
        label: AppSession.accountingUser,
        icon: Icons.account_balance_wallet,
        color: AppTheme.success,
        note: 'الوصول إلى الفواتير والأقساط والمحاسبة فقط',
      ),
      (
        label: AppSession.studentsUser,
        icon: Icons.groups_2,
        color: AppTheme.gold,
        note: 'الوصول إلى الطلاب والتسجيل والانتظار فقط',
      ),
    ];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.darkGrad),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.08),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: Colors.white.withOpacity(.1)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 66,
                          height: 66,
                          decoration: BoxDecoration(
                            gradient: AppTheme.accentGrad,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Center(
                            child: Text(
                              'م',
                              style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'معهدّي',
                                style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'اختر المستخدم للدخول — حاليًا بدون كلمة مرور، ولكل مستخدم صلاحية على بابه فقط ما عدا الإدارة.',
                                style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 12.5),
                              ),
                            ],
                          ),
                        ),
                        const Text(
                          'إدارة المعاهد الذكي • v3.8-fix23',
                          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      final cardWidth = width >= 1100
                          ? (width - 36) / 4
                          : (width >= 760 ? (width - 12) / 2 : width);
                      return Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          for (final user in users)
                            SizedBox(
                              width: cardWidth,
                              child: _LoginUserCard(
                                label: user.label,
                                icon: user.icon,
                                color: user.color,
                                note: user.note,
                                onTap: () => AppSession.loginAs(user.label),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.06),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white.withOpacity(.08)),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ملاحظات التشغيل الحالية',
                          style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '• أي دورة جديدة ينشئها مستخدم الدورات تحفظ أولًا بانتظار الموافقة.\n'
                          '• الإدارة تعتمد الدورة أو تعدّل بياناتها من لوحة القيادة ثم تفتحها للتسجيل.\n'
                          '• بعد الاعتماد فقط تصبح الدورة قابلة لإضافة الطلاب أو اعتماد التسجيل عليها.',
                          style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 12.5, height: 1.6),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginUserCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final String note;
  final VoidCallback onTap;
  const _LoginUserCard({
    required this.label,
    required this.icon,
    required this.color,
    required this.note,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(.25)),
            boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 18, offset: Offset(0, 8))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: color.withOpacity(.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 14),
              Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.dark)),
              const SizedBox(height: 8),
              Text(note, style: const TextStyle(fontSize: 12.5, color: AppTheme.textSub, height: 1.55)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text('دخول', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: color)),
                  const SizedBox(width: 6),
                  Icon(Icons.arrow_back_rounded, color: color, size: 18),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _index;

  static const _titles = [
    ('لوحة القيادة', 'نظرة شاملة فورية على المعهد'),
    ('الطلاب', 'السجلات الأساسية وملف كل طالب'),
    ('التسجيل والانتظار', 'طلبات الاختيار الحر وقوائم انتظار المدرسين'),
    ('الدورات والمجموعات', 'عدد المسجلين والإشغال والاعتماد المالي'),
    ('المدرسون', 'الإشغال والتقييم والاستحقاقات'),
    ('الجدولة والجلسات', 'الشبكة الأسبوعية بمنع التعارض'),
    ('الحضور والغياب', 'لكل مجموعة على حدة'),
    ('الامتحانات والتقييم', 'المواعيد والدرجات والشهادات'),
    ('الفواتير والأقساط', 'التحصيل والحسومات المرنة'),
    ('المحاسبة', 'حساب المادة والطالب والمعلم والصرفيات'),
    ('المخزون والأصول', 'الكميات والتنبيهات التلقائية'),
    ('التقارير', 'تقارير نهاية الجلسة والكورس'),
    ('الإعدادات', 'المستخدمون والصلاحيات والخيارات'),
  ];

  static const _icons = [
    Icons.dashboard,
    Icons.people_alt,
    Icons.app_registration,
    Icons.auto_stories,
    Icons.co_present,
    Icons.calendar_month,
    Icons.fact_check,
    Icons.quiz,
    Icons.receipt_long,
    Icons.calculate,
    Icons.inventory_2,
    Icons.assessment,
    Icons.settings,
  ];

  @override
  void initState() {
    super.initState();
    _index = AppSession.homeIndex;
  }

  @override
  Widget build(BuildContext context) {
    final screens = <Widget>[
      DashboardScreen(onNavigate: _goToIndex),
      const StudentsScreen(),
      const RegistrationScreen(),
      const CoursesScreen(),
      const TeachersScreen(),
      const ScheduleScreen(),
      const AttendanceScreen(),
      const ExamsScreen(),
      const FinanceScreen(),
      const AccountingScreen(),
      const InventoryScreen(),
      const ReportsScreen(),
      const SettingsScreen(),
    ];
    final allowedIndexes = AppSession.allowedNavIndexes.toList()..sort();
    if (!allowedIndexes.contains(_index)) {
      _index = allowedIndexes.first;
    }

    return Scaffold(
      body: Row(
        children: [
          Container(
            width: 235,
            color: AppTheme.dark,
            child: Column(
              children: [
                const SizedBox(height: 22),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(gradient: AppTheme.accentGrad, borderRadius: BorderRadius.circular(13)),
                      child: const Center(
                        child: Text('م', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('معهدّي', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                        Text('إدارة المعاهد الذكي • v3.8-fix23', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9.5)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    children: [
                      for (final i in allowedIndexes)
                        _NavItem(
                          icon: _icons[i],
                          label: _titles[i].$1,
                          selected: _index == i,
                          onTap: () => setState(() => _index = i),
                        ),
                    ],
                  ),
                ),
                Container(
                  margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.04),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withOpacity(.06)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: AppSession.isGeneralManager
                                ? AppTheme.purple
                                : (AppSession.isAccounting ? AppTheme.success : (AppSession.isCoursesManager ? AppTheme.seed : AppTheme.gold)),
                            child: const Icon(Icons.person, size: 16, color: Colors.white),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppSession.currentRole,
                                  style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  AppSession.roleSubtitle,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 9.5),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Color(0xFF334155)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          onPressed: AppSession.logout,
                          icon: const Icon(Icons.logout, size: 16),
                          label: const Text('تسجيل الخروج', style: TextStyle(fontSize: 12)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Container(
                  height: 58,
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Text(
                        _titles[_index].$1,
                        style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold, color: AppTheme.dark),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: AppTheme.line),
                        ),
                        child: Text(_titles[_index].$2, style: const TextStyle(fontSize: 10.5, color: AppTheme.textSub)),
                      ),
                      const Spacer(),
                      _TopIcon(icon: Icons.search, onTap: () {}, tooltip: 'بحث شامل'),
                      const SizedBox(width: 6),
                      Stack(
                        children: [
                          _TopIcon(icon: Icons.notifications_none, onTap: () {}, tooltip: 'الإشعارات'),
                          Positioned(
                            top: 6,
                            right: 6,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(color: AppTheme.danger, shape: BoxShape.circle),
                              child: Text(
                                '${kNotifications.length}',
                                style: const TextStyle(fontSize: 8.5, color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 6),
                      _TopIcon(icon: Icons.sync, onTap: () {}, tooltip: 'آخر مزامنة: اليوم'),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppTheme.line),
                Expanded(child: screens[_index]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _goToIndex(int index) {
    if (!AppSession.allowedNavIndexes.contains(index)) return;
    setState(() => _index = index);
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _NavItem({required this.icon, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Material(
        color: selected ? AppTheme.seed.withOpacity(.18) : Colors.transparent,
        borderRadius: BorderRadius.circular(11),
        child: InkWell(
          borderRadius: BorderRadius.circular(11),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: selected
                ? BoxDecoration(border: Border.all(color: AppTheme.seed.withOpacity(.5)), borderRadius: BorderRadius.circular(11))
                : null,
            child: Row(
              children: [
                Icon(icon, size: 19, color: selected ? AppTheme.seedLight : const Color(0xFF94A3B8)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                      color: selected ? Colors.white : const Color(0xFFCBD5E1),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TopIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  const _TopIcon({required this.icon, required this.onTap, required this.tooltip});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(color: AppTheme.line)),
          child: Icon(icon, size: 18, color: AppTheme.dark2),
        ),
      ),
    );
  }
}
