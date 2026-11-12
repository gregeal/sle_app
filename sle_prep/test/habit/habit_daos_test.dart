import 'package:flutter_test/flutter_test.dart';
import 'package:sle_prep/data/db/daos.dart';
import 'package:sle_prep/data/db/database.dart';
import 'package:sle_prep/data/db/habit_daos.dart';
import 'package:sle_prep/data/db/weekly_daos.dart';
import 'package:sle_prep/domain/habit/habit_settings.dart';
import 'package:sle_prep/domain/weekly/weekly_plan.dart';

import '../support/test_db.dart';

// November 2026: the 2nd is a Monday.
DateTime nov(int day, [int hour = 12]) => DateTime(2026, 11, day, hour);

WeeklyPlan plan({int weekNumber = 1}) => composeWeeklyPlan(
  weekNumber: weekNumber,
  trackId: 'b-to-c-v1',
  lessonId: '01-detail',
  lessonTitleFr: 'Décrire',
);

void main() {
  late AppDatabase db;

  setUp(() => db = inMemoryDatabase());
  tearDown(() => db.close());

  Future<void> study(DateTime at, {int minutes = 6, String? skill}) =>
      db.logActivity(
        startedAt: at,
        seconds: minutes * 60,
        kind: 'vocab',
        skill: skill,
      );

  group('real study time', () {
    test('only observed time is credited, however much was planned', () async {
      final id = await db.createStudyWeek(plan: plan(), startDate: nov(2));
      expect(
        (await db.assignmentsForWeek(id)).fold<int>(0, (n, a) => n + a.minutes),
        300,
      );
      expect(await db.totalActiveMinutes(), 0);
      await study(nov(2), minutes: 7, skill: 'vocabulary');
      await study(nov(2, 18), minutes: 12, skill: 'speaking');
      expect(await db.totalActiveMinutes(), 19);
      expect(await db.secondsOn(nov(2)), 19 * 60);
      expect(await db.secondsOn(nov(3)), 0);
    });

    test('a few seconds of navigation is not study', () async {
      await db.logActivity(startedAt: nov(2), seconds: 19, kind: 'vocab');
      expect(await db.activitySince(nov(1)), isEmpty);
      await db.logActivity(startedAt: nov(2), seconds: 20, kind: 'vocab');
      expect(await db.activitySince(nov(1)), hasLength(1));
    });

    test('one activity can never claim more than 90 minutes', () async {
      await db.logActivity(startedAt: nov(2), seconds: 9 * 3600, kind: 'vocab');
      expect((await db.activitySince(nov(1))).single.seconds, 90 * 60);
    });

    test(
      'old session logs keep their minutes; new ones stop counting plans',
      () async {
        // Before the activity log existed nothing better was recorded.
        await db.upsertSessionLog(
          day: DateTime(2026, 7, 12),
          blocksPlanned: const ['vocabReview'],
          blocksCompleted: const ['vocabReview'],
          minutesActive: 35,
        );
        // From then on a ticked block is a plan, not a measurement.
        await db.upsertSessionLog(
          day: DateTime(2099, 1, 1),
          blocksPlanned: const ['vocabReview'],
          blocksCompleted: const ['vocabReview'],
          minutesActive: 75,
        );
        expect(await db.totalActiveMinutes(), 35);
        expect(await db.getSetting('habit:logSince'), isNotNull);
      },
    );

    test('time is reported per skill inside a window', () async {
      await study(nov(2), minutes: 10, skill: 'speaking');
      await study(nov(3), minutes: 5, skill: 'speaking');
      await study(nov(3), minutes: 4, skill: 'reading');
      await study(nov(4), minutes: 6);
      await study(nov(9), minutes: 30, skill: 'speaking');
      expect(await db.secondsBySkill(nov(2, 0), nov(9, 0)), {
        'speaking': 15 * 60,
        'reading': 4 * 60,
        'other': 6 * 60,
      });
    });
  });

  group('streak', () {
    test('five minutes make a day; four do not', () async {
      await study(nov(3), minutes: 4);
      expect(await db.currentStreak(nov(3)), 0);
      await study(nov(3, 18), minutes: 1);
      expect(await db.currentStreak(nov(3)), 1);
    });

    test('a weekend off inside a weekly rhythm keeps the streak', () async {
      await db.createStudyWeek(plan: plan(), startDate: nov(2));
      await study(nov(5));
      await study(nov(6));
      expect(
        await db.currentStreak(nov(9)),
        2,
        reason: 'Monday morning, before studying: Thursday and Friday stand',
      );
      await study(nov(9));
      expect(await db.currentStreak(nov(9)), 3);
    });

    test('a missed study day inside the plan still breaks it', () async {
      await db.createStudyWeek(plan: plan(), startDate: nov(2));
      await study(nov(2));
      await study(nov(4));
      expect(await db.currentStreak(nov(4)), 1);
    });

    test('the plan dates decide inside a week, not the weekday', () async {
      // A paused-and-resumed week can land a session on a Saturday.
      await db.createStudyWeek(
        plan: plan(),
        startDate: nov(2),
        weekdays: const [1, 2, 3, 4, 6],
      );
      await study(nov(5));
      await study(nov(7));
      expect(
        await db.currentStreak(nov(7)),
        2,
        reason: 'Friday is not in this plan, so it is a rest day',
      );
    });

    test('a group-class day is a scheduled day, Sunday is rest', () async {
      await db.saveHabitSettings(
        const HabitSettings(studyDays: [1, 3, 5, 6], classDays: [2, 4]),
      );
      await study(nov(2));
      await study(nov(4));
      expect(
        await db.currentStreak(nov(4)),
        1,
        reason: 'nothing was done on the Tuesday class day',
      );
      await study(nov(7));
      await study(nov(9));
      expect(await db.currentStreak(nov(9)), 2);
    });

    test('with no rhythm at all every day counts, as it always did', () async {
      await study(nov(6));
      await study(nov(9));
      expect(await db.currentStreak(nov(9)), 1);
    });
  });

  group('rhythm', () {
    test('defaults before anything is chosen', () async {
      final settings = await db.habitSettings();
      expect(settings.configured, isFalse);
      expect(settings.remindersEnabled, isFalse);
      expect(settings.studyDays, [1, 2, 3, 4, 5]);
      expect(settings.classDays, isEmpty);
      expect(settings.dailyMinutes, 20);
    });

    test('round-trips and shares the study days with the planner', () async {
      const chosen = HabitSettings(
        remindersEnabled: true,
        reminderMinutes: 7 * 60 + 15,
        studyDays: [6, 1, 5, 3],
        classDays: [4, 2],
        dailyMinutes: 40,
        workStartMinutes: 510,
        workEndMinutes: 990,
      );
      await db.saveHabitSettings(chosen);
      final saved = await db.habitSettings();
      expect(saved.configured, isTrue);
      expect(saved.remindersEnabled, isTrue);
      expect(saved.reminderMinutes, 435);
      expect(saved.studyDays, [1, 3, 5, 6]);
      expect(saved.classDays, [2, 4]);
      expect(saved.dailyMinutes, 40);
      expect((saved.workStartMinutes, saved.workEndMinutes), (510, 990));
      expect(await db.studyWeekdays(), [1, 3, 5, 6]);
    });

    test('an unusable rhythm is refused, not stored', () async {
      await expectLater(
        db.saveHabitSettings(
          const HabitSettings(studyDays: [1, 2, 3, 4, 5, 6, 7]),
        ),
        throwsArgumentError,
      );
      expect((await db.habitSettings()).configured, isFalse);
    });

    test('a week is kept when most planned days were kept', () async {
      const settings = HabitSettings(
        studyDays: [1, 3, 5, 6],
        classDays: [2, 4],
      );
      // Week of the 2nd: four days.
      for (final day in [2, 3, 5, 7]) {
        await study(nov(day));
      }
      // Week of the 9th: two days.
      await study(nov(9));
      await study(nov(11));
      // Week of the 23rd is still running.
      for (final day in [23, 24, 25, 26]) {
        await study(nov(day));
      }
      expect(await db.keptWeeks(nov(26), settings), 1);
      expect(await db.activeDaysInWeekOf(nov(26)), 4);
      expect(await db.keptWeeks(nov(30), settings), 2);
    });

    test('completion is measured by time of day', () async {
      const settings = HabitSettings(dailyMinutes: 20);
      for (final day in [23, 24, 25]) {
        await study(nov(day, 7), minutes: 16);
      }
      await study(nov(26, 20), minutes: 3);
      final stats = await db.slotStats(nov(27), settings);
      expect(stats.map((s) => (s.slot.name, s.days, s.keptDays)), [
        ('earlyMorning', 3, 3),
        ('evening', 1, 0),
      ]);
    });
  });

  group('group class notes', () {
    test('one note per day, replaced when saved again', () async {
      await db.saveGroupClassNote(
        day: nov(3),
        covered: 'Le passé composé avec être',
        corrections: '',
        at: nov(3, 19),
      );
      await db.saveGroupClassNote(
        day: nov(3),
        covered: '  Le passé composé avec être et avoir  ',
        corrections: 'je suis allé, pas j’ai allé',
        at: nov(3, 20),
      );
      final note = (await db.groupClassNoteFor(nov(3)))!;
      expect(note.covered, 'Le passé composé avec être et avoir');
      expect(note.corrections, contains('je suis allé'));
      expect(await db.recentGroupClassNotes(), hasLength(1));
      expect(await db.groupClassNoteFor(nov(5)), isNull);
    });

    test('an empty note is refused', () async {
      await expectLater(
        db.saveGroupClassNote(
          day: nov(3),
          covered: ' ',
          corrections: '',
          at: nov(3),
        ),
        throwsArgumentError,
      );
      expect(await db.groupClassNoteFor(nov(3)), isNull);
    });
  });

  group('live voice allowance', () {
    test('a session that died costs only what it had used', () async {
      final week = await db.createStudyWeek(plan: plan(), startDate: nov(2));
      final start = nov(2, 9);
      final lease = await db.reserveWeeklyVoice(week, now: start);
      expect(await db.voiceLeaseSeconds(lease), 1200);
      await db.heartbeatWeeklyVoice(
        lease,
        130,
        now: start.add(const Duration(seconds: 135)),
      );

      // While heartbeats keep arriving the session is alive: no second one.
      await expectLater(
        db.reserveWeeklyVoice(
          week,
          now: start.add(const Duration(seconds: 150)),
        ),
        throwsStateError,
      );

      // The app is killed. A minute of silence later the lease is settled at
      // its last checkpoint and the rest of the week's allowance is back.
      final next = await db.reserveWeeklyVoice(
        week,
        now: start.add(const Duration(seconds: 135 + 61)),
      );
      expect(await db.voiceLeaseSeconds(next), 1200 - 130);

      // A late settle from the dead session cannot rewrite history.
      await db.settleWeeklyVoice(lease, 999);
      await db.settleWeeklyVoice(next, 70);
      final third = await db.reserveWeeklyVoice(
        week,
        now: start.add(const Duration(minutes: 30)),
      );
      expect(await db.voiceLeaseSeconds(third), 1200 - 130 - 70);
    });

    test('a session killed before its first heartbeat costs nothing', () async {
      final week = await db.createStudyWeek(plan: plan(), startDate: nov(2));
      final start = nov(2, 9);
      await db.reserveWeeklyVoice(week, now: start);
      final again = await db.reserveWeeklyVoice(
        week,
        now: start.add(const Duration(minutes: 2)),
      );
      expect(await db.voiceLeaseSeconds(again), 1200);
    });

    test('a heartbeat never revives a settled lease', () async {
      final week = await db.createStudyWeek(plan: plan(), startDate: nov(2));
      final lease = await db.reserveWeeklyVoice(week, now: nov(2, 9));
      await db.settleWeeklyVoice(lease, 300);
      await db.heartbeatWeeklyVoice(lease, 900, now: nov(2, 10));
      final next = await db.reserveWeeklyVoice(week, now: nov(2, 11));
      expect(await db.voiceLeaseSeconds(next), 900);
    });
  });

  group('catch-up', () {
    test(
      'a block missed two days ago can still be brought into today',
      () async {
        final week = await db.createStudyWeek(plan: plan(), startDate: nov(2));
        final rows = await db.assignmentsForWeek(week);
        WeeklyAssignment? missed;
        WeeklyAssignment? todays;
        for (final old in rows.where(
          (a) => a.dayIndex == 1 && a.skill != 'teaching',
        )) {
          for (final candidate in rows.where((a) => a.dayIndex == 3)) {
            if (candidate.skill == old.skill &&
                candidate.minutes == old.minutes) {
              missed = old;
              todays = candidate;
            }
          }
        }
        expect(
          missed,
          isNotNull,
          reason: 'the default week has a same-skill, same-length pair',
        );
        await db.swapCatchup(week, missed!.id, todays!.id, '2026-11-04');
        expect((await db.weeklyAssignment(missed.id)).dayIndex, 3);
        expect((await db.weeklyAssignment(todays.id)).dayIndex, 1);
        await expectLater(
          db.swapCatchup(week, todays.id, missed.id, '2026-11-04'),
          throwsStateError,
          reason: 'one catch-up a day',
        );
      },
    );

    test('a later block cannot be pulled backwards', () async {
      final week = await db.createStudyWeek(plan: plan(), startDate: nov(2));
      final rows = await db.assignmentsForWeek(week);
      final later = rows.firstWhere(
        (a) => a.dayIndex == 4 && a.skill == 'speaking',
      );
      final today = rows.firstWhere(
        (a) => a.dayIndex == 3 && a.skill == 'speaking',
      );
      await expectLater(
        db.swapCatchup(week, later.id, today.id, '2026-11-04'),
        throwsArgumentError,
      );
    });
  });
}
