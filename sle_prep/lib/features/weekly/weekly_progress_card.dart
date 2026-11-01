import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/db/weekly_daos.dart';
import '../../providers.dart';
import '../../domain/weekly/weekly_report.dart';
import 'weekly_providers.dart';
import 'weekly_report_screen.dart';

final weeklyMetricsProvider = FutureProvider<Map<String, dynamic>?>((
  ref,
) async {
  ref.watch(dailyStudyPlanProvider);
  ref.watch(activeWeekAssignmentsProvider);
  final db = ref.watch(appDatabaseProvider);
  final history = await db.weeklyHistory();
  if (history.isEmpty) return null;
  final week = await db.activeStudyWeek() ?? history.first;
  return {
    'week': week,
    'snapshot': await db.weeklySnapshot(week.id),
    'job': await db.weeklyFeedback(week.id),
  };
});

class WeeklyProgressCard extends ConsumerWidget {
  const WeeklyProgressCard({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(weeklyMetricsProvider)
      .when(
        loading: () => const SizedBox.shrink(),
        error: (e, _) => Text('Statistiques hebdomadaires indisponibles : $e'),
        data: (value) {
          if (value == null) return const SizedBox.shrink();
          final snapshot = value['snapshot'] as Map<String, dynamic>;
          final rows = List<Map<String, dynamic>>.from(snapshot['assignments']);
          final evidence = List<Map<String, dynamic>>.from(
            snapshot['evidence'],
          );
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Semaine ${value['week'].weekNumber} · quatre compétences',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  for (final skill in [
                    'speaking',
                    'listening',
                    'reading',
                    'writing',
                  ]) ...[
                    Text(
                      '${weeklySkillLabel(skill)} : ${rows.where((a) => a['skill'] == skill).fold<int>(0, (n, a) => n + (a['minutes'] as int))} min prévues · ${rows.where((a) => a['skill'] == skill && a['completed'] == true && a['verified'] == true).fold<int>(0, (n, a) => n + (a['minutes'] as int))} min créditées',
                    ),
                    Text(
                      '${evidence.where((e) => e['skill'] == skill).fold<int>(0, (n, e) => n + ((e['observedSeconds'] as int?) ?? 0)) ~/ 60} min observées · ${evidence.where((e) => e['skill'] == skill && (e['assisted'] == true || e['selfReported'] == true)).length} preuves assistées / auto-déclarées',
                    ),
                  ],
                  const Text(
                    'Le temps de conversation inclut les tours de l’IA. Il ne mesure pas votre temps de parole.',
                  ),
                  if (value['week'].status == 'closed')
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              WeeklyReportScreen(week: value['week']),
                        ),
                      ),
                      child: Text(
                        'Bilan : ${weeklyFeedbackLabel(value['job']?.status)}',
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      );
}
