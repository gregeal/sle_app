import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:sle_prep/data/db/weekly_daos.dart';
import 'package:sle_prep/data/db/daos.dart';
import 'package:sle_prep/domain/weekly/weekly_plan.dart';
import 'package:sle_prep/domain/weekly/weekly_report.dart';
import 'package:sle_prep/domain/course/course_catalog.dart';
import '../support/test_db.dart';

WeeklyPlan samplePlan({int weekNumber = 1}) => composeWeeklyPlan(
  weekNumber: weekNumber,
  trackId: 'b-to-c-v1',
  lessonId: '01-detail',
  lessonTitleFr: 'Décrire',
);
void main() {
  final monday = DateTime(2026, 11, 2);
  test(
    'distinct speaking productions are retained without duplicate minute credit',
    () async {
      final db = inMemoryDatabase();
      addTearDown(db.close);
      final id = await db.createStudyWeek(
        plan: samplePlan(),
        startDate: monday,
      );
      final a = (await db.assignmentsForWeek(
        id,
      )).firstWhere((a) => a.skill == 'speaking');
      for (final text in [
        'Je prépare les réunions.',
        'Je prépare aussi les comptes rendus.',
      ]) {
        await db.saveAssignmentEvidence(
          a.id,
          AssignmentEvidence(
            kind: EvidenceKind.spokenPractice,
            data: {
              'exchanges': [
                {'question': 'Votre travail ?', 'answer': text},
              ],
            },
          ),
          at: monday,
        );
      }
      expect((await db.weeklySnapshot(id))['evidence'], hasLength(2));
      expect(await db.weeklyMinutesBySkill(id, completedOnly: true), {
        'speaking': a.minutes,
      });
      final foreignKeys = await db
          .customSelect('PRAGMA foreign_key_list(weekly_evidence)')
          .get();
      expect(foreignKeys, isNotEmpty);
    },
  );
  test(
    'stores the plan and exact dates and prevents a second active week',
    () async {
      final db = inMemoryDatabase();
      addTearDown(db.close);
      final id = await db.createStudyWeek(
        plan: samplePlan(),
        startDate: monday,
      );
      final week = (await db.activeStudyWeek())!;
      expect(week.id, id);
      expect(week.plan.toJson(), samplePlan().toJson());
      expect(await db.studyDates(week), [
        '2026-11-02',
        '2026-11-03',
        '2026-11-04',
        '2026-11-05',
        '2026-11-06',
      ]);
      expect(
        await db.assignmentsForWeek(id),
        hasLength(samplePlan().assignments.length),
      );
      await expectLater(
        db.createStudyWeek(plan: samplePlan(), startDate: monday),
        throwsStateError,
      );
    },
  );
  test('rejects mismatched nonexistent and missing evidence', () async {
    final db = inMemoryDatabase();
    addTearDown(db.close);
    final id = await db.createStudyWeek(plan: samplePlan(), startDate: monday);
    final a = (await db.assignmentsForWeek(
      id,
    )).firstWhere((a) => a.skill == 'speaking');
    await expectLater(
      db.completeAssignment(a.id, at: monday),
      throwsArgumentError,
    );
    await expectLater(
      db.completeAssignment(
        a.id,
        evidenceKind: 'readingAttempt',
        evidenceId: 999,
        at: monday,
      ),
      throwsArgumentError,
    );
    await expectLater(
      db.completeAssignment(
        a.id,
        evidenceKind: 'oralAttempt',
        evidenceId: 999,
        at: monday,
      ),
      throwsArgumentError,
    );
    expect((await db.weeklyAssignment(a.id)).completed, isFalse);
  });
  test(
    'quiz evidence persists the real score; repeated completion is idempotent',
    () async {
      final db = inMemoryDatabase();
      addTearDown(db.close);
      final id = await db.createStudyWeek(
        plan: samplePlan(),
        startDate: monday,
      );
      final a = (await db.assignmentsForWeek(id)).first;
      final data = AssignmentEvidence(
        kind: EvidenceKind.quiz,
        data: {
          'answers': findCourseLesson(
            '01-detail',
          ).questions.map((q) => q.correct).toList(),
        },
      );
      final evidence = await db.saveAssignmentEvidence(a.id, data, at: monday);
      expect(
        await db.saveAssignmentEvidence(
          a.id,
          data,
          at: monday.add(const Duration(hours: 1)),
        ),
        evidence,
      );
      expect((await db.weeklyAssignment(a.id)).completedAt, monday);
      final snapshot = await db.weeklySnapshot(id);
      expect((snapshot['evidence'] as List).single['data']['correct'], 2);
      expect(await db.weeklyMinutesBySkill(id, completedOnly: true), {
        'teaching': a.minutes,
      });
      expect(await db.totalActiveMinutes(), a.minutes);
      expect(await db.currentStreak(monday), 1);
    },
  );
  test(
    'closing offline freezes evidence and rejects later edits or malformed reports',
    () async {
      final db = inMemoryDatabase();
      addTearDown(db.close);
      final id = await db.createStudyWeek(
        plan: samplePlan(),
        startDate: monday,
      );
      await expectLater(
        db.closeStudyWeek(id, reportJson: '{}', at: monday),
        throwsFormatException,
      );
      await db.closeStudyWeek(id, at: monday.add(const Duration(days: 5)));
      final job = (await db.weeklyFeedback(id))!;
      expect(job.status, 'notRequested');
      expect(jsonDecode(job.snapshotJson)['evidence'], isEmpty);
      final a = (await db.assignmentsForWeek(id)).first;
      await expectLater(
        db.saveAssignmentEvidence(
          a.id,
          const AssignmentEvidence(
            kind: EvidenceKind.solo,
            selfReported: true,
            data: {'reflection': 'Une pratique réelle.'},
          ),
          at: monday,
        ),
        throwsStateError,
      );
      await expectLater(db.closeStudyWeek(id, at: monday), throwsStateError);
      await db.createStudyWeek(
        plan: samplePlan(weekNumber: 2),
        startDate: monday.add(const Duration(days: 7)),
      );
      expect(await db.weeklyHistory(), hasLength(2));
    },
  );
  test(
    'class progress survives reload and cannot be changed after closure',
    () async {
      final db = inMemoryDatabase();
      addTearDown(db.close);
      final id = await db.createStudyWeek(
        plan: samplePlan(),
        startDate: monday,
      );
      const state = ClassProgress(
        stage: 2,
        answers: [0, 1],
        checked: true,
        skips: [0],
      );
      await db.saveClassProgress(id, state);
      expect((await db.classProgress(id)).toJson(), state.toJson());
      await db.closeStudyWeek(id, at: monday);
      await expectLater(db.saveClassProgress(id, state), throwsStateError);
    },
  );
  test(
    'voice reservation survives concurrent starts and settles once',
    () async {
      final db = inMemoryDatabase();
      addTearDown(db.close);
      final id = await db.createStudyWeek(
        plan: samplePlan(),
        startDate: monday,
      );
      final lease = await db.reserveWeeklyVoice(id);
      expect(await db.voiceLeaseSeconds(lease), 1200);
      await expectLater(db.reserveWeeklyVoice(id), throwsStateError);
      await db.settleWeeklyVoice(lease, 100);
      await db.settleWeeklyVoice(lease, 0);
      final second = await db.reserveWeeklyVoice(id);
      expect(await db.voiceLeaseSeconds(second), 1100);
    },
  );
  test(
    'pause reschedules only remaining dates; overdue week closes without network',
    () async {
      final db = inMemoryDatabase();
      addTearDown(db.close);
      final id = await db.createStudyWeek(
        plan: samplePlan(),
        startDate: monday,
      );
      await db.pauseStudyWeek(id, true, DateTime(2026, 11, 4));
      await db.reconcileStudyCalendar(DateTime(2026, 11, 20));
      expect(await db.activeStudyWeek(), isNotNull);
      await db.pauseStudyWeek(id, false, DateTime(2026, 11, 9));
      final dates = await db.studyDates((await db.studyWeek(id))!);
      expect(dates, [
        '2026-11-02',
        '2026-11-03',
        '2026-11-09',
        '2026-11-10',
        '2026-11-11',
      ]);
      await db.reconcileStudyCalendar(DateTime(2026, 11, 12));
      expect(await db.activeStudyWeek(), isNull);
    },
  );
}
