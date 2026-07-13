import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../db/database.dart';

const _seedVersionKey = 'seedVersion';

/// Highest seed version shipped with this build. Content added in later app
/// versions imports incrementally: only the steps above the device's stored
/// version run, so upgrades never duplicate earlier content.
const _targetSeedVersion = 3;

/// Thrown when bundled seed content does not match the app's expected schema.
class SeedContentException implements Exception {
  const SeedContentException(this.message);

  final String message;

  @override
  String toString() => 'SeedContentException: $message';
}

/// Imports the bundled curriculum, vocabulary, and drill data once per seed
/// version. Returns true when content was imported and false when the current
/// seed version is already present.
///
/// The seed version is written only after every row is inserted successfully,
/// so a failed import can be retried safely on the next launch.
Future<bool> importSeedFromAssets(AppDatabase db) async {
  final storedVersion =
      int.tryParse(await _setting(db, _seedVersionKey) ?? '0') ?? 0;
  if (storedVersion >= _targetSeedVersion) {
    return false;
  }

  // Parse everything this upgrade needs before touching the database.
  List<_SeedWeek> curriculum = const [];
  List<_SeedCard> cards = const [];
  List<_SeedDrill> drills = const [];
  List<_SeedReadingSet> readingSets = const [];

  if (storedVersion < 1) {
    curriculum = _parseCurriculum(
      await rootBundle.loadString('assets/seed/curriculum.json'),
    );
    cards = _parseCards(
      await rootBundle.loadString('assets/seed/vocab_core.json'),
    );
    drills = _parseDrills(
      await rootBundle.loadString('assets/seed/drills_core.json'),
    );
  }
  if (storedVersion < 2) {
    readingSets = _parseReadingSets(
      await rootBundle.loadString('assets/seed/reading_core.json'),
    );
  }
  List<_SeedOralQuestion> oralQuestions = const [];
  if (storedVersion < 3) {
    oralQuestions = _parseOralQuestions(
      await rootBundle.loadString('assets/seed/oral_core.json'),
    );
  }

  final now = DateTime.now();

  await db.transaction(() async {
    for (final week in curriculum) {
      await db
          .into(db.curriculumWeeks)
          .insertOnConflictUpdate(
            CurriculumWeeksCompanion.insert(
              weekNumber: Value(week.weekNumber),
              themeFr: week.themeFr,
              themeEn: week.themeEn,
              grammarTopics: jsonEncode(week.grammarTopics),
              vocabDomain: week.vocabDomain,
              resourceSlots: jsonEncode(week.resourceSlots),
            ),
          );
    }

    for (final card in cards) {
      final cardId = await db
          .into(db.vocabCards)
          .insert(
            VocabCardsCompanion.insert(
              front: card.front,
              back: card.back,
              exampleFr: card.exampleFr,
              domain: card.domain,
            ),
          );
      await db
          .into(db.reviewStates)
          .insert(
            ReviewStatesCompanion.insert(cardId: Value(cardId), dueDate: now),
          );
    }

    for (final drill in drills) {
      await db
          .into(db.drillItems)
          .insert(
            DrillItemsCompanion.insert(
              topic: drill.topic,
              prompt: drill.prompt,
              options: jsonEncode(drill.options),
              correctIndex: drill.correctIndex,
              explanationFr: drill.explanationFr,
            ),
          );
    }

    for (final set in readingSets) {
      await db
          .into(db.readingSets)
          .insert(
            ReadingSetsCompanion.insert(
              title: set.title,
              kind: set.kind,
              bodyFr: set.bodyFr,
              questions: jsonEncode(set.questions),
            ),
          );
    }

    for (final question in oralQuestions) {
      await db
          .into(db.oralQuestions)
          .insert(
            OralQuestionsCompanion.insert(
              tier: question.tier,
              questionFr: question.questionFr,
            ),
          );
    }

    await db
        .into(db.appSettings)
        .insertOnConflictUpdate(
          AppSettingsCompanion.insert(
            key: _seedVersionKey,
            value: '$_targetSeedVersion',
          ),
        );
  });

  return true;
}

Future<String?> _setting(AppDatabase db, String key) async {
  final row = await (db.select(
    db.appSettings,
  )..where((setting) => setting.key.equals(key))).getSingleOrNull();
  return row?.value;
}

