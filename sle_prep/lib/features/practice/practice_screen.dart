import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/daos.dart';
import '../../providers.dart';
import '../drills/drill_screen.dart';
import '../vocab/vocab_review_screen.dart';

class PracticeScreen extends ConsumerWidget {
  const PracticeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeWeek = ref.watch(activeWeekProvider);
    return SafeArea(
      child: activeWeek.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (week) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          children: [
            Text('Réviser', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text('Semaine ${week.number} · ${week.week.themeFr}'),
            const SizedBox(height: 16),
            _PracticeCard(
              icon: Icons.style_outlined,
              title: 'Vocabulaire',
              subtitle: 'Cartes dues · répétition espacée',
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const VocabReviewScreen()),
                );
                ref.invalidate(dueCardsProvider);
                ref.invalidate(todayPlanProvider);
                ref.invalidate(progressSnapshotProvider);
              },
            ),
            _PracticeCard(
              icon: Icons.edit_note_outlined,
              title: 'Grammaire type ÉLS',
              subtitle: week.week.grammarTopicsList.join(' · '),
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        DrillScreen(topics: week.week.grammarTopicsList),
                  ),
                );
                ref.invalidate(todayPlanProvider);
                ref.invalidate(progressSnapshotProvider);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PracticeCard extends StatelessWidget {
  const _PracticeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: ListTile(
      contentPadding: const EdgeInsets.all(18),
      leading: Icon(icon, size: 32),
      title: Text(title, style: Theme.of(context).textTheme.titleLarge),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(subtitle),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    ),
  );
}
