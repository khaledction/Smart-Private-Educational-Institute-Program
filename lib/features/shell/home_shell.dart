import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../dashboard/dashboard_screen.dart';
import '../groups/groups_screen.dart';
import '../receipts/receipts_screen.dart';
import '../registration/registration_wizard.dart';
import '../students/students_screen.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final locale = ref.watch(localeProvider);
    final wide = MediaQuery.of(context).size.width > 700;

    final pages = const [
      DashboardScreen(),
      SingleChildScrollView(child: RegistrationWizardScreen()),
      StudentsScreen(),
      GroupsScreen(),
      ReceiptsScreen(),
    ];

    final titles = [s.dashboard, s.newRegistration, s.students, s.groups, s.receipts];
    final icons = const [
      Icons.dashboard_outlined,
      Icons.point_of_sale,
      Icons.people_outline,
      Icons.calendar_month_outlined,
      Icons.receipt_long_outlined,
    ];

    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          const Icon(Icons.school, size: 26),
          const SizedBox(width: 8),
          Text(s.appTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 12),
          Text('• ${titles[_index]}',
              style: const TextStyle(fontSize: 14, color: Colors.black54)),
        ]),
        actions: [
          // Language toggle
          TextButton.icon(
            onPressed: () => ref.read(localeProvider.notifier).state =
                locale.languageCode == 'ar'
                    ? const Locale('en')
                    : const Locale('ar'),
            icon: const Icon(Icons.translate),
            label: Text(locale.languageCode == 'ar' ? 'EN' : 'عربي'),
          ),
          IconButton(
            tooltip: s.settings,
            onPressed: () => _showSettings(context),
            icon: const Icon(Icons.settings_outlined),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Row(children: [
        if (wide)
          NavigationRail(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            labelType: NavigationRailLabelType.all,
            backgroundColor: Colors.white,
            destinations: [
              for (var i = 0; i < titles.length; i++)
                NavigationRailDestination(
                  icon: Icon(icons[i]),
                  label: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(titles[i], textAlign: TextAlign.center),
                  ),
                ),
            ],
          ),
        Expanded(child: pages[_index]),
      ]),
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
              destinations: [
                for (var i = 0; i < titles.length; i++)
                  NavigationDestination(icon: Icon(icons[i]), label: titles[i]),
              ],
            ),
    );
  }

  void _showSettings(BuildContext context) {
    final s = ref.read(stringsProvider);
    final currencyCtrl =
        TextEditingController(text: ref.read(currencyProvider));
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(s.settings),
        content: SizedBox(
          width: 300,
          child: TextField(
            controller: currencyCtrl,
            decoration: InputDecoration(labelText: s.currency),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(s.cancel)),
          FilledButton(
            onPressed: () {
              ref.read(currencyProvider.notifier).state =
                  currencyCtrl.text.trim();
              Navigator.pop(dialogContext);
            },
            child: Text(s.save),
          ),
        ],
      ),
    );
  }
}