List<_SeedWeek> _parseCurriculum(String source) {
  final root = _decodeObject(source, 'curriculum.json');
  final weeks = _requiredList(root, 'weeks', 'curriculum.json');
  final seenWeekNumbers = <int>{};

  return weeks
      .asMap()
      .entries
      .map((entry) {
        final context = 'curriculum.json weeks[${entry.key}]';
        final item = _asObject(entry.value, context);
        final weekNumber = _requiredInt(item, 'weekNumber', context);
        if (!seenWeekNumbers.add(weekNumber)) {
          throw SeedContentException(
            '$context has duplicate weekNumber $weekNumber',
          );
        }

        return _SeedWeek(
          weekNumber: weekNumber,
          themeFr: _requiredString(item, 'themeFr', context),
          themeEn: _requiredString(item, 'themeEn', context),
          grammarTopics: _requiredList(item, 'grammarTopics', context)
              .map(
                (topic) => _asNonEmptyString(topic, '$context grammarTopics'),
              )
              .toList(growable: false),
          vocabDomain: _requiredString(item, 'vocabDomain', context),
          resourceSlots: _requiredList(item, 'resourceSlots', context)
              .asMap()
              .entries
              .map((resource) {
                final resourceContext =
                    '$context resourceSlots[${resource.key}]';
                final value = _asObject(resource.value, resourceContext);
                return <String, dynamic>{
                  'label': _requiredString(value, 'label', resourceContext),
                  'url': _requiredString(value, 'url', resourceContext),
                };
              })
              .toList(growable: false),
        );
      })
      .toList(growable: false);
}

List<_SeedCard> _parseCards(String source) {
  final root = _decodeObject(source, 'vocab_core.json');
  final cards = _requiredList(root, 'cards', 'vocab_core.json');
  final seenFronts = <String>{};

  return cards
      .asMap()
      .entries
      .map((entry) {
        final context = 'vocab_core.json cards[${entry.key}]';
        final item = _asObject(entry.value, context);
        final front = _requiredString(item, 'front', context);
        if (!seenFronts.add(front)) {
          throw SeedContentException('$context has duplicate front "$front"');
        }
        return _SeedCard(
          front: front,
          back: _requiredString(item, 'back', context),
          exampleFr: _requiredString(item, 'exampleFr', context),
          domain: _requiredString(item, 'domain', context),
        );
      })
      .toList(growable: false);
}

List<_SeedDrill> _parseDrills(String source) {
  final root = _decodeObject(source, 'drills_core.json');
  final drills = _requiredList(root, 'items', 'drills_core.json');

  return drills
      .asMap()
      .entries
      .map((entry) {
        final context = 'drills_core.json items[${entry.key}]';
        final item = _asObject(entry.value, context);
        final options = _requiredList(item, 'options', context)
            .map((option) => _asNonEmptyString(option, '$context options'))
            .toList(growable: false);
        final correctIndex = _requiredInt(item, 'correctIndex', context);
        if (options.length != 4) {
          throw SeedContentException(
            '$context options must contain exactly four values',
          );
        }
        if (options.toSet().length != options.length) {
          throw SeedContentException('$context options must be unique');
        }
        if (correctIndex < 0 || correctIndex >= options.length) {
          throw SeedContentException(
            '$context correctIndex is outside the options',
          );
        }

        return _SeedDrill(
          topic: _requiredString(item, 'topic', context),
          prompt: _requiredString(item, 'prompt', context),
          options: options,
          correctIndex: correctIndex,
          explanationFr: _requiredString(item, 'explanationFr', context),
        );
      })
      .toList(growable: false);
}

