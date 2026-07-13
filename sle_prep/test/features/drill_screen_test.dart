import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sle_prep/data/db/daos.dart';
import 'package:sle_prep/features/drills/drill_screen.dart';
import 'package:sle_prep/providers.dart';

import '../support/test_db.dart';

void main() {
  testWidgets('answering shows feedback and then a summary', (tester) async {
    final db = inMemoryDatabase();
    addTearDown(db.close);
    await db.insertDrillItem(
      topic: 'subjonctif_present',
      prompt: 'Il faut que le rapport ___ prêt.',
      options: const ['est', 'soit', 'sera', 'serait'],
      correctIndex: 1,
      explanationFr: 'Après « il faut que », on emploie le subjonctif.',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const MaterialApp(
          home: DrillScreen(topics: ['subjonctif_present']),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('est'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('drill-explanation')), findsOneWidget);
    expect(find.textContaining('subjonctif'), findsOneWidget);

    final next = find.byKey(const Key('next-drill-question'));
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();
    await tester.tap(next);
    await tester.pumpAndSettle();
    expect(find.text('Exercice terminé'), findsOneWidget);
    expect(find.text('0 bonne réponse sur 1.'), findsOneWidget);
  });
}
