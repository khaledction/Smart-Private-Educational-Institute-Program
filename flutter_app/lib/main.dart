import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'theme.dart';
import 'widgets/ui.dart';
import 'data/mock_data.dart';
import 'data/registration_store.dart';
import 'data/student_store.dart';
import 'screens/dashboard.dart';
import 'screens/students.dart';
import 'screens/registration.dart';
import 'screens/courses.dart';
import 'screens/teachers.dart';
import 'screens/schedule.dart';
import 'screens/attendance.dart';
import 'screens/exams.dart';
import 'screens/finance.dart';
import 'screens/accounting.dart';
import 'screens/inventory.dart';
import 'screens/reports.dart';
import 'screens/settings.dart';

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
      home: const MainShell(),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
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
    Icons.dashboard, Icons.people_alt, Icons.app_registration, Icons.auto_stories,
    Icons.co_present, Icons.calendar_month, Icons.fact_check, Icons.quiz,
    Icons.receipt_long, Icons.calculate, Icons.inventory_2, Icons.assessment, Icons.settings,
  ];

  @override
  Widget build(BuildContext context) {
    final screens = <Widget>[
      DashboardScreen(onNavigate: (i) => setState(() => _index = i)),
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

    return Scaffold(
      body: Row(children: [
        // ===== السايدبار =====
        Container(
          width: 235,
          color: AppTheme.dark,
          child: Column(children: [
            const SizedBox(height: 22),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(gradient: AppTheme.accentGrad, borderRadius: BorderRadius.circular(13)),
                child: const Center(child: Text('م', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold))),
              ),
              const SizedBox(width: 10),
              const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('معهدّي', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                Text('إدارة المعاهد الذكي • v3.8', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9.5)),
              ]),
            ]),
            const SizedBox(height: 18),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                children: [
                  for (var i = 0; i < _titles.length; i++)
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
              padding: const EdgeInsets.all(14),
              child: const Row(children: [
                CircleAvatar(radius: 16, backgroundColor: AppTheme.seed, child: Icon(Icons.person, size: 16, color: Colors.white)),
                SizedBox(width: 8),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('المدير العام', style: TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold)),
                  Text('معهد الرسالة — الرئيسي', style: TextStyle(color: Color(0xFF64748B), fontSize: 9.5)),
                ])),
              ]),
            ),
          ]),
        ),
        // ===== المحتوى =====
        Expanded(
          child: Column(children: [
            Container(
              height: 58,
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(children: [
                Text(_titles[_index].$1,
                    style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold, color: AppTheme.dark)),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(999), border: Border.all(color: AppTheme.line)),
                  child: Text(_titles[_index].$2, style: const TextStyle(fontSize: 10.5, color: AppTheme.textSub)),
                ),
                const Spacer(),
                _TopIcon(icon: Icons.search, onTap: () {}, tooltip: 'بحث شامل'),
                const SizedBox(width: 6),
                Stack(children: [
                  _TopIcon(icon: Icons.notifications_none, onTap: () {}, tooltip: 'الإشعارات'),
                  Positioned(
                    top: 6, right: 6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: AppTheme.danger, shape: BoxShape.circle),
                      child: Text('${kNotifications.length}',
                          style: TextStyle(fontSize: 8.5, color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ]),
                const SizedBox(width: 6),
                _TopIcon(icon: Icons.sync, onTap: () {}, tooltip: 'آخر مزامنة: اليوم'),
              ]),
            ),
            const Divider(height: 1, color: AppTheme.line),
            Expanded(child: screens[_index]),
          ]),
        ),
      ]),
    );
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
            child: Row(children: [
              Icon(icon, size: 19, color: selected ? AppTheme.seedLight : const Color(0xFF94A3B8)),
              const SizedBox(width: 10),
              Expanded(child: Text(label,
                  style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                      color: selected ? Colors.white : const Color(0xFFCBD5E1)))),
            ]),
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
