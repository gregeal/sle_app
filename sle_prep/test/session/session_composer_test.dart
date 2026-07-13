import 'package:flutter_test/flutter_test.dart';
import 'package:sle_prep/domain/session/session_composer.dart';

void main() {
  const topics = ['subjonctif_present', 'verbes_volonte'];
  const resources = [
    SessionResource(label: 'Mauril', url: 'https://mauril.ca'),
  ];

  test('composes a session close to the requested duration', () {
    final blocks = composeSession(
      dueCardCount: 20,
      grammarTopics: topics,
      topicAccuracy: const {'subjonctif_present': 0.4},
      resources: resources,
      targetMinutes: 75,
    );

    expect(blocks.fold(0, (total, block) => total + block.minutes), 75);
    expect(blocks.map((block) => block.type), contains(BlockType.resource));
  });

  test('omits vocabulary when there are no due cards', () {
    final blocks = composeSession(
      dueCardCount: 0,
      grammarTopics: topics,
      topicAccuracy: const {},
      resources: resources,
      targetMinutes: 60,
    );

    expect(
      blocks.map((block) => block.type),
      isNot(contains(BlockType.vocabReview)),
    );
    expect(blocks.fold(0, (total, block) => total + block.minutes), 60);
  });

  test('puts the weakest grammar topic first', () {
    final blocks = composeSession(
      dueCardCount: 5,
      grammarTopics: topics,
      topicAccuracy: const {'subjonctif_present': 0.9, 'verbes_volonte': 0.3},
      resources: resources,
      targetMinutes: 60,
    );

    final grammar = blocks.firstWhere(
      (block) => block.id == 'grammarDrillPrimary',
    );
    expect(grammar.grammarTopics.first, 'verbes_volonte');
  });
}
