import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sle_prep/data/db/daos.dart';
import 'package:sle_prep/domain/session/session_composer.dart';
import 'package:sle_prep/providers.dart';

import '../support/test_db.dart';

void main() {
  test('fresh-install cards due later today appear in day-one plan', () async {
    final db = inMemoryDatabase();
    addTearDown(db.close);
    final studyDay = DateTime(2026, 7, 13);

    await db.upsertWeek(
      weekNumber: 1,
      themeFr: 'Bienvenue',
      themeEn: 'Welcome',
      grammarTopics: const ['present'],
      vocabDomain: 'travail',
      resourceSlots: const [],
    );
    await db.insertCardWithState(
      front: 'a deadline',
      back: 'une échéance',
      exampleFr: 'Il faut respecter cette échéance.',
      domain: 'travail',
      now: studyDay.add(const Duration(hours: 14)),
    );

    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        studyDayProvider.overrideWithValue(studyDay),
      ],
    );
    addTearDown(container.dispose);

    final plan = await container.read(todayPlanProvider.future);
    expect(
      plan.blocks.map((block) => block.type),
      contains(BlockType.vocabReview),
    );
  });
}
