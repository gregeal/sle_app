import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sle_prep/data/db/daos.dart';
import 'package:sle_prep/domain/llm/drill_generator.dart';
import 'package:sle_prep/domain/llm/llm_client.dart';

import '../support/test_db.dart';

class _ScriptedClient implements LlmClient {
  _ScriptedClient(this.responses);

  final List<String> responses;
  final prompts = <String>[];

  @override
  Future<String> complete({
    required String system,
    required String user,
    double temperature = 0.7,
    int? maxTokens,
  }) async {
    prompts.add(user);
    if (responses.isEmpty) throw StateError('no scripted response left');
    return responses.removeAt(0);
  }
}

String _payload(List<Map<String, dynamic>> items) =>
    jsonEncode({'items': items});

Map<String, dynamic> _validItem({String topic = 'subjonctif_present'}) => {
      'topic': topic,
      'prompt': 'Il faut que nous ___ la directive.',
      'options': ['respectons', 'respections', 'respecterons', 'respectiez'],
      'correctIndex': 1,
      'explanationFr': 'Il faut que + subjonctif.',
    };

void main() {
  group('parseGeneratedDrills', () {
    test('accepts well-formed items for allowed topics', () {
      final drills = parseGeneratedDrills(
        _payload([_validItem()]),
        allowedTopics: {'subjonctif_present'},
      );
      expect(drills, hasLength(1));
      expect(drills.single.topic, 'subjonctif_present');
      expect(drills.single.correctIndex, 1);
    });

    test('strips markdown code fences around the JSON', () {
      final raw = '```json\n${_payload([_validItem()])}\n```';
      expect(
        parseGeneratedDrills(raw, allowedTopics: {'subjonctif_present'}),
        hasLength(1),
      );
    });

    test('silently drops malformed or off-topic items', () {
      final drills = parseGeneratedDrills(
        _payload([
          _validItem(),
          _validItem(topic: 'sujet_inconnu'),
          {..._validItem(), 'correctIndex': 9},
          {
            ..._validItem(),
            'options': ['a', 'a', 'b', 'c'],
          },
          {..._validItem(), 'options': <String>['seulement', 'trois', 'choix']},
        ]),
        allowedTopics: {'subjonctif_present'},
      );
      expect(drills, hasLength(1));
    });

    test('throws LlmException when the payload is not JSON at all', () {
      expect(
        () => parseGeneratedDrills('Je ne peux pas produire de JSON.',
            allowedTopics: {'x'}),
        throwsA(isA<LlmException>()),
      );
    });
  });

  group('generateDrills', () {
    test('inserts valid items with source=generated and returns the count',
        () async {
      final db = inMemoryDatabase();
      addTearDown(db.close);
      final client = _ScriptedClient([
        _payload([
          _validItem(),
          {..._validItem(), 'prompt': 'Bien que le délai ___ serré…'},
        ]),
      ]);

      final inserted = await generateDrills(
        db: db,
        client: client,
        topics: const ['subjonctif_present'],
        count: 2,
      );

      expect(inserted, 2);
      final stored = await db.randomDrillItems(['subjonctif_present'], 10);
      expect(stored, hasLength(2));
      expect(stored.every((item) => item.source == 'generated'), isTrue);
      expect(client.prompts.single, contains('subjonctif_present'));
    });

    test('retries once when the first reply has no usable item', () async {
      final db = inMemoryDatabase();
      addTearDown(db.close);
      final client = _ScriptedClient([
        _payload([_validItem(topic: 'hors_sujet')]),
        _payload([_validItem()]),
      ]);

      final inserted = await generateDrills(
        db: db,
        client: client,
        topics: const ['subjonctif_present'],
        count: 1,
      );

      expect(inserted, 1);
      expect(client.prompts, hasLength(2));
    });

    test('throws LlmException when both attempts produce nothing usable',
        () async {
      final db = inMemoryDatabase();
      addTearDown(db.close);
      final client = _ScriptedClient([
        _payload([]),
        _payload([]),
      ]);

      await expectLater(
        generateDrills(
          db: db,
          client: client,
          topics: const ['subjonctif_present'],
          count: 5,
        ),
        throwsA(isA<LlmException>()),
      );
    });
  });
}
