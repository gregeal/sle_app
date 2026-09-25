import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sle_prep/data/db/course_daos.dart';
import 'package:sle_prep/data/db/daos.dart';
import 'dart:convert';
import 'package:sle_prep/domain/course/b_to_c_course.dart';
import 'package:sle_prep/features/course/course_screen.dart';
import 'package:sle_prep/providers.dart';
import '../support/test_db.dart';
import '../features/learning_hub_test.dart' show FakeTts;
import 'course_fixtures.dart';

Future<void> tapCourse(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    350,
    maxScrolls: 80,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'recall starts without previous quiz answers or practice checks',
    (tester) async {
      final db = inMemoryDatabase();
      addTearDown(db.close);
      final lesson = bToCLessons.first;
      final progress = CourseProgress(
        read: true,
        quizPassed: true,
        practice: const [true, true, true],
        completedAt: DateTime(2020),
        reviewAt: DateTime(2020, 1, 3),
      );
      await db.setSetting(
        'course:$courseId:${lesson.id}',
        jsonEncode(progress.toJson()),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            ttsServiceProvider.overrideWithValue(FakeTts()),
          ],
          child: MaterialApp(
            home: CourseLessonScreen(lesson: lesson, recall: true),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const Key('course-recall')),
        350,
        maxScrolls: 80,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('course-recall')))
            .onPressed,
        isNull,
      );
      for (var i = 0; i < lesson.criteria.length; i++) {
        expect(
          tester
              .widget<CheckboxListTile>(find.byKey(Key('course-criterion-$i')))
              .value,
          isFalse,
        );
      }
      expect((await db.courseProgress(lesson.id)).reviewCount, 0);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'class teaches, checks understanding, records practice and preserves notes',
    (tester) async {
      final db = inMemoryDatabase();
      addTearDown(db.close);
      final lesson = bToCLessons.first;
      final tts = FakeTts();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            ttsServiceProvider.overrideWithValue(tts),
          ],
          child: MaterialApp(home: CourseLessonScreen(lesson: lesson)),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(lesson.objective), findsOneWidget);
      await tapCourse(
        tester,
        find.text('Écouter l’exemple · voix synthétique'),
      );
      expect(tts.spoken, [lesson.developedExample]);
      await tapCourse(tester, find.byKey(const Key('course-read')));
      expect((await db.courseProgress(lesson.id)).read, isTrue);
      final comprehension = workshopAnswers(lesson.id);
      for (var i = 0; i < 2; i++) {
        await tapCourse(
          tester,
          find.byKey(Key('course-comprehension-$i-${comprehension[i]}')),
        );
      }
      await tapCourse(
        tester,
        find.byKey(const Key('course-check-comprehension')),
      );
      await tester.scrollUntilVisible(
        find.byKey(const Key('course-writing')),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.enterText(
        find.byKey(const Key('course-writing')),
        'Mon texte personnel décrit le changement et précise une limite importante.',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      for (var i = 0; i < 3; i++) {
        await tapCourse(tester, find.byKey(Key('course-revision-$i')));
      }
      await tapCourse(tester, find.byKey(const Key('course-save-workshop')));
      for (var i = 0; i < lesson.questions.length; i++) {
        await tapCourse(
          tester,
          find.byKey(Key('course-q$i-o${lesson.questions[i].correct}')),
        );
      }
      await tapCourse(tester, find.byKey(const Key('course-quiz')));
      expect((await db.courseProgress(lesson.id)).quizPassed, isTrue);
      expect((await db.courseProgress(lesson.id)).completed, isFalse);
      for (var i = 0; i < lesson.criteria.length; i++) {
        await tapCourse(tester, find.byKey(Key('course-criterion-$i')));
      }
      await tapCourse(tester, find.byKey(const Key('course-practice')));
      expect((await db.courseProgress(lesson.id)).completed, isTrue);
      await tester.scrollUntilVisible(
        find.byKey(const Key('course-notes')),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.enterText(
        find.byKey(const Key('course-notes')),
        'Expliquer le changement avec mon propre exemple.',
      );
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      expect(
        (await db.courseProgress(lesson.id)).notes,
        contains('mon propre exemple'),
      );
      expect(tts.stops, greaterThan(0));
    },
  );

  testWidgets(
    'roadmap resumes the first unfinished lesson, independently of calendar week',
    (tester) async {
      final db = inMemoryDatabase();
      addTearDown(db.close);
      final first = bToCLessons.first;
      await db.markCourseRead(first.id);
      await db.submitCourseQuiz(
        first.id,
        first.questions.map((q) => q.correct).toList(),
      );
      await db.saveCoursePractice(first.id, [true, true, true]);
      await finishWorkshop(db, first.id);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            ttsServiceProvider.overrideWithValue(FakeTts()),
          ],
          child: const MaterialApp(home: CourseScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('1 / 16 leçons terminées · 8 modules'), findsOneWidget);
      await tapCourse(tester, find.byKey(const Key('course-continue')));
      expect(find.text(bToCLessons[1].objective), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );
}
