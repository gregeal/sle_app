import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sle_prep/data/db/daos.dart';

import '../support/test_db.dart';

void main() {
  final now = DateTime(2026, 7, 12, 9, 0);

  group('reading sets', () {
    test('insert and fetch round-trips the questions JSON', () async {
      final db = inMemoryDatabase();
      addTearDown(db.close);

      final id = await db.insertReadingSet(
        title: 'Note de service — télétravail',
        kind: 'note_service',
        bodyFr: 'À tous les employés…',
        questions: const [
          {
            'prompt': 'Quel est l\'objet de la note ?',
            'options': ['a', 'b', 'c', 'd'],
            'correctIndex': 2,
            'explanationFr': 'L\'objet figure au premier paragraphe.',
          },
        ],
      );

      final sets = await db.allReadingSets();
      expect(sets, hasLength(1));
      expect(sets.single.id, id);
      expect(sets.single.source, 'seed');
      final questions = sets.single.questionsList;
      expect(questions.single['correctIndex'], 2);
      expect((questions.single['options'] as List), hasLength(4));
    });

    test('recordReadingAttempt persists results and history is ordered',
        () async {
      final db = inMemoryDatabase();
      addTearDown(db.close);

      final id = await db.insertReadingSet(
        title: 't',
        kind: 'courriel',
        bodyFr: 'b',
        questions: const [],
      );
      await db.recordReadingAttempt(
        setId: id,
        correct: 6,
        total: 8,
        seconds: 540,
        at: now,
      );
      await db.recordReadingAttempt(
        setId: id,
        correct: 7,
        total: 8,
        seconds: 500,
        at: now.add(const Duration(days: 1)),
      );

      final attempts = await db.readingHistory();
      expect(attempts, hasLength(2));
      expect(attempts.first.answeredAt.isAfter(attempts.last.answeredAt),
          isTrue,
          reason: 'newest first');
      expect(attempts.first.correct, 7);
    });
  });

  group('writing attempts', () {
    test('insert stores the feedback JSON and history is retrievable',
        () async {
      final db = inMemoryDatabase();
      addTearDown(db.close);

      await db.insertWritingAttempt(
        promptFr: 'Rédigez un courriel à votre gestionnaire…',
        userText: 'Bonjour, je voudrais…',
        feedback: jsonEncode({'levelEstimate': 'B', 'errors': []}),
        at: now,
      );

      final attempts = await db.writingHistory();
      expect(attempts, hasLength(1));
      expect(attempts.single.promptFr, contains('gestionnaire'));
      expect(
        (jsonDecode(attempts.single.feedback)
            as Map<String, dynamic>)['levelEstimate'],
        'B',
      );
    });
  });
}
