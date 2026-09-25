import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:sle_prep/data/db/course_daos.dart';
import 'package:sle_prep/data/db/daos.dart';
import 'package:sle_prep/domain/course/course_catalog.dart';
import 'package:sle_prep/domain/course/course_workshops.dart';
import '../support/test_db.dart';
import 'course_fixtures.dart';

void main() {
  test(
    'both tracks have 16 distinct four-skill lessons with level-appropriate material',
    () {
      final ids = <String>{};
      for (final track in courseTracks) {
        expect(track.lessons.length, 16);
        expect(track.modules.length, 8);
        for (final lesson in track.lessons) {
          expect(ids.add(lesson.id), isTrue);
          expect(lesson.foundation, track == aToBCourse);
          expect(lesson.teaching.length, greaterThanOrEqualTo(4));
          expect(lesson.criteria.length, 3);
          expect(lesson.questions.length, 2);
          expect(lesson.partnerPrompt.length, lessThanOrEqualTo(1200));
          final workshop = workshopForLesson(lesson.id);
          expect(workshop.reading.length, greaterThan(100));
          expect(workshop.listening.length, greaterThan(80));
          expect(workshop.reading, isNot(workshop.listening));
          expect(workshop.writingTask, isNotEmpty);
          expect(workshop.writingModel.length, greaterThan(80));
          for (final q in [
            ...lesson.questions,
            workshop.readingQuestion,
            workshop.listeningQuestion,
          ]) {
            expect(q.options.length, 3);
            expect(q.options.toSet().length, 3);
            expect(q.correct, inInclusiveRange(0, 2));
            expect(q.explanation, isNotEmpty);
          }
        }
      }
      expect(ids, courseWorkshops.keys.toSet());
      expect(
        aToBCourse.lessons.first.partnerPrompt,
        isNot(contains('hypothèse complexe')),
      );
    },
  );

  test(
    'legacy B to C completion and notes survive; new workshops are not invented',
    () async {
      final db = inMemoryDatabase();
      addTearDown(db.close);
      final id = bToCCourse.lessons.first.id;
      final old =
          CourseProgress(
              read: true,
              quizPassed: true,
              practice: const [true, true, true],
              completedAt: DateTime(2026, 9, 25),
              reviewAt: DateTime(2026, 9, 27),
              notes: 'À conserver.',
            ).toJson()
            ..remove('skills')
            ..remove('writing');
      await db.setSetting('course:b-to-c-v1:$id', jsonEncode(old));
      final loaded = await db.courseProgress(id);
      expect(loaded.completed, isTrue);
      expect(loaded.fullCourseCompleted, isFalse);
      expect(loaded.notes, 'À conserver.');
      await db.markCourseRead(aToBCourse.lessons.first.id);
      expect((await db.courseOverview()).keys, [id]);
      expect((await db.courseOverview(track: aToBCourse)).keys, [
        aToBCourse.lessons.first.id,
      ]);
      await finishWorkshop(db, id);
      expect((await db.courseProgress(id)).completedAt, loaded.completedAt);
      expect((await db.courseProgress(id)).fullCourseCompleted, isTrue);
    },
  );

  test(
    'workshop rejects empty writing and invalid answers; results survive note edits',
    () async {
      final db = inMemoryDatabase();
      addTearDown(db.close);
      final id = aToBCourse.lessons.first.id;
      await expectLater(
        db.saveCourseWorkshop(
          id,
          answers: workshopAnswers(id),
          writingRevised: true,
        ),
        throwsArgumentError,
      );
      await expectLater(
        db.saveCourseWorkshop(id, answers: [10, 0], writingRevised: false),
        throwsArgumentError,
      );
      await finishWorkshop(db, id);
      await db.saveCourseNotes(id, 'Nouvelles notes.');
      final progress = await db.courseProgress(id);
      expect(progress.skills, [true, true, true]);
      expect(progress.writing, contains('Mon texte personnel'));
      expect(
        progress.completed,
        isFalse,
      ); // Core study and speaking still needed.
      final ab = await db.courseSpeakingSession(id);
      final bc = await db.courseSpeakingSession(bToCCourse.lessons.first.id);
      expect(await db.isFoundationCourseSession(ab), isTrue);
      expect(await db.isFoundationCourseSession(bc), isFalse);
    },
  );
}
