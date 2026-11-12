import 'package:flutter_test/flutter_test.dart';
import 'package:sle_prep/domain/habit/activity_meter.dart';
import 'package:sle_prep/domain/habit/habit_settings.dart';
import 'package:sle_prep/domain/habit/journey.dart';
import 'package:sle_prep/domain/habit/reminder_plan.dart';
import 'package:sle_prep/domain/habit/slot_analysis.dart';
import 'package:sle_prep/domain/habit/streak.dart';
import 'package:sle_prep/domain/weekly/weekly_report.dart';

// November 2026: the 2nd is a Monday.
DateTime nov(int day, [int hour = 0, int minute = 0]) =>
    DateTime(2026, 11, day, hour, minute);

Set<String> days(List<int> values) => {
  for (final day in values) studyDateKey(nov(day)),
};

bool weekend(DateTime day) => day.weekday >= 6;

void main() {
  group('computeStreak', () {
    test('a weekend of rest does not break the chain', () {
      expect(
        computeStreak(
          today: nov(9),
          activeDays: days([5, 6, 9]),
          isRestDay: weekend,
        ),
        3,
        reason: 'Thursday, Friday, then Monday across two rest days',
      );
    });

    test('today still open counts back from yesterday, through rest days', () {
      expect(
        computeStreak(today: nov(9), activeDays: days([6]), isRestDay: weekend),
        1,
      );
    });

    test('a missed study day does break it', () {
      expect(
        computeStreak(
          today: nov(6),
          activeDays: days([4, 6]),
          isRestDay: weekend,
        ),
        1,
      );
    });

    test('studying on a rest day adds to the count', () {
      expect(
        computeStreak(
          today: nov(9),
          activeDays: days([6, 7, 9]),
          isRestDay: weekend,
        ),
        3,
      );
    });

    test('without rest days every calendar day counts, as before', () {
      expect(
        computeStreak(
          today: nov(9),
          activeDays: days([6, 9]),
          isRestDay: (_) => false,
        ),
        1,
      );
    });

    test('terminates when every day is a rest day', () {
      expect(
        computeStreak(
          today: nov(9),
          activeDays: const {},
          isRestDay: (_) => true,
        ),
        0,
      );
    });
  });

  group('ActivityMeter', () {
    late DateTime clock;
    ActivityMeter meter() => ActivityMeter(now: () => clock);
    void advance(Duration by) => clock = clock.add(by);

    setUp(() => clock = nov(3, 7, 15));

    test('counts time between interactions', () {
      final m = meter()..resume();
      advance(const Duration(minutes: 2));
      m.touch();
      advance(const Duration(minutes: 1));
      expect(m.seconds, 180);
    });

    test('a screen left open is capped at the idle limit', () {
      final m = meter()..resume();
      advance(const Duration(hours: 2));
      expect(m.seconds, 300, reason: 'two idle hours are not two study hours');
      m.touch();
      advance(const Duration(seconds: 30));
      expect(m.seconds, 330);
    });

    test('time while paused is not counted', () {
      final m = meter()..resume();
      advance(const Duration(seconds: 40));
      m.pause();
      advance(const Duration(minutes: 30));
      expect(m.seconds, 40);
      m.resume();
      advance(const Duration(seconds: 20));
      expect(m.seconds, 60);
    });

    test('never exceeds the per-activity maximum', () {
      final m = meter()..resume();
      for (var i = 0; i < 60; i++) {
        advance(const Duration(minutes: 4));
        m.touch();
      }
      expect(m.seconds, 90 * 60);
    });

    test('remembers when it started and ignores a clock moved backwards', () {
      final m = meter()..resume();
      expect(m.startedAt, nov(3, 7, 15));
      clock = nov(3, 6);
      expect(m.seconds, 0);
    });
  });

  group('planReminders', () {
    const settings = HabitSettings(
      configured: true,
      remindersEnabled: true,
      reminderMinutes: 7 * 60 + 15,
      studyDays: [1, 3, 5, 6],
      classDays: [2, 4],
    );
    ReminderSpec find(
      List<ReminderSpec> specs,
      int weekday,
      ReminderKind kind,
    ) => specs.singleWhere((s) => s.weekday == weekday && s.kind == kind);

    test('one reminder and one nudge per active day, none on the rest day', () {
      final specs = planReminders(
        now: nov(2, 6),
        settings: settings,
        doneToday: false,
      );
      expect(specs, hasLength(12));
      expect(specs.where((s) => s.weekday == 7), isEmpty);
      expect(specs.map((s) => s.id).toSet(), hasLength(12));
      expect(allReminderIds, containsAll(specs.map((s) => s.id)));
      expect(find(specs, 1, ReminderKind.primary).firstFire, nov(2, 7, 15));
      expect(find(specs, 1, ReminderKind.nudge).firstFire, nov(2, 10, 15));
      expect(find(specs, 2, ReminderKind.primary).classDay, isTrue);
      expect(find(specs, 3, ReminderKind.primary).classDay, isFalse);
    });

    test('a time already passed today moves to next week', () {
      final specs = planReminders(
        now: nov(2, 8),
        settings: settings,
        doneToday: false,
      );
      expect(find(specs, 1, ReminderKind.primary).firstFire, nov(9, 7, 15));
      expect(
        find(specs, 1, ReminderKind.nudge).firstFire,
        nov(2, 10, 15),
        reason: 'the nudge is still ahead',
      );
    });

    test('once today is done, nothing more fires today', () {
      final specs = planReminders(
        now: nov(2, 6),
        settings: settings,
        doneToday: true,
      );
      expect(find(specs, 1, ReminderKind.primary).firstFire, nov(9, 7, 15));
      expect(find(specs, 1, ReminderKind.nudge).firstFire, nov(9, 10, 15));
      expect(
        find(specs, 2, ReminderKind.primary).firstFire,
        nov(3, 7, 15),
        reason: 'tomorrow is unaffected',
      );
    });

    test('evenings stay free: no nudge after 21 h', () {
      final late = settings.copyWith(reminderMinutes: 19 * 60);
      final specs = planReminders(
        now: nov(2, 6),
        settings: late,
        doneToday: false,
      );
      expect(specs.where((s) => s.kind == ReminderKind.nudge), isEmpty);
      expect(specs, hasLength(6));
      final edge = settings.copyWith(reminderMinutes: 18 * 60);
      expect(
        planReminders(
          now: nov(2, 6),
          settings: edge,
          doneToday: false,
        ).where((s) => s.kind == ReminderKind.nudge),
        hasLength(6),
        reason: '21 h exactly is still allowed',
      );
    });

    test('disabled reminders plan nothing', () {
      expect(
        planReminders(
          now: nov(2, 6),
          settings: settings.copyWith(remindersEnabled: false),
          doneToday: false,
        ),
        isEmpty,
      );
    });

    test('every first occurrence is in the future on the right weekday', () {
      for (var hour = 0; hour < 24; hour += 5) {
        for (var day = 2; day <= 8; day++) {
          final now = nov(day, hour, 59);
          for (final spec in planReminders(
            now: now,
            settings: settings,
            doneToday: false,
          )) {
            expect(spec.firstFire.isAfter(now), isTrue);
            expect(spec.firstFire.weekday, spec.weekday);
            expect(spec.firstFire.difference(now).inDays, lessThan(8));
          }
        }
      }
    });

    test('the wording never pressures and class days say so', () {
      final specs = planReminders(
        now: nov(2, 6),
        settings: settings,
        doneToday: false,
      );
      final classDay = find(specs, 2, ReminderKind.primary);
      expect(reminderTitle(classDay), contains('Jour de cours'));
      final study = find(specs, 1, ReminderKind.primary);
      expect(reminderBody(study, 20), contains('20 minutes'));
      expect(reminderBody(study, 20), contains('cinq minutes comptent'));
      expect(
        reminderBody(find(specs, 1, ReminderKind.nudge), 20),
        contains('Sans pression'),
      );
    });
  });

  group('slots', () {
    test('finds the slot where sessions actually get finished', () {
      final stats = analyzeSlots([
        // Three mornings, all finished.
        StudyStretch(nov(2, 7, 10), 900),
        StudyStretch(nov(3, 7, 20), 950),
        StudyStretch(nov(4, 7, 30), 1000),
        // Three evenings, one finished.
        StudyStretch(nov(5, 20, 30), 120),
        StudyStretch(nov(6, 21, 0), 200),
        StudyStretch(nov(7, 20, 0), 600),
        StudyStretch(nov(7, 20, 30), 400),
      ], targetSeconds: 900);
      final morning = stats.singleWhere((s) => s.slot == DaySlot.earlyMorning);
      final evening = stats.singleWhere((s) => s.slot == DaySlot.evening);
      expect((morning.days, morning.keptDays), (3, 3));
      expect(
        (evening.days, evening.keptDays),
        (3, 1),
        reason: 'two stretches on the 7th add up to one finished day',
      );
      expect(morning.medianStartMinutes, 7 * 60 + 20);
      expect(bestSlot(stats)!.slot, DaySlot.earlyMorning);
    });

    test('says nothing until there is enough evidence', () {
      final stats = analyzeSlots([
        StudyStretch(nov(2, 7), 900),
        StudyStretch(nov(3, 7), 900),
      ], targetSeconds: 900);
      expect(bestSlot(stats), isNull);
      expect(bestSlot(const []), isNull);
    });

    test('a session after midnight belongs to the late slot', () {
      expect(DaySlot.of(nov(3, 0, 30)), DaySlot.night);
      expect(DaySlot.of(nov(3, 4, 59)), DaySlot.night);
      expect(DaySlot.of(nov(3, 5)), DaySlot.earlyMorning);
      expect(DaySlot.of(nov(3, 12, 15)), DaySlot.midday);
    });

    test('suggestions sit around the working day, never late evening', () {
      final office = suggestSlots(
        workStartMinutes: 8 * 60 + 30,
        workEndMinutes: 16 * 60 + 30,
      );
      expect(office.map((s) => s.minutes), [
        7 * 60 + 45,
        12 * 60 + 15,
        17 * 60,
      ]);
      final lateShift = suggestSlots(
        workStartMinutes: 14 * 60,
        workEndMinutes: 22 * 60,
      );
      expect(
        lateShift.map((s) => s.label),
        ['Avant le travail'],
        reason: 'no lunch inside the shift and nothing after 20 h 30',
      );
    });
  });

  group('HabitSettings', () {
    const usable = HabitSettings(studyDays: [1, 3, 5, 6], classDays: [2, 4]);

    test('the owner rhythm is valid', () {
      expect(usable.problem, isNull);
      expect(usable.isClassDay(nov(3)), isTrue);
      expect(usable.isStudyDay(nov(2)), isTrue);
      expect(usable.isRestDay(nov(8)), isTrue);
    });

    test('a full rest day is mandatory', () {
      expect(
        usable.copyWith(studyDays: [1, 3, 5, 6, 7]).problem,
        contains('repos'),
      );
    });

    test('a day cannot be both study and class', () {
      expect(usable.copyWith(classDays: [1, 2]).problem, isNotNull);
    });

    test('needs enough days and a supported length', () {
      expect(usable.copyWith(studyDays: [1, 3]).problem, contains('trois'));
      expect(usable.copyWith(dailyMinutes: 25).problem, isNotNull);
      expect(usable.copyWith(reminderMinutes: 24 * 60).problem, isNotNull);
    });

    test('refuses a week too small to cover the four skills', () {
      final tiny = usable.copyWith(studyDays: [1, 3, 5], classDays: []);
      expect(tiny.problem, contains('quatre compétences'));
      expect(tiny.copyWith(dailyMinutes: 40).problem, isNull);
      expect(weeklyBudgetIsFeasible(4, 20), isTrue);
      expect(weeklyBudgetIsFeasible(3, 20), isFalse);
    });

    test('formats a clock time the French way', () {
      expect(formatClock(7 * 60 + 5), '07 h 05');
      expect(formatClock(12 * 60 + 15), '12 h 15');
    });
  });

  group('journey', () {
    test('no level goal is shown until the habit has held for four weeks', () {
      for (var kept = 0; kept < kHabitStageWeeks; kept++) {
        final stage = journeyFor(keptWeeks: kept);
        expect(stage.number, 1);
        expect(
          stage.detail.toLowerCase(),
          anyOf(
            contains('aucun objectif de niveau'),
            contains('sans objectif de niveau'),
          ),
        );
      }
      final next = journeyFor(keptWeeks: kHabitStageWeeks);
      expect(next.number, 2);
      expect(next.title, contains('B solide'));
      expect(next.detail, contains('sans date limite'));
    });

    test('one missed day never fails a week', () {
      expect(keptDaysNeeded(6), 4);
      expect(keptDaysNeeded(5), 4);
      expect(keptDaysNeeded(3), 3);
    });
  });
}
