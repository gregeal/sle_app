import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/daos.dart';
import '../../domain/llm/drill_generator.dart';
import '../../domain/llm/llm_client.dart';
import '../../providers.dart';
import '../drills/drill_screen.dart';
import '../reading/reading_screen.dart';
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
            _PracticeCard(
              icon: Icons.menu_book_outlined,
              title: 'Lecture chronométrée',
              subtitle: 'Textes administratifs · QCM type ELS',
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        ReadingListScreen(themeFr: week.week.themeFr),
                  ),
                );
                ref.invalidate(progressSnapshotProvider);
              },
            ),
            const SizedBox(height: 8),
            _GenerateDrillsCard(topics: week.week.grammarTopicsList),
          ],
        ),
      ),
    );
  }
}

class _GenerateDrillsCard extends ConsumerStatefulWidget {
  const _GenerateDrillsCard({required this.topics});

  final List<String> topics;

  @override
  ConsumerState<_GenerateDrillsCard> createState() =>
      _GenerateDrillsCardState();
}

class _GenerateDrillsCardState extends ConsumerState<_GenerateDrillsCard> {
  var _isGenerating = false;

  Future<void> _generate() async {
    setState(() => _isGenerating = true);
    try {
      final client = await ref.read(llmClientProvider.future);
      final inserted = await generateDrills(
        db: ref.read(appDatabaseProvider),
        client: client,
        topics: widget.topics,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '$inserted nouveaux exercices ajoutés pour cette semaine.',
            ),
          ),
        );
      }
    } on LlmException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Génération impossible : $error')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Génération impossible : $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: ListTile(
      contentPadding: const EdgeInsets.all(18),
      leading: _isGenerating
          ? const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(strokeWidth: 3),
            )
          : const Icon(Icons.auto_awesome_outlined, size: 32),
      title: Text(
        _isGenerating
            ? 'Génération en cours…'
            : 'Générer plus d’exercices (IA)',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      subtitle: const Padding(
        padding: EdgeInsets.only(top: 4),
        child: Text(
          '10 questions type ÉLS sur les sujets de la semaine · connexion requise',
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: _isGenerating ? null : _generate,
    ),
  );
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
