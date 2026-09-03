import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/providers.dart';
import 'core/theme.dart';
import 'features/shell/home_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Supabase (uncomment when your project is ready) ──────────────────────
  // import 'package:supabase_flutter/supabase_flutter.dart';
  // await Supabase.initialize(
  //   url: 'https://YOUR-PROJECT.supabase.co',
  //   anonKey: 'YOUR-ANON-KEY',
  // );
  // Then in core/providers.dart switch repositoryProvider to:
  //   SupabaseInstituteRepository()

  runApp(const ProviderScope(child: SmartInstituteApp()));
}

class SmartInstituteApp extends ConsumerWidget {
  const SmartInstituteApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    return MaterialApp(
      title: 'Smart Institute | المعهد الذكي',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      locale: locale,
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const HomeShell(),
    );
  }
}