List<_SeedReadingSet> _parseReadingSets(String source) {
  final root = _decodeObject(source, 'reading_core.json');
  final sets = _requiredList(root, 'sets', 'reading_core.json');

  return sets
      .asMap()
      .entries
      .map((entry) {
        final context = 'reading_core.json sets[${entry.key}]';
        final item = _asObject(entry.value, context);
        final questions = _requiredList(item, 'questions', context)
            .asMap()
            .entries
            .map((question) {
              final questionContext = '$context questions[${question.key}]';
              final value = _asObject(question.value, questionContext);
              final options = _requiredList(value, 'options', questionContext)
                  .map(
                    (option) =>
                        _asNonEmptyString(option, '$questionContext options'),
                  )
                  .toList(growable: false);
              final correctIndex = _requiredInt(
                value,
                'correctIndex',
                questionContext,
              );
              if (options.length != 4) {
                throw SeedContentException(
                  '$questionContext options must contain exactly four values',
                );
              }
              if (options.toSet().length != options.length) {
                throw SeedContentException(
                  '$questionContext options must be unique',
                );
              }
              if (correctIndex < 0 || correctIndex >= options.length) {
                throw SeedContentException(
                  '$questionContext correctIndex is outside the options',
                );
              }
              return <String, dynamic>{
                'prompt': _requiredString(value, 'prompt', questionContext),
                'options': options,
                'correctIndex': correctIndex,
                'explanationFr': _requiredString(
                  value,
                  'explanationFr',
                  questionContext,
                ),
              };
            })
            .toList(growable: false);
        if (questions.isEmpty) {
          throw SeedContentException(
            '$context must contain at least one question',
          );
        }

        return _SeedReadingSet(
          title: _requiredString(item, 'title', context),
          kind: _requiredString(item, 'kind', context),
          bodyFr: _requiredString(item, 'bodyFr', context),
          questions: questions,
        );
      })
      .toList(growable: false);
}

const _oralTiers = {'A', 'B', 'C'};

List<_SeedOralQuestion> _parseOralQuestions(String source) {
  final root = _decodeObject(source, 'oral_core.json');
  final questions = _requiredList(root, 'questions', 'oral_core.json');

  return questions
      .asMap()
      .entries
      .map((entry) {
        final context = 'oral_core.json questions[${entry.key}]';
        final item = _asObject(entry.value, context);
        final tier = _requiredString(item, 'tier', context);
        if (!_oralTiers.contains(tier)) {
          throw SeedContentException('$context tier must be A, B or C');
        }
        return _SeedOralQuestion(
          tier: tier,
          questionFr: _requiredString(item, 'questionFr', context),
        );
      })
      .toList(growable: false);
}

Map<String, dynamic> _decodeObject(String source, String name) {
  try {
    return _asObject(jsonDecode(source), name);
  } on FormatException catch (error) {
    throw SeedContentException('$name is not valid JSON: ${error.message}');
  }
}

Map<String, dynamic> _asObject(Object? value, String context) {
  if (value is! Map) {
    throw SeedContentException('$context must be an object');
  }
  return value.map((key, value) {
    if (key is! String) {
      throw SeedContentException('$context has a non-string key');
    }
    return MapEntry(key, value);
  });
}

List<Object?> _requiredList(
  Map<String, dynamic> item,
  String key,
  String context,
) {
  final value = item[key];
  if (value is! List) {
    throw SeedContentException('$context.$key must be a list');
  }
  return value;
}

String _requiredString(Map<String, dynamic> item, String key, String context) =>
    _asNonEmptyString(item[key], '$context.$key');

String _asNonEmptyString(Object? value, String context) {
  if (value is! String || value.trim().isEmpty) {
    throw SeedContentException('$context must be a non-empty string');
  }
  return value;
}

int _requiredInt(Map<String, dynamic> item, String key, String context) {
  final value = item[key];
  if (value is! int) {
    throw SeedContentException('$context.$key must be an integer');
  }
  return value;
}

class _SeedWeek {
  const _SeedWeek({
    required this.weekNumber,
    required this.themeFr,
    required this.themeEn,
    required this.grammarTopics,
    required this.vocabDomain,
    required this.resourceSlots,
  });

  final int weekNumber;
  final String themeFr;
  final String themeEn;
  final List<String> grammarTopics;
  final String vocabDomain;
  final List<Map<String, dynamic>> resourceSlots;
}

class _SeedReadingSet {
  const _SeedReadingSet({
    required this.title,
    required this.kind,
    required this.bodyFr,
    required this.questions,
  });

  final String title;
  final String kind;
  final String bodyFr;
  final List<Map<String, dynamic>> questions;
}

class _SeedOralQuestion {
  const _SeedOralQuestion({required this.tier, required this.questionFr});

  final String tier;
  final String questionFr;
}

class _SeedCard {
  const _SeedCard({
    required this.front,
    required this.back,
    required this.exampleFr,
    required this.domain,
  });

  final String front;
  final String back;
  final String exampleFr;
  final String domain;
}

class _SeedDrill {
  const _SeedDrill({
    required this.topic,
    required this.prompt,
    required this.options,
    required this.correctIndex,
    required this.explanationFr,
  });

  final String topic;
  final String prompt;
  final List<String> options;
  final int correctIndex;
  final String explanationFr;
}
