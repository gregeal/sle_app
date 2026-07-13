import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sle_prep/data/db/daos.dart';
import 'package:sle_prep/domain/llm/llm_client.dart';
import 'package:sle_prep/domain/llm/oral_coach.dart';

import '../support/test_db.dart';

class _ScriptedClient implements LlmClient {
  _ScriptedClient(this.responses);

  final List<String> responses;
  final userPrompts = <String>[];

  @override
  Future<String> complete({
    required String system,
    required String user,
    double temperature = 0.7,
    int? maxTokens,
  }) async {
    userPrompts.add(user);
    return responses.removeAt(0);
  }
}

String _payload({List<Map<String, String>>? criteria}) => jsonEncode({
      'levelEstimate': 'B',
      'summary': 'La compréhension atteint déjà le niveau C.',
      'criteria': criteria ??
          [
            {'name': 'aisance', 'level': 'B', 'comment': 'Débit régulier.'},
            {'name': 'comprehension', 'level': 'C', 'comment': 'Très bonne.'},
            {'name': 'vocabulaire', 'level': 'B+', 'comment': 'Varié.'},
            {'name': 'grammaire', 'level': 'B', 'comment': 'Accords à revoir.'},
            {
              'name': 'prononciation',
              'level': 'B',
              'comment': 'Approximation fondée sur la transcription.',
            },
          ],
      'tips': ['Accord du participe.', 'Structurez vos réponses.', 'Variez les connecteurs.'],
    });

void main() {
  const exchange = {
    'question': 'Décrivez votre poste actuel.',
    'answer': 'Je suis analyste principal depuis deux ans…',
  };

  group('parseOralFeedback', () {
    test('parses a complete report with all five criteria', () {
      final feedback = parseOralFeedback(_payload());
      expect(feedback.levelEstimate, 'B');
      expect(feedback.criteria, hasLength(5));
      expect(feedback.criterion('comprehension')!.level, 'C');
      expect(feedback.tips, hasLength(3));
    });

    test('rejects a report missing one of the five OLA criteria', () {
      expect(
        () => parseOralFeedback(_payload(criteria: [
          {'name': 'aisance', 'level': 'B', 'comment': 'x'},
        ])),
        throwsA(isA<LlmException>()),
      );
    });

    test('rejects non-JSON', () {
      expect(
        () => parseOralFeedback('désolé'),
        throwsA(isA<LlmException>()),
      );
    });
  });

  group('requestOralFeedback', () {
    test('includes every exchange in the prompt and persists the attempt',
        () async {
      final db = inMemoryDatabase();
      addTearDown(db.close);
      final client = _ScriptedClient([_payload()]);

      final feedback = await requestOralFeedback(
        db: db,
        client: client,
        mode: 'interview',
        exchanges: const [
          exchange,
          {'question': 'Question C — hypothèse budgétaire ?', 'answer': 'Je proposerais…'},
        ],
      );

      expect(feedback.levelEstimate, 'B');
      expect(client.userPrompts.single, contains('analyste principal'));
      expect(client.userPrompts.single, contains('hypothèse budgétaire'));

      final history = await db.oralHistory();
      expect(history, hasLength(1));
      expect(history.single.mode, 'interview');
      expect(history.single.exchangesList, hasLength(2));
    });

    test('retries once then throws without persisting', () async {
      final db = inMemoryDatabase();
      addTearDown(db.close);
      final client = _ScriptedClient(['non', 'non plus']);

      await expectLater(
        requestOralFeedback(
          db: db,
          client: client,
          mode: 'daily',
          exchanges: const [exchange],
        ),
        throwsA(isA<LlmException>()),
      );
      expect(await db.oralHistory(), isEmpty);
    });
  });

  test('levelProgress maps letters to bar fractions for the report UI', () {
    expect(levelProgress('A'), closeTo(0.35, 0.01));
    expect(levelProgress('B'), closeTo(0.62, 0.01));
    expect(levelProgress('B+'), closeTo(0.75, 0.01));
    expect(levelProgress('C'), closeTo(0.9, 0.01));
    expect(levelProgress('inconnu'), closeTo(0.5, 0.01));
  });
}
