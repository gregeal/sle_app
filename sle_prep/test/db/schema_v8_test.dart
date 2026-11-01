import 'package:flutter_test/flutter_test.dart';
import 'package:sle_prep/data/db/weekly_daos.dart';
import 'package:sle_prep/domain/weekly/weekly_plan.dart';

import '../support/test_db.dart';

WeeklyPlan samplePlan({int weekNumber = 1}) => composeWeeklyPlan(
  weekNumber: weekNumber,
  trackId: 'b-to-c-v1',
  lessonId: 'bc-0$weekNumber-lesson',
  lessonTitleFr: 'Leçon $weekNumber',
);

void main() {
  final monday = DateTime(2026, 11, 2);

  group('creating a week', () {
    test('stores the plan snapshot and every assignment', () async {
      final db = inMemoryDatabase();
      addTearDown(db.close);
      final plan = samplePlan();

      final weekId = await db.createStudyWeek(plan: plan, startDate: monday);

      final week = await db.activeStudyWeek();
      expect(week, isNotNull);
      expect(week!.id, weekId);
      expect(week.weekNumber, 1);
      expect(week.trackId, 'b-to-c-v1');
      expect(week.startDate, '2026-11-02');
      expect(week.status, 'active');
      expect(week.reportJson, isNull);

      // The snapshot must restore the exact plan the learner was given.
      expect(week.plan.toJson(), plan.toJson());

      final assignments = await db.assignmentsForWeek(weekId);
      expect(assignments, hasLength(plan.assignments.length));
      expect(
        assignments.map((row) => row.specId).toSet(),
        plan.assignments.map((spec) => spec.id).toSet(),
      );
      expect(assignments.every((row) => row.completedAt == null), isTrue);
    });

    test('refuses a second active week', () async {
      final db = inMemoryDatabase();
      addTearDown(db.close);
      await db.createStudyWeek(plan: samplePlan(), startDate: monday);

      await expectLater(
        db.createStudyWeek(plan: samplePlan(weekNumber: 2), startDate: monday),
        throwsStateError,
      );
      expect(await db.weeklyHistory(), hasLength(1));
    });

    test('day lookups return that day in plan order', () async {
      final db = inMemoryDatabase();
      addTearDown(db.close);
      final plan = samplePlan();
      final weekId = await db.createStudyWeek(plan: plan, startDate: monday);

      final day1 = await db.assignmentsForDay(weekId, 1);
      expect(day1.first.skill, 'teaching');
      expect(day1[1].skill, 'speaking');
      expect(
        day1.fold<int>(0, (sum, row) => sum + row.minutes),
        plan.minutesPerDay,
      );
      expect(await db.assignmentsForDay(weekId, 99), isEmpty);
    });
  });

  group('completing work', () {
    test('records evidence once and stays idempotent', () async {
      final db = inMemoryDatabase();
      addTearDown(db.close);
      final weekId = await db.createStudyWeek(
        plan: samplePlan(),
        startDate: monday,
      );
      final speaking = (await db.assignmentsForWeek(
        weekId,
      )).firstWhere((row) => row.skill == 'speaking');

      final at = DateTime(2026, 11, 2, 19, 30);
      await db.completeAssignment(
        speaking.id,
        evidenceKind: 'speakingSession',
        evidenceId: 42,
        at: at,
      );
      await db.completeAssignment(
        speaking.id,
        evidenceKind: 'speakingSession',
        evidenceId: 77,
        at: at.add(const Duration(hours: 2)),
      );

      final stored = await db.weeklyAssignment(speaking.id);
      expect(stored.completedAt, at, reason: 'first completion wins');
      expect(stored.evidenceId, 42);
      expect(stored.evidenceKind, 'speakingSession');
    });

    test('accepts completion without evidence but rejects half a pair', () async {
      final db = inMemoryDatabase();
      addTearDown(db.close);
      final weekId = await db.createStudyWeek(
        plan: samplePlan(),
        startDate: monday,
      );
      final rows = await db.assignmentsForWeek(weekId);

      await db.completeAssignment(rows.first.id, at: monday);
      expect((await db.weeklyAssignment(rows.first.id)).completedAt, monday);

      // Validation is synchronous, like the other DAOs in this app.
      expect(
        () => db.completeAssignment(
          rows[1].id,
          evidenceKind: 'readingAttempt',
          at: monday,
        ),
        throwsArgumentError,
      );
      expect(
        () => db.completeAssignment(rows[1].id, evidenceId: 3, at: monday),
        throwsArgumentError,
      );
      expect((await db.weeklyAssignment(rows[1].id)).completedAt, isNull);
    });

    test('reports planned and completed minutes per skill', () async {
      final db = inMemoryDatabase();
      addTearDown(db.close);
      final plan = samplePlan();
      final weekId = await db.createStudyWeek(plan: plan, startDate: monday);

      final planned = await db.weeklyMinutesBySkill(weekId);
      expect(planned['speaking'], plan.minutesFor(SkillKind.speaking));
      expect(planned['listening'], plan.minutesFor(SkillKind.listening));
      expect(
        planned.values.fold<int>(0, (sum, value) => sum + value),
        plan.totalMinutes,
      );

      expect(await db.weeklyMinutesBySkill(weekId, completedOnly: true), isEmpty);
      final listening = (await db.assignmentsForWeek(
        weekId,
      )).firstWhere((row) => row.skill == 'listening');
      await db.completeAssignment(listening.id, at: monday);
      expect(await db.weeklyMinutesBySkill(weekId, completedOnly: true), {
        'listening': listening.minutes,
      });
    });
  });

  group('closing a week', () {
    test('frees the slot for the next week and keeps the report', () async {
      final db = inMemoryDatabase();
      addTearDown(db.close);
      final weekId = await db.createStudyWeek(
        plan: samplePlan(),
        startDate: monday,
      );

      await db.closeStudyWeek(
        weekId,
        reportJson: '{"levels":{"speaking":"B"}}',
        at: monday.add(const Duration(days: 6)),
      );

      expect(await db.activeStudyWeek(), isNull);
      final closed = await db.studyWeek(weekId);
      expect(closed!.status, 'closed');
      expect(closed.reportJson, contains('speaking'));
      expect(closed.closedAt, isNotNull);

      final next = await db.createStudyWeek(
        plan: samplePlan(weekNumber: 2),
        startDate: monday.add(const Duration(days: 7)),
      );
      expect((await db.activeStudyWeek())!.id, next);
      expect(await db.weeklyHistory(), hasLength(2));
    });

    test('refuses to close a week twice', () async {
      final db = inMemoryDatabase();
      addTearDown(db.close);
      final weekId = await db.createStudyWeek(
        plan: samplePlan(),
        startDate: monday,
      );
      await db.closeStudyWeek(weekId, reportJson: '{}', at: monday);

      await expectLater(
        db.closeStudyWeek(weekId, reportJson: '{}', at: monday),
        throwsStateError,
      );
    });
  });
}
