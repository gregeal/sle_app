import 'package:flutter_test/flutter_test.dart';
import 'package:sle_prep/data/db/daos.dart';
import 'package:sle_prep/data/db/learning_daos.dart';
import 'package:sle_prep/domain/learning/listening_lessons.dart';

import '../support/test_db.dart';

void main() {
  test(
    'personal expressions are due immediately and duplicates preserve progress',
    () async {
      final db = inMemoryDatabase();
      addTearDown(db.close);
      final now = DateTime(2026, 9, 11, 16);
      final id = await db.addPersonalWord(
        front: '  provided that ',
        back: 'à condition que',
        example: 'Je suis d’accord à condition que le budget soit respecté.',
        now: now,
      );
      expect((await db.dueCards(now)).single.card.id, id);
      await db.applyReview(
        cardId: id,
        easeFactor: 2.8,
        intervalDays: 6,
        repetitions: 2,
        lapses: 0,
        dueDate: now.add(const Duration(days: 6)),
      );
      final duplicate = await db.addPersonalWord(
        front: 'PROVIDED   THAT',
        back: 'À CONDITION QUE',
        example: '',
        now: now,
      );
      expect(duplicate, id);
      expect(await db.vocabularyLibrary(), hasLength(1));
      expect((await db.reviewStateFor(id)).intervalDays, 6);
    },
  );

  test('invalid personal vocabulary never creates a partial card', () async {
    final db = inMemoryDatabase();
    addTearDown(db.close);
    await expectLater(
      db.addPersonalWord(
        front: ' ',
        back: 'mot',
        example: '',
        now: DateTime.now(),
      ),
      throwsFormatException,
    );
    expect(await db.vocabularyLibrary(), isEmpty);
  });

  test(
    'personal edits preserve scheduling and cannot modify seeded cards',
    () async {
      final db = inMemoryDatabase();
      addTearDown(db.close);
      final now = DateTime(2026, 9, 11);
      final id = await db.addPersonalWord(
        front: 'deadline',
        back: 'échéance',
        example: '',
        now: now,
      );
      final originalState = await db.reviewStateFor(id);
      await db.addPersonalWord(
        cardId: id,
        front: 'deadline',
        back: 'date limite',
        example: 'Respectez la date limite.',
        now: now.add(const Duration(days: 1)),
      );
      expect(await db.reviewStateFor(id), originalState);
      expect((await db.vocabularyLibrary()).single.back, 'date limite');
      final seeded = await db.insertCardWithState(
        front: 'seed',
        back: 'origine',
        exampleFr: '',
        domain: 'seed',
        now: now,
      );
      await expectLater(
        db.addPersonalWord(
          cardId: seeded,
          front: 'changed',
          back: 'modifié',
          example: '',
          now: now,
        ),
        throwsArgumentError,
      );
      await expectLater(db.deletePersonalWord(seeded), throwsArgumentError);
      await db.deletePersonalWord(id);
      expect((await db.vocabularyLibrary()).single.id, seeded);
      expect((await db.select(db.reviewStates).get()).single.cardId, seeded);
    },
  );

  test(
    'latest grammar attempt controls recovery queue including timestamp ties',
    () async {
      final db = inMemoryDatabase();
      addTearDown(db.close);
      final id = await db.insertDrillItem(
        topic: 'conditionnel',
        prompt: 'Si j’avais le temps…',
        options: ['je viendrai', 'je viendrais', 'je viens', 'je suis venu'],
        correctIndex: 1,
        explanationFr: 'Si + imparfait, conditionnel présent.',
      );
      final day = DateTime(2026, 9, 11);
      await db.recordAttempt(id, wasCorrect: false, at: day);
      expect((await db.unresolvedDrillMistakes()).single.id, id);
      await db.recordAttempt(id, wasCorrect: true, at: day);
      expect(await db.unresolvedDrillMistakes(), isEmpty);
      await db.recordAttempt(
        id,
        wasCorrect: false,
        at: day.subtract(const Duration(days: 1)),
      );
      expect(await db.unresolvedDrillMistakes(), isEmpty);
      await db.recordAttempt(
        id,
        wasCorrect: false,
        at: day.add(const Duration(days: 1)),
      );
      expect(await db.unresolvedDrillMistakes(), hasLength(1));
    },
  );

  test(
    'listening results persist separately from reading and mock estimates',
    () async {
      final db = inMemoryDatabase();
      addTearDown(db.close);
      await db.recordListening(
        lessonId: '-1',
        correct: 2,
        total: 3,
        seconds: 120,
        usedTranscript: true,
        at: DateTime.now(),
      );
      final row = (await db.listeningHistory()).single;
      expect(row.correct, 2);
      expect(row.usedTranscript, isTrue);
      expect(await db.select(db.readingAttempts).get(), isEmpty);
      expect(await db.select(db.mockResults).get(), isEmpty);
      await expectLater(
        db.recordListening(
          lessonId: '-1',
          correct: 4,
          total: 3,
          seconds: 1,
          usedTranscript: false,
          at: DateTime.now(),
        ),
        throwsArgumentError,
      );
      expect(await db.listeningHistory(), hasLength(1));
    },
  );

  test('listening catalog has unique lessons and valid answer keys', () {
    expect(listeningLessons, hasLength(4));
    expect(listeningLessons.map((l) => l.id).toSet(), hasLength(4));
    for (final lesson in listeningLessons) {
      expect(lesson.bodyFr.split(' ').length, greaterThan(65));
      expect(lesson.questionsList, hasLength(3));
      for (final question in lesson.questionsList) {
        expect(question['options'], hasLength(4));
        expect((question['options'] as List).toSet(), hasLength(4));
        expect(question['correctIndex'], inInclusiveRange(0, 3));
        expect((question['explanationFr'] as String).length, greaterThan(20));
      }
    }
  });
}
