import 'package:flutter/material.dart';

/// الهوية البصرية لنظام «معهدّي» — v3 (تصميم مؤسسي حديث)
class AppTheme {
  static const Color seed = Color(0xFF0284C7);     // أزرق أساسي
  static const Color seedLight = Color(0xFF0EA5E9);
  static const Color dark = Color(0xFF0F172A);     // كحلي (السايدبار)
  static const Color dark2 = Color(0xFF1E293B);
  static const Color gold = Color(0xFFB45309);
  static const Color success = Color(0xFF15803D);
  static const Color danger = Color(0xFFB91C1C);
  static const Color purple = Color(0xFF7C3AED);
  static const Color surface = Color(0xFFF6F8FB);
  static const Color line = Color(0xFFE2E8F0);
  static const Color textSub = Color(0xFF64748B);

  static const LinearGradient accentGrad =
      LinearGradient(colors: [Color(0xFF0284C7), Color(0xFF0EA5E9)]);
  static const LinearGradient darkGrad =
      LinearGradient(colors: [Color(0xFF0F172A), Color(0xFF1E3A8A)]);

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(seedColor: seed);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: surface,
      splashFactory: InkRipple.splashFactory,
      appBarTheme: const AppBarTheme(
        backgroundColor: dark,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: AppTheme.dark,
        unselectedLabelColor: AppTheme.textSub,
        indicatorColor: AppTheme.seed,
      ),
      dropdownMenuTheme: const DropdownMenuThemeData(
        textStyle: TextStyle(fontSize: 13, color: dark),
      ),
    );
  }
}
