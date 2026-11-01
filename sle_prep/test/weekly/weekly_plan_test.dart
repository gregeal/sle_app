import 'package:flutter_test/flutter_test.dart';
import 'package:sle_prep/domain/weekly/weekly_plan.dart';

/// Every plan the composer can produce must honour the published time
/// contract, so these checks run over many generated weeks rather than a
/// single hand-picked timetable.
void assertContract(WeeklyPlan plan) {
  final reason = 'week ${plan.weekNumber} (${plan.minutesBySkill})';

  expect(
    plan.totalMinutes,
    plan.studyDays * plan.minutesPerDay,
    reason: 'budget must be spent exactly · $reason',
  );

  final speaking = plan.shareOf(SkillKind.speaking);
  expect(
    speaking,
    inInclusiveRange(kSpeakingMinShare, kSpeakingMaxShare),
    reason: 'speaking share · $reason',
  );
  for (final skill in SkillKind.values) {
    if (skill == SkillKind.speaking) continue;
    expect(
      plan.minutesFor(skill),
      lessThan(plan.minutesFor(SkillKind.speaking)),
      reason: 'speaking must dominate $skill · $reason',
    );
  }

  final spread = <double>[
    for (final skill in distributedSkills) plan.shareOf(skill),
  ];
  for (final share in spread) {
    expect(
      share,
      inInclusiveRange(kDistributedMinShare, kDistributedMaxShare),
      reason: 'listening/reading/writing band · $reason',
    );
  }
  spread.sort();
  expect(
    spread.last - spread.first,
    lessThanOrEqualTo(kMaxDistributedSpread + 1e-9),
    reason: 'the three other skills stay evenly distributed · $reason',
  );

  for (var day = 1; day <= plan.studyDays; day++) {
    final blocks = plan.assignmentsForDay(day);
    expect(blocks, isNotEmpty, reason: 'day $day is empty · $reason');
    expect(
      blocks.fold<int>(0, (sum, block) => sum + block.minutes),
      plan.minutesPerDay,
      reason: 'day $day must fill its budget · $reason',
    );
    expect(
      blocks.any((block) => block.skill == SkillKind.speaking),
      isTrue,
      reason: 'day $day needs a speaking block · $reason',
    );
    for (final block in blocks) {
      expect(
        block.minutes,
        greaterThanOrEqualTo(kMinimumBlockMinutes),
        reason: 'no sliver blocks · $reason',
      );
    }
  }

  expect(
    plan.assignments.map((block) => block.id).toSet(),
    hasLength(plan.assignments.length),
    reason: 'assignment ids are unique · $reason',
  );
  expect(
    plan.assignments.where((block) => block.skill == SkillKind.teaching),
    hasLength(1),
    reason: 'exactly one teaching block, on the class day · $reason',
  );
  expect(
    plan.assignments
        .firstWhere((block) => block.skill == SkillKind.teaching)
        .dayIndex,
    1,
    reason: 'the class opens the week · $reason',
  );
}

WeeklyPlan planFor({
  int weekNumber = 1,
  int studyDays = 5,
  int minutesPerDay = 60,
  WeeklyEmphasis emphasis = const WeeklyEmphasis.balanced(),
}) => composeWeeklyPlan(
  weekNumber: weekNumber,
  trackId: 'b-to-c-v1',
  lessonId: 'bc-01-precision',
  lessonTitleFr: 'Décrire avec précision',
  studyDays: studyDays,
  minutesPerDay: minutesPerDay,
  emphasis: emphasis,
);

