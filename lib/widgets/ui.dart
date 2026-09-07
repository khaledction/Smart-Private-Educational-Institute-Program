import 'package:flutter/material.dart';
import '../theme.dart';

/// ===== أدوات مساعدة =====
String fmt(num v) {
  final s = v.round().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    final r = s.length - i;
    b.write(s[i]);
    if (r > 1 && r % 3 == 1) b.write(',');
  }
  return b.toString();
}

String money(num v) => '${fmt(v)} ل.س';

/// زخرفة البطاقة الموحدة
BoxDecoration cardDeco() => BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppTheme.line),
      boxShadow: const [
        BoxShadow(color: Color(0x0A0F172A), blurRadius: 10, offset: Offset(0, 2))
      ],
    );

/// ===== رأس الصفحة =====
class PageHeader extends StatelessWidget {
  final String title, subtitle;
  final List<Widget> actions;
  const PageHeader(this.title, this.subtitle, {super.key, this.actions = const []});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 4),
      child: Row(children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 21, fontWeight: FontWeight.bold, color: AppTheme.dark)),
          const SizedBox(height: 3),
          Text(subtitle, style: const TextStyle(fontSize: 12.5, color: AppTheme.textSub)),
        ]),
        const Spacer(),
        ...actions,
      ]),
    );
  }
}

/// ===== بطاقة مؤشر KPI =====
class StatCard extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;
  final String? trend;
  const StatCard(this.icon, this.label, this.value,
      {super.key, this.color = AppTheme.seed, this.trend});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: cardDeco(),
      child: Row(children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [color.withOpacity(.16), color.withOpacity(.07)]),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: color, size: 26),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: const TextStyle(fontSize: 12, color: AppTheme.textSub),
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(value,
                style: const TextStyle(
                    fontSize: 19, fontWeight: FontWeight.bold, color: AppTheme.dark)),
            if (trend != null) ...[
              const SizedBox(height: 3),
              Text(trend!, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
            ],
          ]),
        ),
      ]),
    );
  }
}

/// ===== بطاقة قسم بعنوان =====
class SectionCard extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget child;
  final EdgeInsets padding;
  const SectionCard(this.title,
      {super.key, required this.child, this.actionLabel, this.onAction,
      this.padding = const EdgeInsets.all(18)});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: cardDeco(),
      padding: padding,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.dark)),
          const Spacer(),
          if (actionLabel != null)
            TextButton(onPressed: onAction, child: Text(actionLabel!, style: const TextStyle(fontSize: 12.5))),
        ]),
        const SizedBox(height: 12),
        child,
      ]),
    );
  }
}

/// ===== شارات =====
class StatusChip extends StatelessWidget {
  final String text;
  final Color color;
  const StatusChip(this.text, {super.key, required this.color});

  static Color forStatus(String s) {
    if (s.contains('مسدد') && !s.contains('غير')) return AppTheme.success;
    if (s == 'نشط' || s == 'منطلقة' || s == 'معتمد' || s == 'مدفوع' || s == 'منتهي') return AppTheme.success;
    if (s == 'معلق' || s == 'جزئي' || s == 'قادم' || s == 'مجدول' || s == 'قائمة انتظار' || s == 'متأخر') {
      return s == 'متأخر' ? AppTheme.danger : AppTheme.gold;
    }
    if (s == 'مرفوض' || s == 'متوقف' || s == 'منطلق' ) return AppTheme.danger;
    return AppTheme.seed;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(.11),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(.35)),
      ),
      child: Text(text,
          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: color)),
    );
  }
}

class PeriodBadge extends StatelessWidget {
  final String period; // صباحي / ظهر / مسائي
  const PeriodBadge(this.period, {super.key});

  @override
  Widget build(BuildContext context) {
    final (icon, label, c) = switch (period) {
      'صباحي' => ('☀', 'صباحي', Color(0xFFB45309)),
      'ظهر' => ('🌤', 'ع الظهر', Color(0xFF0F766E)),
      _ => ('🌙', 'مسائي', Color(0xFF4338CA)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.withOpacity(.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text('$icon $label',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: c)),
    );
  }
}

class CountBadge extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const CountBadge(this.label, this.count, {super.key, this.color = AppTheme.gold});

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(.35)),
      ),
      child: Text('$label: $count',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
    );
  }
}

/// ===== شريط الإشغال =====
class FillBar extends StatelessWidget {
  final int value, max;
  final double height;
  const FillBar(this.value, this.max, {super.key, this.height = 8});

  @override
  Widget build(BuildContext context) {
    final ratio = max == 0 ? 0.0 : (value / max).clamp(0.0, 1.0);
    final color = ratio >= 1 ? AppTheme.danger : (ratio >= .8 ? AppTheme.gold : AppTheme.success);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: LinearProgressIndicator(
          value: ratio,
          minHeight: height,
          backgroundColor: AppTheme.line,
          valueColor: AlwaysStoppedAnimation(color),
        ),
      ),
      const SizedBox(height: 6),
      Text('$value / $max',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
    ]);
  }
}

