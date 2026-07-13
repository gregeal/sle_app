import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/practice/practice_screen.dart';
import 'features/progress/progress_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/today/today_screen.dart';
import 'providers.dart';

class SlePrepApp extends ConsumerWidget {
  const SlePrepApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seedImport = ref.watch(seedImportProvider);

    return MaterialApp(
      title: 'Objectif C',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xff3b5ba9),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xfffaf9fd),
        useMaterial3: true,
      ),
      home: seedImport.when(
        data: (_) => const AppShell(),
        loading: () => const _StartupScreen(),
        error: (error, _) => _StartupError(error: error),
      ),
    );
  }
}

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  var _index = 0;

  static const _screens = [
    TodayScreen(),
    PracticeScreen(),
    ProgressScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    body: IndexedStack(index: _index, children: _screens),
    bottomNavigationBar: NavigationBar(
      selectedIndex: _index,
      onDestinationSelected: (index) => setState(() => _index = index),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Accueil',
        ),
        NavigationDestination(
          icon: Icon(Icons.style_outlined),
          selectedIcon: Icon(Icons.style),
          label: 'Réviser',
        ),
        NavigationDestination(
          icon: Icon(Icons.bar_chart_outlined),
          selectedIcon: Icon(Icons.bar_chart),
          label: 'Progrès',
        ),
        NavigationDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings),
          label: 'Paramètres',
        ),
      ],
    ),
  );
}

class _StartupScreen extends StatelessWidget {
  const _StartupScreen();

  @override
  Widget build(BuildContext context) => const Scaffold(
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Préparation de vos exercices hors ligne…'),
        ],
      ),
    ),
  );
}

class _StartupError extends ConsumerWidget {
  const _StartupError({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Impossible de préparer les exercices.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '$error',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => ref.invalidate(seedImportProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    ),
  );
}
