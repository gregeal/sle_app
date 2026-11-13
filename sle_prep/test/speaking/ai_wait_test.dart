import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sle_prep/data/db/database.dart';
import 'package:sle_prep/data/db/speaking_daos.dart';
import 'package:sle_prep/domain/llm/llm_client.dart';
import 'package:sle_prep/features/speaking/speaking_session_screen.dart';
import 'package:sle_prep/providers.dart';

import '../support/test_db.dart';
import 'speaking_partner_test.dart' show learnerAnswer, validFeedback;
import 'speaking_screens_test.dart' show TestSpeech, TestTts;

/// A provider that never answers until the test says so: the situation in
/// which the screen used to look frozen.
class SlowClient implements LlmClient {
  final pending = <Completer<String>>[];

  @override
  Future<String> complete({
    required String system,
    required String user,
    double temperature = 0.7,
    int? maxTokens,
  }) {
    final completer = Completer<String>();
    pending.add(completer);
    return completer.future;
  }
}

Future<(AppDatabase, int, SlowClient)> open(WidgetTester tester) async {
  tester.view.physicalSize = const Size(800, 2600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final db = inMemoryDatabase();
  addTearDown(db.close);
  final id = await db.createSpeakingSession(
    topic: 'Travail',
    prompt: 'Pourquoi ?',
    now: DateTime.now(),
  );
  final client = SlowClient();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        llmClientProvider.overrideWith((ref) async => client),
        speechServiceProvider.overrideWithValue(TestSpeech()),
        ttsServiceProvider.overrideWithValue(TestTts()),
      ],
      child: MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => SpeakingSessionScreen(sessionId: id),
                  ),
                ),
                child: const Text('ouvrir'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('ouvrir'));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextField).first, learnerAnswer);
  await tester.pump(const Duration(milliseconds: 600));
  await tester.tap(find.byKey(const Key('partner-submit')));
  // The progress bar animates for as long as the wait lasts, so the frames
  // are advanced by hand instead of waiting for the screen to settle.
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(milliseconds: 300));
  expect(client.pending, hasLength(1));
  return (db, id, client);
}

Future<void> close(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  testWidgets('a slow partner can be cancelled and the text is kept', (
    tester,
  ) async {
    final (db, id, client) = await open(tester);
    expect(find.byKey(const Key('partner-cancel')), findsOneWidget);
    expect(find.textContaining('jusqu’à une minute'), findsOneWidget);

    await tester.tap(find.byKey(const Key('partner-cancel')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const Key('partner-cancel')), findsNothing);
    expect(find.textContaining('Attente annulée'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField).first).controller!.text,
      learnerAnswer,
    );

    // The abandoned answer arrives anyway. It must not be saved as a turn
    // the learner never saw.
    client.pending.single.complete(validFeedback.toJson());
    await tester.pump(const Duration(milliseconds: 300));
    expect(await db.speakingHistory(id), isEmpty);

    // And the learner can simply send again.
    await tester.tap(find.byKey(const Key('partner-submit')));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
    expect(client.pending, hasLength(2));
    client.pending.last.complete(validFeedback.toJson());
    await tester.pumpAndSettle();
    expect(await db.speakingHistory(id), hasLength(1));
    await close(tester);
  });

  testWidgets('the back button works while the partner is still thinking', (
    tester,
  ) async {
    final (db, id, client) = await open(tester);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(SpeakingSessionScreen), findsNothing);
    expect(find.text('ouvrir'), findsOneWidget);
    expect(
      (await db.speakingSession(id)).draft,
      learnerAnswer,
      reason: 'leaving keeps the unsent text',
    );

    client.pending.single.complete(validFeedback.toJson());
    await tester.pump(const Duration(milliseconds: 300));
    expect(await db.speakingHistory(id), isEmpty);
    expect(tester.takeException(), isNull);
    await close(tester);
  });

  testWidgets('a partner that never answers gives the screen back', (
    tester,
  ) async {
    final (db, id, _) = await open(tester);

    await tester.pump(aiPatience + const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.textContaining('met trop de temps'), findsOneWidget);
    expect(find.byKey(const Key('partner-cancel')), findsNothing);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('partner-submit')))
          .onPressed,
      isNotNull,
      reason: 'the learner can try again',
    );
    expect(await db.speakingHistory(id), isEmpty);
    await close(tester);
  });
}
