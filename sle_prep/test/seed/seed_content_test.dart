import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sle_prep/data/db/daos.dart';
import 'package:sle_prep/data/seed/seed_loader.dart';

import '../support/test_db.dart';

Future<Map<String, dynamic>> loadAsset(String name) async =>
    jsonDecode(await rootBundle.loadString('assets/seed/$name'))
        as Map<String, dynamic>;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Map<String, dynamic> curriculum;
  late Map<String, dynamic> vocab;
  late Map<String, dynamic> drills;

  setUpAll(() async {
    curriculum = await loadAsset('curriculum.json');
    vocab = await loadAsset('vocab_core.json');
    drills = await loadAsset('drills_core.json');
  });

  group('curriculum.json', () {
    test('has 26 uniquely numbered weeks with required fields', () {
      final weeks = (curriculum['weeks'] as List).cast<Map<String, dynamic>>();
      expect(weeks, hasLength(26));
      expect(weeks.map((w) => w['weekNumber']).toSet(),
          Set.of(List.generate(26, (i) => i + 1)));
      for (final w in weeks) {
        expect(w['themeFr'], isNotEmpty);
        expect(w['themeEn'], isNotEmpty);
        expect(w['grammarTopics'], isNotEmpty);
        expect(w['vocabDomain'], isNotEmpty);
        expect(w['resourceSlots'], isA<List<dynamic>>());
      }
    });
  });

  group('vocab_core.json', () {
    test('has at least 250 cards with required fields and no duplicates', () {
      final cards = (vocab['cards'] as List).cast<Map<String, dynamic>>();
      expect(cards.length, greaterThanOrEqualTo(250));
      final fronts = <String>{};
      for (final c in cards) {
        expect(c['front'], isNotEmpty);
        expect(c['back'], isNotEmpty);
        expect(c['exampleFr'], isNotEmpty);
        expect(c['domain'], isNotEmpty);
        expect(fronts.add(c['front'] as String), isTrue,
            reason: 'duplicate front: ${c['front']}');
      }
    });

    test('every card domain is used by some curriculum week', () {
      final weekDomains = (curriculum['weeks'] as List)
          .map((w) => (w as Map<String, dynamic>)['vocabDomain'] as String)
          .toSet();
      // Cross-cutting domains reviewed continuously rather than tied to one week.
      const standingDomains = {'connecteurs'};
      final cards = (vocab['cards'] as List).cast<Map<String, dynamic>>();
      for (final c in cards) {
        final domain = c['domain'] as String;
        expect(
          weekDomains.contains(domain) || standingDomains.contains(domain),
          isTrue,
          reason: 'card "${c['front']}" has unscheduled domain $domain',
        );
      }
    });
  });

  group('drills_core.json', () {
    test('has at least 80 well-formed items', () {
      final items = (drills['items'] as List).cast<Map<String, dynamic>>();
      expect(items.length, greaterThanOrEqualTo(80));
      for (final item in items) {
        expect(item['topic'], isNotEmpty);
        expect(item['prompt'], isNotEmpty);
        final options = (item['options'] as List).cast<String>();
        expect(options, hasLength(4), reason: 'item: ${item['prompt']}');
        expect(options.toSet(), hasLength(4),
            reason: 'duplicate options in: ${item['prompt']}');
        final correct = item['correctIndex'] as int;
        expect(correct, inInclusiveRange(0, 3));
        expect(item['explanationFr'], isNotEmpty);
      }
    });

    test('every drill topic is scheduled in some curriculum week', () {
      final weekTopics = (curriculum['weeks'] as List)
          .expand((w) =>
              ((w as Map<String, dynamic>)['grammarTopics'] as List)
                  .cast<String>())
          .toSet();
      final items = (drills['items'] as List).cast<Map<String, dynamic>>();
      for (final item in items) {
        expect(weekTopics, contains(item['topic']),
            reason: 'unscheduled drill topic: ${item['topic']}');
      }
    });
  });

  group('reading_core.json', () {
    test('has at least 3 well-formed reading sets', () async {
      final reading = await loadAsset('reading_core.json');
      final sets = (reading['sets'] as List).cast<Map<String, dynamic>>();
      expect(sets.length, greaterThanOrEqualTo(3));
      for (final set in sets) {
        expect(set['title'], isNotEmpty);
        expect(set['kind'], isNotEmpty);
        expect((set['bodyFr'] as String).length, greaterThan(200),
            reason: 'passages should be substantial');
        final questions =
            (set['questions'] as List).cast<Map<String, dynamic>>();
        expect(questions.length, greaterThanOrEqualTo(4));
        for (final question in questions) {
          expect(question['prompt'], isNotEmpty);
          final options = (question['options'] as List).cast<String>();
          expect(options, hasLength(4));
          expect(options.toSet(), hasLength(4));
          expect(question['correctIndex'] as int, inInclusiveRange(0, 3));
          expect(question['explanationFr'], isNotEmpty);
        }
      }
    });
  });

  group('seed loader upgrade', () {
    test('v1 devices gain reading sets without duplicating v1 content',
        () async {
      final db = inMemoryDatabase();
      addTearDown(db.close);

      // Simulate a device that already imported seed v1.
      await db.setSetting('seedVersion', '1');
      await db.insertCardWithState(
        front: 'pre-existing card',
        back: 'x',
        exampleFr: 'x',
        domain: 'x',
        now: DateTime(2026),
      );

      final ran = await importSeedFromAssets(db);
      expect(ran, isTrue);

      expect(await db.dueCardCount(DateTime(2030)), 1,
          reason: 'vocab must not be re-imported');
      expect(await db.allReadingSets(), isNotEmpty,
          reason: 'reading sets are the v2 content');
      expect(await db.getSetting('seedVersion'), '2');
    });
  });

  group('seed loader', () {
    test('imports all content once and is idempotent across calls', () async {
      final db = inMemoryDatabase();
      addTearDown(db.close);

      final first = await importSeedFromAssets(db);
      expect(first, isTrue, reason: 'first import should run');

      final cards = (vocab['cards'] as List).length;
      final items = (drills['items'] as List).length;
      expect(await db.dueCardCount(DateTime(2030)), cards);
      expect((await db.randomDrillItems(_allTopics(drills), 10000)).length,
          items);
      expect((await db.weekByNumber(8))?.themeFr, isNotEmpty);

      final second = await importSeedFromAssets(db);
      expect(second, isFalse, reason: 'same version should be skipped');
      expect(await db.dueCardCount(DateTime(2030)), cards,
          reason: 'no duplicate cards after re-import');
    });
  });
}

List<String> _allTopics(Map<String, dynamic> drills) =>
    (drills['items'] as List)
        .map((i) => (i as Map<String, dynamic>)['topic'] as String)
        .toSet()
        .toList();
