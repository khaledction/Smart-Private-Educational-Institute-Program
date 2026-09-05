import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets/ui.dart';

/// الإعدادات — المستخدمون والصلاحيات وخيارات النظام (§1.4، §12 من الوثيقة)
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _whatsapp = true, _backup = true, _absenceAlert = true, _lowStock = true, _aiEarly = false;

  static const _users = [
    ('المدير العام', 'مالك', 'كل الصلاحيات', AppTheme.dark),
    ('أحمد النجار', 'محاسب', 'المالية والصرفيات', AppTheme.seed),
    ('غيداء العلي', 'استقبال', 'تسجيل + حضور + مدفوعات يومية', AppTheme.success),
    ('سلمى حداد', 'منسقة أكاديمية', 'المجموعات والجداول والاعتماد', AppTheme.purple),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(flex: 3,
            child: SectionCard('مستخدمو النظام والأدوار (RBAC)',
                actionLabel: 'مستخدم جديد',
                onAction: () {},
                child: SimpleTable(columns: const ['الاسم', 'الدور', 'نطاق الصلاحيات', ''],
                  rows: [
                    for (final (name, role, scope, color) in _users)
                      [
                        Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        StatusChip(role, color: color),
                        Text(scope, style: const TextStyle(fontSize: 12)),
                        const Icon(Icons.edit, size: 16, color: AppTheme.textSub),
                      ],
                  ])),
          ),
          const SizedBox(width: 16),
          Expanded(flex: 2,
            child: SectionCard('بيانات المعهد', child: Column(children: const [
              InfoRow('اسم المعهد', 'معهد الرسالة التعليمي'),
              InfoRow('الفرع', 'الفرع الرئيسي — دمشق'),
              InfoRow('العملة', 'ليرة سورية (ل.س)'),
              InfoRow('سعة كل مجموعة (افتراضي)', '14 طالب'),
              InfoRow('نسخة النظام', 'معهدّي v3.0 — Desktop'),
              Divider(),
              InfoRow('قاعدة البيانات', 'SQLite محلي (Offline)', valueColor: AppTheme.success),
              InfoRow('آخر نسخة احتياطية', 'اليوم 9:00ص', valueColor: AppTheme.success),
            ])),
          ),
        ]),
        const SizedBox(height: 16),
        SectionCard('تفعيل الأنظمة التلقائية', child: Column(children: [
          _toggle('إشعارات واتساب للطلاب وأولياء الأمور', _whatsapp, (v) => setState(() => _whatsapp = v)),
          _toggle('نسخ احتياطي تلقائي يومي مشفّر', _backup, (v) => setState(() => _backup = v)),
          _toggle('إشعار غياب فوري لولي الأمر', _absenceAlert, (v) => setState(() => _absenceAlert = v)),
          _toggle('تنبيه انخفاض المخزون', _lowStock, (v) => setState(() => _lowStock = v)),
          _toggle('الإنذار المبكر بالذكاء الاصطناعي (تعثر/انسحاب)', _aiEarly, (v) => setState(() => _aiEarly = v)),
        ])),
      ]),
    );
  }

  Widget _toggle(String label, bool value, void Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Expanded(child: Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.dark2))),
        Switch(value: value, onChanged: onChanged, activeColor: AppTheme.seed),
      ]),
    );
  }
}
