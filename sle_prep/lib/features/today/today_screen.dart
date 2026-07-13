import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/db/daos.dart';
import '../../data/db/database.dart';
import '../../domain/session/session_composer.dart';
import '../../providers.dart';
import '../drills/drill_screen.dart';
import '../vocab/vocab_review_screen.dart';

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref.watch(todayPlanProvider);
    final sessionLog = ref.watch(todaySessionLogProvider);
    final progress = ref.watch(progressSnapshotProvider);

    return SafeArea(
      child: plan.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _TodayError(error: error),
        data: (loadedPlan) => sessionLog.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _TodayError(error: error),
          data: (log) => _TodayContent(
            plan: loadedPlan,
            sessionLog: log,
            streak: progress.when(
              data: (snapshot) => snapshot.streak,
              loading: () => 0,
              error: (_, _) => 0,
            ),
            onOpen: (block) => _openBlock(context, ref, block),
            onToggleComplete: (block) =>
                _toggleComplete(ref, loadedPlan, log, block),
          ),
        ),
      ),
    );
  }

  Future<void> _openBlock(
    BuildContext context,
    WidgetRef ref,
    SessionBlock block,
  ) async {
    switch (block.type) {
      case BlockType.vocabReview:
        await Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const VocabReviewScreen()));
      case BlockType.grammarDrill:
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                DrillScreen(topics: block.grammarTopics, title: block.titleFr),
          ),
        );
      case BlockType.resource:
        final resource = block.resource;
        if (resource == null) return;
        final opened = await launchUrl(
          Uri.parse(resource.url),
          mode: LaunchMode.externalApplication,
        );
        if (!opened && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Impossible d’ouvrir cette ressource.'),
            ),
          );
        }
      case BlockType.freePractice:
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Décrivez le thème de la semaine à voix haute pendant quelques minutes.',
              ),
            ),
          );
        }
    }
    ref.invalidate(dueCardsProvider);
    ref.invalidate(todayPlanProvider);
    ref.invalidate(progressSnapshotProvider);
  }

  Future<void> _toggleComplete(
    WidgetRef ref,
    TodayPlan plan,
    SessionLog? existingLog,
    SessionBlock block,
  ) async {
    final completed = <String>{...?existingLog?.blocksCompletedList};
    if (!completed.add(block.id)) {
      completed.remove(block.id);
    }
    final completedMinutes = plan.blocks
        .where((candidate) => completed.contains(candidate.id))
        .fold(0, (total, candidate) => total + candidate.minutes);
    await ref
        .read(appDatabaseProvider)
        .upsertSessionLog(
          day: plan.day,
          blocksPlanned: plan.blocks.map((candidate) => candidate.id).toList(),
          blocksCompleted: completed.toList(),
          minutesActive: completedMinutes,
        );
    ref.invalidate(todaySessionLogProvider);
    ref.invalidate(progressSnapshotProvider);
  }
}

class _TodayContent extends StatelessWidget {
  const _TodayContent({
    required this.plan,
    required this.sessionLog,
    required this.streak,
    required this.onOpen,
    required this.onToggleComplete,
  });

  final TodayPlan plan;
  final SessionLog? sessionLog;
  final int streak;
  final ValueChanged<SessionBlock> onOpen;
  final ValueChanged<SessionBlock> onToggleComplete;

  @override
  Widget build(BuildContext context) {
    final completed = sessionLog?.blocksCompletedList.toSet() ?? <String>{};
    final plannedMinutes = plan.blocks.fold(
      0,
      (sum, block) => sum + block.minutes,
    );
    final completedMinutes = plan.blocks
        .where((block) => completed.contains(block.id))
        .fold(0, (sum, block) => sum + block.minutes);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _dateLabel(plan.day),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            if (streak > 0)
              Chip(
                avatar: const Icon(Icons.local_fire_department_outlined),
                label: Text('$streak j'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text('Bonjour', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 4),
        Text(
          'Semaine ${plan.activeWeek.number} de 26 · ${plan.activeWeek.week.themeFr}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        Card(
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Séance d’aujourd’hui',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  '$plannedMinutes min prévues · $completedMinutes min terminées',
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: plannedMinutes == 0
                      ? 0
                      : completedMinutes / plannedMinutes,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        ...plan.blocks.map(
          (block) => _SessionBlockCard(
            block: block,
            completed: completed.contains(block.id),
            onOpen: () => onOpen(block),
            onToggleComplete: () => onToggleComplete(block),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Touchez un bloc pour le commencer. Cochez-le une fois terminé.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _SessionBlockCard extends StatelessWidget {
  const _SessionBlockCard({
    required this.block,
    required this.completed,
    required this.onOpen,
    required this.onToggleComplete,
  });

  final SessionBlock block;
  final bool completed;
  final VoidCallback onOpen;
  final VoidCallback onToggleComplete;

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: ListTile(
      onTap: onOpen,
      leading: Icon(_iconFor(block.type)),
      title: Text(
        block.titleFr,
        style: TextStyle(
          decoration: completed ? TextDecoration.lineThrough : null,
        ),
      ),
      subtitle: Text(block.subtitleFr),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('${block.minutes} min'),
          IconButton(
            tooltip: completed ? 'Marquer à faire' : 'Marquer terminé',
            onPressed: onToggleComplete,
            icon: Icon(
              completed ? Icons.check_circle : Icons.radio_button_unchecked,
              color: completed ? Theme.of(context).colorScheme.primary : null,
            ),
          ),
        ],
      ),
    ),
  );
}

IconData _iconFor(BlockType type) => switch (type) {
  BlockType.vocabReview => Icons.style_outlined,
  BlockType.grammarDrill => Icons.edit_note_outlined,
  BlockType.resource => Icons.headphones_outlined,
  BlockType.freePractice => Icons.chat_bubble_outline,
};

String _dateLabel(DateTime date) {
  const days = [
    'lundi',
    'mardi',
    'mercredi',
    'jeudi',
    'vendredi',
    'samedi',
    'dimanche',
  ];
  const months = [
    'janvier',
    'février',
    'mars',
    'avril',
    'mai',
    'juin',
    'juillet',
    'août',
    'septembre',
    'octobre',
    'novembre',
    'décembre',
  ];
  return '${days[date.weekday - 1]} ${date.day} ${months[date.month - 1]}';
}

class _TodayError extends ConsumerWidget {
  const _TodayError({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48),
          const SizedBox(height: 12),
          const Text('Impossible de composer la séance.'),
          const SizedBox(height: 8),
          Text('$error', textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () {
              ref.invalidate(activeWeekProvider);
              ref.invalidate(todayPlanProvider);
              ref.invalidate(todaySessionLogProvider);
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
          ),
        ],
      ),
    ),
  );
}
