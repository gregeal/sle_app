import 'package:flutter_test/flutter_test.dart';
import 'package:sle_prep/data/db/course_daos.dart';
import 'package:sle_prep/data/db/daos.dart';
import 'package:sle_prep/data/db/speaking_daos.dart';
import 'package:sle_prep/domain/course/b_to_c_course.dart';
import 'package:sle_prep/domain/session/restart_course.dart';
import '../support/test_db.dart';

void main() {
  test('restarting the calendar preserves the separate course track', () async {
    final db = inMemoryDatabase();
    addTearDown(db.close);
    await db.upsertWeek(
      weekNumber: 1,
      themeFr: 'Début',
      themeEn: 'Start',
      grammarTopics: ['present'],
      vocabDomain: 'travail',
      resourceSlots: [],
    );
    await db.setSetting('planStartDate', '2026-07-12');
    final lesson = bToCLessons.first;
    await db.markCourseRead(lesson.id);
    await db.saveCourseNotes(lesson.id, 'Mon exemple à conserver.');
    final before = await db.getSetting('course:$courseId:${lesson.id}');
    await restartCourse(db, DateTime(2026, 9, 25));
    expect(await db.getSetting('planStartDate'), '2026-09-25');
    expect(await db.getSetting('course:$courseId:${lesson.id}'), before);
  });

  test(
    '16 complete original lessons form eight ordered modules with valid activities',
    () {
      expect(bToCLessons.length, 16);
      expect(courseModules.length, 8);
      expect(bToCLessons.map((l) => l.id).toSet().length, 16);
      for (final module in courseModules) {
        expect(bToCLessons.where((l) => l.module == module.number).length, 2);
      }
      for (final lesson in bToCLessons) {
        expect(lesson.id, matches(RegExp(r'^\d{2}-[a-z]+$')));
        expect(lesson.teaching.length, greaterThanOrEqualTo(4));
        expect(lesson.teaching.every((p) => p.length > 80), isTrue);
        expect(lesson.simpleExample, isNotEmpty);
        expect(lesson.developedExample.length, greaterThan(100));
        expect(lesson.phrases.length, greaterThanOrEqualTo(3));
        expect(lesson.exercise, isNotEmpty);
        expect(lesson.modelAnswer, isNotEmpty);
        expect(lesson.criteria.length, 3);
        expect(lesson.questions.length, 2);
        expect(lesson.speakingTask.length, lessThanOrEqualTo(1200));
        expect(lesson.partnerPrompt.length, lessThanOrEqualTo(1200));
        expect(lesson.partnerPrompt, contains(lesson.objective));
        if (lesson.module == 6) {
          expect(lesson.partnerPrompt, contains(lesson.developedExample));
          expect(lesson.partnerPrompt, contains(lesson.exercise));
        }
        expect('Cours B → C · ${lesson.title}'.length, lessThanOrEqualTo(300));
        for (final question in lesson.questions) {
          expect(question.options.length, 3);
          expect(question.options.toSet().length, 3);
          expect(question.correct, inInclusiveRange(0, 2));
          expect(question.explanation, isNotEmpty);
        }
      }
    },
  );

  test(
    'completion requires study, successful quiz and self-attested oral practice',
    () async {
      final db = inMemoryDatabase();
      addTearDown(db.close);
      final lesson = bToCLessons.first;
      await db.setSetting('planStartDate', '2026-09-01');
      expect(await db.courseOverview(), isEmpty);
      await db.markCourseRead(lesson.id);
      expect(await db.submitCourseQuiz(lesson.id, [2, 2]), 0);
      await db.saveCoursePractice(lesson.id, [true, true, true]);
      expect((await db.courseProgress(lesson.id)).completed, isFalse);
      expect(
        await db.submitCourseQuiz(
          lesson.id,
          lesson.questions.map((q) => q.correct).toList(),
        ),
        2,
      );
      final progress = await db.courseProgress(lesson.id);
      expect(progress.completed, isTrue);
      expect(
        progress.reviewAt!.difference(progress.completedAt!),
        const Duration(days: 2),
      );
      expect(progress.due(progress.completedAt!), isFalse);
      expect(await db.getSetting('planStartDate'), '2026-09-01');
      expect((await db.courseOverview()).length, 1);
      // Repeating the class is practice, not erasure of historical completion.
      await db.submitCourseQuiz(lesson.id, [2, 2]);
      expect(
        (await db.courseProgress(lesson.id)).completedAt,
        progress.completedAt,
      );
    },
  );

  test(
    'notes merge does not erase results or a reusable linked conversation',
    () async {
      final db = inMemoryDatabase();
      addTearDown(db.close);
      final lesson = bToCLessons.first;
      await db.markCourseRead(lesson.id);
      await db.saveCourseNotes(lesson.id, 'Mon exemple personnel.');
      final session = await db.courseSpeakingSession(lesson.id);
      expect(await db.courseSpeakingSession(lesson.id), session);
      await db.saveCourseNotes(lesson.id, 'Mon exemple révisé.');
      final progress = await db.courseProgress(lesson.id);
      expect(progress.read, isTrue);
      expect(progress.notes, 'Mon exemple révisé.');
      expect(progress.speakingSessionId, session);
      expect(
        (await db.speakingSession(session)).promptFr,
        lesson.partnerPrompt,
      );
      expect(
        (await db.speakingSession(session)).promptFr,
        isNot(contains(progress.notes)),
      );
      await db.finishSpeakingSession(session);
      expect(await db.courseSpeakingSession(lesson.id), isNot(session));
      expect((await db.recentSpeakingSessions()).length, 2);
    },
  );

  test(
    'recall requires fresh evidence, schedules spacing and rejects double grading',
    () async {
      final db = inMemoryDatabase();
      addTearDown(db.close);
      final lesson = bToCLessons.first;
      final answers = lesson.questions.map((q) => q.correct).toList();
      await db.markCourseRead(lesson.id);
      await db.submitCourseQuiz(lesson.id, answers);
      await db.saveCoursePractice(lesson.id, [true, true, true]);
      var progress = await db.courseProgress(lesson.id);
      final now = progress.reviewAt!;
      await expectLater(
        db.completeCourseRecall(
          lesson.id,
          answers: answers,
          criteria: [true, false, true],
          expectedCount: 0,
          now: now,
        ),
        throwsStateError,
      );
      await db.completeCourseRecall(
        lesson.id,
        answers: answers,
        criteria: [true, true, true],
        expectedCount: 0,
        now: now,
      );
      progress = await db.courseProgress(lesson.id);
      expect(progress.reviewCount, 1);
      expect(progress.reviewAt, now.add(const Duration(days: 7)));
      await expectLater(
        db.completeCourseRecall(
          lesson.id,
          answers: answers,
          criteria: [true, true, true],
          expectedCount: 0,
          now: now,
        ),
        throwsStateError,
      );
      await db.completeCourseRecall(
        lesson.id,
        answers: answers,
        criteria: [true, true, true],
        expectedCount: 1,
        now: progress.reviewAt!,
      );
      final second = await db.courseProgress(lesson.id);
      expect(second.reviewAt, progress.reviewAt!.add(const Duration(days: 21)));
    },
  );

  test(
    'invalid input and corrupt stored progress never silently overwrite history',
    () async {
      final db = inMemoryDatabase();
      addTearDown(db.close);
      final id = bToCLessons.first.id;
      expect(() => db.saveCourseNotes(id, 'x' * 3001), throwsArgumentError);
      expect(() => db.saveCoursePractice(id, [true]), throwsArgumentError);
      await expectLater(db.submitCourseQuiz(id, [0]), throwsArgumentError);
      await expectLater(db.courseProgress('unknown'), throwsStateError);
      await db.setSetting('course:$courseId:$id', '{broken');
      await expectLater(db.markCourseRead(id), throwsFormatException);
      expect(await db.getSetting('course:$courseId:$id'), '{broken');
      await expectLater(db.courseOverview(), throwsFormatException);
    },
  );
}
