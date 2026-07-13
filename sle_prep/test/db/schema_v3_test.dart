import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sle_prep/data/db/daos.dart';

import '../support/test_db.dart';

void main() {
  final now = DateTime(2026, 7, 13, 9, 0);

  group('oral questions', () {
    test('insert and fetch by tier', () async {
      final db = inMemoryDatabase();
      addTearDown(db.close);

      await db.insertOralQuestion(
          tier: 'A', questionFr: 'Décrivez votre poste actuel.');
      await db.insertOralQuestion(
          tier: 'C',
          questionFr:
              'Si votre budget était réduit de 15 %, que proposeriez-vous ?');

      final aTier = await db.oralQuestionsByTier('A');
      expect(aTier, hasLength(1));
      expect(aTier.single.source, 'seed');
      expect(await db.oralQuestionsByTier('B'), isEmpty);
    });
  });

  group('oral attempts', () {
    test('record and list newest first with parsed exchanges', () async {
      final db = inMemoryDatabase();
      addTearDown(db.close);

      await db.recordOralAttempt(
        mode: 'daily',
        exchanges: const [
          {'question': 'Décrivez votre poste.', 'answer': 'Je suis analyste…'},
        ],
        feedback: jsonEncode({'levelEstimate': 'B'}),
        at: now,
      );
      await db.recordOralAttempt(
        mode: 'interview',
        exchanges: const [
          {'question': 'q1', 'answer': 'a1'},
          {'question': 'q2', 'answer': 'a2'},
        ],
        feedback: jsonEncode({'levelEstimate': 'B+'}),
        at: now.add(const Duration(hours: 1)),
      );

      final history = await db.oralHistory();
      expect(history, hasLength(2));
      expect(history.first.mode, 'interview');
      expect(history.first.exchangesList, hasLength(2));
      expect(history.last.exchangesList.single['question'],
          contains('poste'));
    });
  });
}
