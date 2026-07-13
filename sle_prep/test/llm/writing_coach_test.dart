import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sle_prep/data/db/daos.dart';
import 'package:sle_prep/domain/llm/llm_client.dart';
import 'package:sle_prep/domain/llm/writing_coach.dart';

import '../support/test_db.dart';

class _ScriptedClient implements LlmClient {
  _ScriptedClient(this.responses);

  final List<String> responses;

  @override
  Future<String> complete({
    required String system,
    required String user,
    double temperature = 0.7,
    int? maxTokens,
  }) async =>
      responses.removeAt(0);
}

String _payload() => jsonEncode({
      'levelEstimate': 'B',
      'correctedText': 'Bonjour, il faudrait que les gestionnaires soient consultés.',
      'errors': [
        {
          'extrait': 'soient consulté',
          'correction': 'soient consultés',
          'explication': 'Accord du participe passé au passif.',
        },
      ],
      'tips': ['Variez les connecteurs.', 'Structurez en trois paragraphes.'],
    });

void main() {
  group('parseWritingFeedback', () {
    test('parses a well-formed payload', () {
      final feedback = parseWritingFeedback(_payload());
      expect(feedback.levelEstimate, 'B');
      expect(feedback.correctedText, contains('consultés'));
      expect(feedback.errors.single.extrait, 'soient consulté');
      expect(feedback.tips, hasLength(2));
    });

    test('tolerates missing errors/tips lists but not missing level', () {
      final minimal = parseWritingFeedback(jsonEncode({
        'levelEstimate': 'C',
        'correctedText': 'Texte corrigé.',
      }));
      expect(minimal.errors, isEmpty);
      expect(minimal.tips, isEmpty);

      expect(
        () => parseWritingFeedback(jsonEncode({'correctedText': 'x'})),
        throwsA(isA<LlmException>()),
      );
    });

    test('throws on non-JSON', () {
      expect(
        () => parseWritingFeedback('Je ne peux pas.'),
        throwsA(isA<LlmException>()),
      );
    });
  });

  group('requestWritingFeedback', () {
    test('returns the feedback and persists the attempt', () async {
      final db = inMemoryDatabase();
      addTearDown(db.close);
      final client = _ScriptedClient([_payload()]);

      final feedback = await requestWritingFeedback(
        db: db,
        client: client,
        promptFr: 'Rédigez un courriel à votre gestionnaire.',
        userText: 'Bonjour, il faudrait que les gestionnaires soient consulté.',
      );

      expect(feedback.levelEstimate, 'B');
      final history = await db.writingHistory();
      expect(history, hasLength(1));
      expect(history.single.userText, contains('gestionnaires'));
      final stored =
          jsonDecode(history.single.feedback) as Map<String, dynamic>;
      expect(stored['levelEstimate'], 'B');
    });

    test('retries once then throws without persisting', () async {
      final db = inMemoryDatabase();
      addTearDown(db.close);
      final client = _ScriptedClient(['non', 'toujours non']);

      await expectLater(
        requestWritingFeedback(
          db: db,
          client: client,
          promptFr: 'p',
          userText: 'u',
        ),
        throwsA(isA<LlmException>()),
      );
      expect(await db.writingHistory(), isEmpty);
    });
  });

  test('compositionPromptFor is deterministic per day and theme-aware', () {
    final a = compositionPromptFor("Réunions d'équipe", 0);
    final b = compositionPromptFor("Réunions d'équipe", 1);
    expect(a, contains("Réunions d'équipe"));
    expect(a, isNot(equals(b)));
  });
}
