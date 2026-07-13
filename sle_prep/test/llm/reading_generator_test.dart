import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sle_prep/data/db/daos.dart';
import 'package:sle_prep/domain/llm/llm_client.dart';
import 'package:sle_prep/domain/llm/reading_generator.dart';

import '../support/test_db.dart';

class _ScriptedClient implements LlmClient {
  _ScriptedClient(this.responses);

  final List<String> responses;
  var calls = 0;

  @override
  Future<String> complete({
    required String system,
    required String user,
    double temperature = 0.7,
    int? maxTokens,
  }) async {
    calls++;
    return responses.removeAt(0);
  }
}

Map<String, dynamic> _question({int correctIndex = 1}) => {
      'prompt': 'Quel est l\'objet du texte ?',
      'options': ['a', 'b', 'c', 'd'],
      'correctIndex': correctIndex,
      'explanationFr': 'Voir le premier paragraphe.',
    };

String _payload({String? bodyFr, List<Map<String, dynamic>>? questions}) =>
    jsonEncode({
      'title': 'Note de service — test',
      'kind': 'note_service',
      'bodyFr': bodyFr ?? ('La présente note vise à informer les employés. ' * 10),
      'questions': questions ?? [_question(), _question(), _question(), _question()],
    });

void main() {
  group('parseGeneratedReadingSet', () {
    test('accepts a well-formed passage and keeps valid questions', () {
      final set = parseGeneratedReadingSet(_payload());
      expect(set.title, contains('Note'));
      expect(set.questions, hasLength(4));
    });

    test('drops malformed questions but requires at least three', () {
      final set = parseGeneratedReadingSet(_payload(questions: [
        _question(),
        _question(),
        _question(),
        _question(correctIndex: 9),
      ]));
      expect(set.questions, hasLength(3));

      expect(
        () => parseGeneratedReadingSet(_payload(questions: [
          _question(),
          _question(correctIndex: 9),
          _question(correctIndex: -1),
          {'prompt': ''},
        ])),
        throwsA(isA<LlmException>()),
      );
    });

    test('rejects a passage that is too short to be SLE-like', () {
      expect(
        () => parseGeneratedReadingSet(_payload(bodyFr: 'Trop court.')),
        throwsA(isA<LlmException>()),
      );
    });
  });

  group('generateReadingSet', () {
    test('inserts the passage with source=generated', () async {
      final db = inMemoryDatabase();
      addTearDown(db.close);
      final client = _ScriptedClient([_payload()]);

      final title = await generateReadingSet(
        db: db,
        client: client,
        themeFr: "Réunions d'équipe",
      );

      expect(title, isNotEmpty);
      final sets = await db.allReadingSets();
      expect(sets, hasLength(1));
      expect(sets.single.source, 'generated');
      expect(sets.single.questionsList.length, greaterThanOrEqualTo(3));
    });

    test('retries once on an unusable reply, then throws', () async {
      final db = inMemoryDatabase();
      addTearDown(db.close);
      final client = _ScriptedClient(['pas du JSON', 'toujours pas']);

      await expectLater(
        generateReadingSet(db: db, client: client, themeFr: 'x'),
        throwsA(isA<LlmException>()),
      );
      expect(client.calls, 2);
      expect(await db.allReadingSets(), isEmpty);
    });
  });
}