/// ===== جدول بيانات موحد =====
class SimpleTable extends StatelessWidget {
  final List<String> columns;
  final List<List<Widget>> rows;
  final List<DataColumn>? customColumns;
  const SimpleTable({super.key, required this.columns, required this.rows, this.customColumns});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: cardDeco(),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: const WidgetStatePropertyAll(Color(0xFFF1F5F9)),
          headingTextStyle: const TextStyle(
              fontSize: 12.5, fontWeight: FontWeight.bold, color: AppTheme.dark2),
          dataTextStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF334155)),
          columns: (customColumns ?? [
            for (final c in columns) DataColumn(label: Text(c)),
          ]),
          rows: [
            for (final r in rows) DataRow(cells: [for (final cell in r) DataCell(cell)]),
          ],
        ),
      ),
    );
  }
}

/// ===== الرسوم البيانية (مرسومة يدويًا — بلا حزم) =====
class DonutChart extends StatelessWidget {
  final List<(String, double, Color)> data;
  final String centerValue, centerLabel;
  final double size;
  const DonutChart(this.data,
      {super.key, required this.centerValue, required this.centerLabel, this.size = 170});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(alignment: Alignment.center, children: [
        CustomPaint(
          size: Size(size, size),
          painter: _DonutPainter(data.map((d) => d.$2).toList(),
              data.map((d) => d.$3).toList()),
        ),
        Column(mainAxisSize: MainAxisSize.min, children: [
          Text(centerValue,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.dark)),
          Text(centerLabel, style: const TextStyle(fontSize: 11, color: AppTheme.textSub)),
        ]),
      ]),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;
  _DonutPainter(this.values, this.colors);

  @override
  void paint(Canvas canvas, Size size) {
    final total = values.fold<double>(0.0, (a, b) => a + b);
    if (total == 0) return;
    final rect = Offset.zero & size;
    const stroke = 22.0;
    var start = -3.14159 / 2;
    for (var i = 0; i < values.length; i++) {
      final sweep = 2 * 3.14159 * (values[i] / total);
      canvas.drawArc(rect.deflate(stroke / 2), start, sweep - 0.02, false,
        Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.butt
        ..color = colors[i % colors.length]);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class BarsChart extends StatelessWidget {
  final List<(String, double)> items;
  final String unit;
  final double maxHeight;
  const BarsChart(this.items, {super.key, this.unit = 'م', this.maxHeight = 120});

  @override
  Widget build(BuildContext context) {
    final maxV = items.map((e) => e.$2).fold<double>(0.0001, (a, b) => a > b ? a : b);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final (label, v) in items)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Column(children: [
                Text(v.toStringAsFixed(1),
                    style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppTheme.dark2)),
                const SizedBox(height: 4),
                Container(
                  height: maxHeight * (v / maxV),
                  decoration: BoxDecoration(
                    gradient: AppTheme.accentGrad,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                  ),
                ),
                const SizedBox(height: 6),
                Text(label, style: const TextStyle(fontSize: 10.5, color: AppTheme.textSub)),
              ]),
            ),
          ),
      ],
    );
  }
}

/// ===== لوحة منزلقة جانبية (قائمة منزلقة) =====
void showSidePanel(BuildContext context,
    {required String title, required WidgetBuilder builder}) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'إغلاق اللوحة',
    barrierColor: Colors.black38,
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (_, __, ___) => Align(
      alignment: AlignmentDirectional.centerEnd,
      child: Material(
        color: Colors.white,
        child: SizedBox(
          width: 480,
          height: double.infinity,
          child: Column(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(color: AppTheme.dark),
              child: Row(children: [
                Text(title,
                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                const Spacer(),
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => Navigator.pop(context),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.close, size: 20, color: Color(0xFF94A3B8)),
                  ),
                ),
              ]),
            ),
            Expanded(child: builder(context)),
          ]),
        ),
      ),
    ),
    transitionBuilder: (_, anim, __, child) => SlideTransition(
      position: Tween(begin: const Offset(-1, 0), end: Offset.zero)
          .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
      child: child,
    ),
  );
}

/// ===== سطر معلومة =====
class InfoRow extends StatelessWidget {
  final String label, value;
  final Color? valueColor;
  const InfoRow(this.label, this.value, {super.key, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(children: [
        Text(label, style: const TextStyle(fontSize: 12.5, color: AppTheme.textSub)),
        const Spacer(),
        Text(value,
            style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: valueColor ?? AppTheme.dark)),
      ]),
    );
  }
}

/// ===== زر رئيسي =====
class PrimaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final Color color;
  const PrimaryButton(this.label, {super.key, this.icon, this.onPressed, this.color = AppTheme.seed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
    );
  }
}
