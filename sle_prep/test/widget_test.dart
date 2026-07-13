import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sle_prep/data/db/daos.dart';
import 'package:sle_prep/features/vocab/vocab_review_screen.dart';
import 'package:sle_prep/providers.dart';

import 'support/test_db.dart';

void main() {
  testWidgets('grading advances to the next vocabulary card', (tester) async {
    final db = inMemoryDatabase();
    addTearDown(db.close);
    final now = DateTime.now();
    await db.insertCardWithState(
      front: 'a deadline',
      back: 'une échéance',
      exampleFr: 'Il faut respecter cette échéance.',
      domain: 'gestion_projet',
      now: now,
    );
    await db.insertCardWithState(
      front: 'a meeting',
      back: 'une réunion',
      exampleFr: 'La réunion commence à neuf heures.',
      domain: 'reunions',
      now: now,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const MaterialApp(home: VocabReviewScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('a deadline'), findsOneWidget);
    await tester.tap(find.byKey(const Key('vocab-card')));
    await tester.pumpAndSettle();
    expect(find.text('une échéance'), findsOneWidget);

    await tester.tap(find.text('Bien'));
    await tester.pumpAndSettle();

    expect(find.text('a meeting'), findsOneWidget);
  });

  testWidgets('an empty queue shows the review summary', (tester) async {
    final db = inMemoryDatabase();
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const MaterialApp(home: VocabReviewScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Aucune carte à revoir'), findsOneWidget);
  });
}
