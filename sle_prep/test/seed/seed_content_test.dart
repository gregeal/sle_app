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
