import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/database.dart';
import '../../data/db/weekly_daos.dart';
import '../../domain/course/course_catalog.dart';
import '../../domain/weekly/placement.dart';
import '../../domain/weekly/weekly_plan.dart';
import '../../providers.dart';
import 'placement_screen.dart';
import 'weekly_class_screen.dart';

/// The "Classe" tab: placement first, then one week at a time.
class WeeklyHomeScreen extends ConsumerWidget {
  const WeeklyHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final placement = ref.watch(placementProvider);
    final week = ref.watch(activeStudyWeekProvider);

    return SafeArea(
      child: placement.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _Message(text: '$error'),
        data: (placed) => week.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _Message(text: '$error'),
          data: (active) => ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            children: [
              Text(
                'Ma classe',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 4),
              const Text(
                'Chaque semaine : une classe, puis des exercices dans les '
                'quatre compétences, avec une large part à l’oral.',
              ),
              const SizedBox(height: 20),
              if (placed == null)
                _PlacementCard(onDone: () => _startWeekOne(context, ref))
              else if (active == null)
                _NextWeekCard(placement: placed, ref: ref)
              else
                _ActiveWeekCard(week: active),
            ],
          ),
        ),
      ),
    );
  }

  static Future<void> _startWeekOne(BuildContext context, WidgetRef ref) async {
    final placed = await ref.read(placementProvider.future);
    if (placed == null) return;
    await startNextWeek(ref, placed);
  }
}

/// Opens the next week for the placed track, binding it to the next lesson
/// that has not been taught yet.
Future<void> startNextWeek(WidgetRef ref, PlacementResult placement) async {
  final db = ref.read(appDatabaseProvider);
  if (await db.activeStudyWeek() != null) return;
  final track = courseTracks.firstWhere(
    (candidate) => candidate.id == placement.trackId,
    orElse: () => courseTracks.first,
  );
  final history = await db.weeklyHistory();
  final taught = history.map((week) => week.lessonId).toSet();
  final lesson = track.lessons.firstWhere(
    (candidate) => !taught.contains(candidate.id),
    orElse: () => track.lessons.last,
  );
  final weekNumber = history.length + 1;
  final now = DateTime.now();
  await db.createStudyWeek(
    plan: composeWeeklyPlan(
      weekNumber: weekNumber,
      trackId: track.id,
      lessonId: lesson.id,
      lessonTitleFr: lesson.title,
    ),
    startDate: DateTime(now.year, now.month, now.day),
  );
  ref.invalidate(activeStudyWeekProvider);
  ref.invalidate(activeWeekAssignmentsProvider);
}

class _PlacementCard extends StatelessWidget {
  const _PlacementCard({required this.onDone});

  final Future<void> Function() onDone;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Commencer par le placement',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Text(
            'Une courte classe de placement choisit votre parcours de départ '
            'et explique pourquoi. Cela ne prend que quelques minutes.',
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            key: const Key('weekly-placement'),
            onPressed: () async {
              final result = await Navigator.of(context).push<PlacementResult>(
                MaterialPageRoute(builder: (_) => const PlacementScreen()),
              );
              if (result != null) await onDone();
            },
            icon: const Icon(Icons.school_outlined),
            label: const Text('Faire le placement'),
          ),
        ],
      ),
    ),
  );
}

class _NextWeekCard extends StatelessWidget {
  const _NextWeekCard({required this.placement, required this.ref});

  final PlacementResult placement;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            placement.trackId == 'a-to-b-v1'
                ? 'Parcours A → B'
                : 'Parcours B → C',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Text('Aucune semaine en cours. Ouvrez la suivante.'),
          const SizedBox(height: 14),
          FilledButton.icon(
            key: const Key('weekly-start'),
            onPressed: () => startNextWeek(ref, placement),
            icon: const Icon(Icons.play_arrow),
            label: const Text('Ouvrir la semaine'),
          ),
        ],
      ),
    ),
  );
}

class _ActiveWeekCard extends ConsumerWidget {
  const _ActiveWeekCard({required this.week});

  final StudyWeek week;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = week.plan;
    final assignments = ref.watch(activeWeekAssignmentsProvider);
    final done = assignments.maybeWhen(
      data: (rows) => rows.where((row) => row.completedAt != null).length,
      orElse: () => 0,
    );
    final total = assignments.maybeWhen(
      data: (rows) => rows.length,
      orElse: () => plan.assignments.length,
    );
    final classDone = assignments.maybeWhen(
      data: (rows) => rows.any(
        (row) => row.skill == SkillKind.teaching.name && row.completedAt != null,
      ),
      orElse: () => false,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Semaine ${plan.weekNumber}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(plan.lessonTitleFr),
                const SizedBox(height: 10),
                LinearProgressIndicator(value: total == 0 ? 0 : done / total),
                const SizedBox(height: 6),
                Text('$done / $total activités terminées'),
                const SizedBox(height: 14),
                FilledButton.icon(
                  key: const Key('weekly-class'),
                  onPressed: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => WeeklyClassScreen(week: week),
                      ),
                    );
                    ref.invalidate(activeWeekAssignmentsProvider);
                  },
                  icon: const Icon(Icons.cast_for_education),
                  label: Text(
                    classDone ? 'Revoir la classe' : 'Commencer la classe',
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Vos devoirs',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        assignments.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _Message(text: '$error'),
          data: (rows) => Column(
            children: [
              for (var day = 1; day <= plan.studyDays; day++)
                _DaySection(
                  day: day,
                  rows: rows.where((row) => row.dayIndex == day).toList(),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DaySection extends StatelessWidget {
  const _DaySection({required this.day, required this.rows});

  final int day;
  final List<WeeklyAssignment> rows;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 4),
        child: Text('Jour $day', style: Theme.of(context).textTheme.titleSmall),
      ),
      for (final row in rows)
        ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          leading: Icon(
            row.completedAt != null
                ? Icons.check_circle_outline
                : Icons.radio_button_unchecked,
            size: 20,
          ),
          title: Text(row.titleFr),
          subtitle: Text(row.subtitleFr),
          trailing: Text('${row.minutes} min'),
        ),
    ],
  );
}

class _Message extends StatelessWidget {
  const _Message({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) =>
      Padding(padding: const EdgeInsets.all(20), child: Text(text));
}