void main() {
  group('the published time contract', () {
    test('holds for the owner default of 5 days x 60 min', () {
      assertContract(planFor());
    });

    test('holds across many weeks, budgets and emphases', () {
      for (var week = 1; week <= 16; week++) {
        for (final days in [3, 5, 6, 7]) {
          for (final minutes in [30, 45, 60, 75, 90, 120]) {
            for (final emphasis in [
              const WeeklyEmphasis.balanced(),
              const WeeklyEmphasis(reinforce: {SkillKind.writing}),
              const WeeklyEmphasis(reinforce: {SkillKind.listening}),
              const WeeklyEmphasis(
                reinforce: {SkillKind.reading, SkillKind.writing},
              ),
              const WeeklyEmphasis(speakingBoost: 0.08),
              const WeeklyEmphasis(
                reinforce: {SkillKind.listening},
                speakingBoost: -0.02,
              ),
            ]) {
              assertContract(
                planFor(
                  weekNumber: week,
                  studyDays: days,
                  minutesPerDay: minutes,
                  emphasis: emphasis,
                ),
              );
            }
          }
        }
      }
    });

    test('speaking really is the dominant share, not a token majority', () {
      final plan = planFor();
      final speaking = plan.minutesFor(SkillKind.speaking);
      for (final skill in distributedSkills) {
        expect(speaking, greaterThan(2 * plan.minutesFor(skill)));
      }
      expect(plan.minutesFor(SkillKind.speaking), 125);
    });
  });

  group('adaptation', () {
    test('reinforcing a skill moves minutes to it without breaking the band', () {
      final balanced = planFor();
      final focused = planFor(
        emphasis: const WeeklyEmphasis(reinforce: {SkillKind.writing}),
      );

      expect(
        focused.minutesFor(SkillKind.writing),
        greaterThan(balanced.minutesFor(SkillKind.writing)),
      );
      expect(
        focused.minutesFor(SkillKind.reading),
        lessThanOrEqualTo(balanced.minutesFor(SkillKind.reading)),
      );
      assertContract(focused);
    });

    test('a speaking boost cannot push past the ceiling', () {
      final plan = planFor(
        emphasis: const WeeklyEmphasis(speakingBoost: 0.40),
      );
      expect(plan.shareOf(SkillKind.speaking), lessThanOrEqualTo(kSpeakingMaxShare));
      assertContract(plan);
    });

    test('reinforcing every distributed skill stays balanced', () {
      final plan = planFor(emphasis: const WeeklyEmphasis(reinforce: {...distributedSkills}));
      assertContract(plan);
      final shares = {
        for (final skill in distributedSkills) plan.minutesFor(skill),
      };
      expect(shares, hasLength(lessThanOrEqualTo(2)));
    });
  });

  group('shape of the week', () {
    test('the class day opens with teaching then live speaking practice', () {
      final day1 = planFor().assignmentsForDay(1);
      expect(day1.first.skill, SkillKind.teaching);
      expect(day1[1].skill, SkillKind.speaking);
      expect(day1[1].payload['mode'], 'liveClassPractice');
    });

    test('later days carry ordinary speaking practice bound to the lesson', () {
      final plan = planFor();
      final later = plan.assignments.where(
        (block) => block.dayIndex > 1 && block.skill == SkillKind.speaking,
      );
      expect(later, isNotEmpty);
      for (final block in later) {
        expect(block.payload['mode'], isNot('liveClassPractice'));
        expect(block.payload['lessonId'], 'bc-01-precision');
      }
    });

    test('is deterministic for identical inputs', () {
      expect(planFor(weekNumber: 4).toJson(), planFor(weekNumber: 4).toJson());
      expect(
        planFor(weekNumber: 4).toJson(),
        isNot(planFor(weekNumber: 5).toJson()),
        reason: 'the week number varies which skill follows the class',
      );
    });

    test('survives a JSON round trip', () {
      final plan = planFor(weekNumber: 7, emphasis: const WeeklyEmphasis(reinforce: {SkillKind.reading}));
      final restored = WeeklyPlan.fromJson(plan.toJson());
      expect(restored.toJson(), plan.toJson());
      expect(restored.assignments.length, plan.assignments.length);
      assertContract(restored);
    });
  });

  group('validation', () {
    test('rejects budgets that cannot honour the contract', () {
      expect(() => planFor(studyDays: 1), throwsArgumentError);
      expect(() => planFor(studyDays: 9), throwsArgumentError);
      expect(() => planFor(minutesPerDay: 15), throwsArgumentError);
      expect(() => planFor(minutesPerDay: 200), throwsArgumentError);
      expect(() => planFor(weekNumber: 0), throwsArgumentError);
    });

    test('rejects an emphasis that targets speaking or teaching', () {
      expect(
        () => planFor(emphasis: const WeeklyEmphasis(reinforce: {SkillKind.speaking})),
        throwsArgumentError,
      );
      expect(
        () => planFor(emphasis: const WeeklyEmphasis(reinforce: {SkillKind.teaching})),
        throwsArgumentError,
      );
      expect(
        () => planFor(emphasis: const WeeklyEmphasis(speakingBoost: double.nan)),
        throwsArgumentError,
      );
    });

    test('rejects malformed stored plans instead of guessing', () {
      final good = planFor().toJson();
      expect(() => WeeklyPlan.fromJson({...good, 'version': 99}), throwsFormatException);
      expect(() => WeeklyPlan.fromJson({...good, 'assignments': 'nope'}), throwsFormatException);
      expect(() => WeeklyPlan.fromJson({...good, 'studyDays': 0}), throwsFormatException);
    });
  });
}
