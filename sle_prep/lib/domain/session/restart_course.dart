import '../../data/db/daos.dart';
import '../../data/db/database.dart';
import 'session_composer.dart';

/// Restarts only the calendar, not the learner's accumulated knowledge/history.
/// Today's completed blocks remain as distinct, completed entries; unfinished
/// work is replaced with week-one work. The transaction prevents partial resets.
Future<void> restartCourse(
  AppDatabase db,
  DateTime now,
) => db.transaction(() async {
  final day = DateTime(now.year, now.month, now.day);
  final dateKey =
      '${day.year.toString().padLeft(4, '0')}-'
      '${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
  if (await db.getSetting('planStartDate') == dateKey) return;
  final week = await db.weekByNumber(1);
  if (week == null) throw StateError('Week one is unavailable');
  final endOfDay = DateTime(
    day.year,
    day.month,
    day.day + 1,
  ).subtract(const Duration(microseconds: 1));
  final blocks = composeSession(
    dueCardCount: await db.dueCardCount(endOfDay),
    grammarTopics: week.grammarTopicsList,
    topicAccuracy: await db.topicAccuracy(),
    resources: week.resourceSlotsList
        .map(
          (slot) => SessionResource(
            label: slot['label'] as String,
            url: slot['url'] as String,
          ),
        )
        .toList(),
    targetMinutes: 75,
  );
  final old = await db.sessionLogFor(day);
  final completedIds = old?.blocksCompletedList.toSet() ?? <String>{};
  final completed =
      old?.planSnapshotList
          .where((block) => completedIds.contains(block.id))
          .toList() ??
      <SessionBlock>[];
  if (completed.length != completedIds.length) {
    throw StateError(
      'Open today’s plan before restarting to recover its legacy history',
    );
  }
  final retained = [
    for (final (index, block) in completed.indexed)
      SessionBlock(
        id: 'course-retained-$index',
        type: block.type,
        minutes: block.minutes,
        titleFr: block.titleFr,
        subtitleFr: block.id.startsWith('course-retained-')
            ? block.subtitleFr
            : 'Terminé avant le redémarrage · ${block.subtitleFr}',
        grammarTopics: block.grammarTopics,
        resource: block.resource,
      ),
  ];
  await db.upsertSessionLog(
    day: day,
    blocksPlanned: [...retained, ...blocks].map((block) => block.id).toList(),
    blocksCompleted: retained.map((block) => block.id).toList(),
    minutesActive: old?.minutesActive ?? 0,
    planSnapshot: [...retained, ...blocks],
  );
  await db.setSetting('planStartDate', dateKey);
});
