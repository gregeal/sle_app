import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sle_prep/data/db/database.dart';
import 'package:sle_prep/data/db/weekly_daos.dart';
import 'package:sle_prep/domain/course/course_catalog.dart';
import 'package:sle_prep/domain/speech/speech_services.dart';
import 'package:sle_prep/domain/weekly/weekly_plan.dart';
import 'package:sle_prep/features/weekly/weekly_class_screen.dart';
import 'package:sle_prep/providers.dart';

import '../support/test_db.dart';

class _FakeTts implements TtsService {
  final spoken = <String>[];
  var stopped = 0;

  @override
  Future<void> speak(String textFr) async => spoken.add(textFr);

  @override
  Future<void> stop() async => stopped++;
}

Future<(AppDatabase, StudyWeek, CourseLesson)> _seedWeek() async {
  final db = inMemoryDatabase();
  final lesson = bToCCourse.lessons.first;
  final id = await db.createStudyWeek(
    plan: composeWeeklyPlan(
      weekNumber: 1,
      trackId: bToCCourse.id,
      lessonId: lesson.id,
      lessonTitleFr: lesson.title,
    ),
    startDate: DateTime(2026, 11, 2),
  );
  return (db, (await db.studyWeek(id))!, lesson);
}

/// Moves through the class the way a learner does, since Material's vertical
/// Stepper only builds the steps near the viewport.
Future<void> advance(WidgetTester tester, int steps) async {
  for (var step = 0; step < steps; step++) {
    final button = find.byKey(Key('class-continue-$step'));
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pumpAndSettle();
  }
}

void main() {
  testWidgets('the class teaches, checks, and records the teaching block', (
    tester,
  ) async {
    final (db, week, lesson) = await _seedWeek();
    addTearDown(db.close);
    final tts = _FakeTts();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          ttsServiceProvider.overrideWithValue(tts),
        ],
        child: MaterialApp(home: WeeklyClassScreen(week: week)),
      ),
    );
    await tester.pumpAndSettle();

    // Step 1 shows the lesson and can read it aloud, offline.
    expect(find.text(lesson.title), findsWidgets);
    expect(find.textContaining('Objectif : '), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('class-listen')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('class-listen')));
    await tester.pumpAndSettle();
    expect(tts.spoken, hasLength(1));
    expect(tts.spoken.single, contains(lesson.objective));

    // Step 2: answering every question correctly completes the teaching block.
    await advance(tester, 1);
    expect(find.byKey(const Key('class-check')), findsOneWidget);

    for (var i = 0; i < lesson.questions.length; i++) {
      final option = lesson.questions[i].correct;
      await tester.ensureVisible(find.byKey(Key('class-q$i-o$option')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(Key('class-q$i-o$option')));
      await tester.pump();
    }
    await tester.ensureVisible(find.byKey(const Key('class-check')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('class-check')));
    await tester.pumpAndSettle();

    expect(
      find.text('${lesson.questions.length} / ${lesson.questions.length}'),
      findsOneWidget,
    );
    final rows = await db.assignmentsForWeek(week.id);
    final teaching = rows.firstWhere(
      (row) => row.skill == SkillKind.teaching.name,
    );
    expect(
      teaching.completedAt,
      isNotNull,
      reason: 'checking understanding closes the class block',
    );
    expect(teaching.evidenceKind, 'courseLesson');

    // The speaking block waits for real practice.
    expect(
      rows
          .firstWhere(
            (row) =>
                row.skill == SkillKind.speaking.name && row.dayIndex == 1,
          )
          .completedAt,
      isNull,
    );
  });

  testWidgets('a wrong answer explains instead of blocking the class', (
    tester,
  ) async {
    final (db, week, lesson) = await _seedWeek();
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          ttsServiceProvider.overrideWithValue(_FakeTts()),
        ],
        child: MaterialApp(home: WeeklyClassScreen(week: week)),
      ),
    );
    await tester.pumpAndSettle();
    await advance(tester, 1);

    for (var i = 0; i < lesson.questions.length; i++) {
      final wrong = (lesson.questions[i].correct + 1) %
          lesson.questions[i].options.length;
      await tester.ensureVisible(find.byKey(Key('class-q$i-o$wrong')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(Key('class-q$i-o$wrong')));
      await tester.pump();
    }
    await tester.ensureVisible(find.byKey(const Key('class-check')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('class-check')));
    await tester.pumpAndSettle();

    expect(find.textContaining('✘'), findsWidgets);
    expect(find.text('0 / ${lesson.questions.length}'), findsOneWidget);
    final teaching = (await db.assignmentsForWeek(week.id)).firstWhere(
      (row) => row.skill == SkillKind.teaching.name,
    );
    expect(
      teaching.completedAt,
      isNotNull,
      reason: 'the class is formative: a wrong answer still teaches',
    );
  });

  testWidgets('the homework step shows the week with speaking dominant', (
    tester,
  ) async {
    final (db, week, _) = await _seedWeek();
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          ttsServiceProvider.overrideWithValue(_FakeTts()),
        ],
        child: MaterialApp(home: WeeklyClassScreen(week: week)),
      ),
    );
    await tester.pumpAndSettle();
    await advance(tester, 3);

    final plan = week.plan;
    expect(
      find.textContaining(
        'Expression orale ${(plan.shareOf(SkillKind.speaking) * 100).round()} %',
      ),
      findsOneWidget,
    );
    expect(find.text('Jour 1'), findsOneWidget);
    expect(find.text('Jour ${plan.studyDays}'), findsOneWidget);
    expect(find.byKey(const Key('class-done')), findsOneWidget);
  });
}
