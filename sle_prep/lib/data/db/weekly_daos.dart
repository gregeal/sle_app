import 'dart:convert';

import 'package:drift/drift.dart';

import '../../domain/weekly/weekly_plan.dart';
import 'daos.dart';
import 'database.dart';

const _activeWeekSetting = 'weekly:activeWeekId';

/// Evidence kinds a completed assignment may point at.
const weeklyEvidenceKinds = {
  'speakingSession',
  'writingAttempt',
  'readingAttempt',
  'listeningAttempt',
  'drillAttempt',
  'courseLesson',
};

String _dateKey(DateTime day) =>
    '${day.year.toString().padLeft(4, '0')}-'
    '${day.month.toString().padLeft(2, '0')}-'
    '${day.day.toString().padLeft(2, '0')}';

extension StudyWeekPlan on StudyWeek {
  /// The exact plan the learner was given when the week opened.
  WeeklyPlan get plan =>
      WeeklyPlan.fromJson(jsonDecode(planJson) as Map<String, dynamic>);
}

extension WeeklyAssignmentPayload on WeeklyAssignment {
  Map<String, dynamic> get payload =>
      jsonDecode(payloadJson) as Map<String, dynamic>;
  bool get completed => completedAt != null;
}

extension WeeklyDaos on AppDatabase {
  /// Opens a week from a composed plan. Exactly one week may be active, so the
  /// previous one must be closed (which is what produces its report) first.
  Future<int> createStudyWeek({
    required WeeklyPlan plan,
    required DateTime startDate,
  }) => transaction(() async {
    if (await activeStudyWeek() != null) {
      throw StateError(
        'Close the active week before opening another one.',
      );
    }
    final now = DateTime.now();
    final weekId = await into(studyWeeks).insert(
      StudyWeeksCompanion.insert(
        weekNumber: plan.weekNumber,
        trackId: plan.trackId,
        lessonId: plan.lessonId,
        startDate: _dateKey(startDate),
        planJson: jsonEncode(plan.toJson()),
        createdAt: now,
      ),
    );
    for (final spec in plan.assignments) {
      await into(weeklyAssignments).insert(
        WeeklyAssignmentsCompanion.insert(
          weekId: weekId,
          specId: spec.id,
          dayIndex: spec.dayIndex,
          skill: spec.skill.name,
          minutes: spec.minutes,
          titleFr: spec.titleFr,
          subtitleFr: spec.subtitleFr,
          payloadJson: jsonEncode(spec.payload),
        ),
      );
    }
    await setSetting(_activeWeekSetting, '$weekId');
    return weekId;
  });

  Future<StudyWeek?> studyWeek(int id) =>
      (select(studyWeeks)..where((w) => w.id.equals(id))).getSingleOrNull();

  Future<StudyWeek?> activeStudyWeek() async {
    final row =
        await (select(studyWeeks)
              ..where((w) => w.status.equals('active'))
              ..orderBy([(w) => OrderingTerm.desc(w.id)])
              ..limit(1))
            .getSingleOrNull();
    return row;
  }

  /// Newest first.
  Future<List<StudyWeek>> weeklyHistory() =>
      (select(studyWeeks)..orderBy([(w) => OrderingTerm.desc(w.weekNumber)]))
          .get();

  Future<List<WeeklyAssignment>> assignmentsForWeek(int weekId) =>
      (select(weeklyAssignments)
            ..where((a) => a.weekId.equals(weekId))
            ..orderBy([
              (a) => OrderingTerm.asc(a.dayIndex),
              (a) => OrderingTerm.asc(a.id),
            ]))
          .get();

  Future<WeeklyAssignment> weeklyAssignment(int id) =>
      (select(weeklyAssignments)..where((a) => a.id.equals(id))).getSingle();

  Future<List<WeeklyAssignment>> assignmentsForDay(int weekId, int dayIndex) =>
      (select(weeklyAssignments)
            ..where((a) => a.weekId.equals(weekId) & a.dayIndex.equals(dayIndex))
            ..orderBy([(a) => OrderingTerm.asc(a.id)]))
          .get();

  /// Marks an assignment done. The first completion wins, so re-opening a
  /// finished activity never rewrites the evidence or the timestamp.
  Future<void> completeAssignment(
    int assignmentId, {
    String? evidenceKind,
    int? evidenceId,
    required DateTime at,
  }) {
    if ((evidenceKind == null) != (evidenceId == null)) {
      throw ArgumentError(
        'Evidence needs both a kind and an id, or neither.',
      );
    }
    if (evidenceKind != null && !weeklyEvidenceKinds.contains(evidenceKind)) {
      throw ArgumentError.value(evidenceKind, 'evidenceKind', 'Unknown kind');
    }
    if (evidenceId != null && evidenceId < 1) {
      throw ArgumentError.value(evidenceId, 'evidenceId', 'Invalid id');
    }
    return transaction(() async {
      final current = await weeklyAssignment(assignmentId);
      if (current.completedAt != null) return;
      await (update(weeklyAssignments)
            ..where((a) => a.id.equals(assignmentId)))
          .write(
            WeeklyAssignmentsCompanion(
              completedAt: Value(at),
              evidenceKind: Value(evidenceKind),
              evidenceId: Value(evidenceId),
            ),
          );
    });
  }

  /// Minutes per [SkillKind] name for a week. Skills with no minutes are
  /// absent rather than zero, so a caller can tell "not planned" from "planned
  /// but not done yet".
  Future<Map<String, int>> weeklyMinutesBySkill(
    int weekId, {
    bool completedOnly = false,
  }) async {
    final rows = await assignmentsForWeek(weekId);
    final totals = <String, int>{};
    for (final row in rows) {
      if (completedOnly && row.completedAt == null) continue;
      totals[row.skill] = (totals[row.skill] ?? 0) + row.minutes;
    }
    return totals;
  }

  Future<void> closeStudyWeek(
    int weekId, {
    required String reportJson,
    required DateTime at,
  }) => transaction(() async {
    final week = await studyWeek(weekId);
    if (week == null || week.status != 'active') {
      throw StateError('Only an active week can be closed.');
    }
    await (update(studyWeeks)..where((w) => w.id.equals(weekId))).write(
      StudyWeeksCompanion(
        status: const Value('closed'),
        reportJson: Value(reportJson),
        closedAt: Value(at),
      ),
    );
    await setSetting(_activeWeekSetting, '');
  });
}
