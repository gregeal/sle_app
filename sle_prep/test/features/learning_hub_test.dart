import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sle_prep/data/db/daos.dart';
import 'package:sle_prep/data/db/learning_daos.dart';
import 'package:sle_prep/domain/learning/listening_lessons.dart';
import 'package:sle_prep/domain/speech/speech_services.dart';
import 'package:sle_prep/features/learning/learning_hub_screen.dart';
import 'package:sle_prep/features/reading/reading_screen.dart';
import 'package:sle_prep/providers.dart';
import '../support/test_db.dart';

class FakeTts implements TtsService {
  final spoken = <String>[];
  int stops = 0;
  bool fail = false;
  @override
  Future<void> speak(String textFr) async {
    if (fail) throw StateError('Unavailable');
    spoken.add(textFr);
  }

  @override
  Future<void> stop() async {
    stops++;
  }
}

void main() {
  testWidgets(
    'listening hides transcript, plays audio and saves an assisted result separately',
    (tester) async {
      final db = inMemoryDatabase();
      addTearDown(db.close);
      final tts = FakeTts();
      final lesson = listeningLessons.first;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            ttsServiceProvider.overrideWithValue(tts),
          ],
          child: MaterialApp(
            home: ReadingSessionScreen(readingSet: lesson, listeningMode: true),
          ),
        ),
      );
      expect(find.text(lesson.bodyFr), findsNothing);
      await tester.tap(find.text('Écouter'));
      await tester.pumpAndSettle();
      expect(tts.spoken, [lesson.bodyFr]);
      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();
      expect(find.text(lesson.bodyFr), findsOneWidget);
      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('start-questions')));
      await tester.pumpAndSettle();
      expect(tts.stops, greaterThan(0));
      for (final question in lesson.questionsList) {
        final answer = find.text(
          (question['options'] as List)[question['correctIndex'] as int]
              as String,
        );
        await tester.ensureVisible(answer);
        await tester.pumpAndSettle();
        await tester.tap(answer);
        await tester.pumpAndSettle();
        final next = find.byKey(const Key('next-reading-question'));
        await tester.scrollUntilVisible(
          next,
          160,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        await tester.tap(next);
        await tester.pumpAndSettle();
      }
      expect(find.text('Écoute terminée'), findsOneWidget);
      expect(find.text('Entraînement avec transcription.'), findsOneWidget);
      final result = (await db.listeningHistory()).single;
      expect(result.correct, 3);
      expect(result.usedTranscript, isTrue);
      expect(await db.readingHistory(), isEmpty);
      final stops = tts.stops;
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      expect(tts.stops, greaterThan(stops));
    },
  );

  testWidgets(
    'audio failure offers transcript fallback and backgrounding stops playback',
    (tester) async {
      final tts = FakeTts()..fail = true;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [ttsServiceProvider.overrideWithValue(tts)],
          child: MaterialApp(
            home: ReadingSessionScreen(
              readingSet: listeningLessons.first,
              listeningMode: true,
            ),
          ),
        ),
      );
      await tester.tap(find.text('Écouter'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Audio indisponible'), findsOneWidget);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      expect(tts.stops, greaterThan(0));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'notebook searches both languages and creates a due personal card',
    (tester) async {
      final db = inMemoryDatabase();
      addTearDown(db.close);
      await db.insertCardWithState(
        front: 'deadline',
        back: 'échéance',
        exampleFr: '',
        domain: 'seed',
        now: DateTime.now(),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            ttsServiceProvider.overrideWithValue(FakeTts()),
          ],
          child: const MaterialApp(home: VocabularyNotebookScreen()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'DEADLINE');
      await tester.pumpAndSettle();
      expect(find.text('échéance'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'introuvable');
      await tester.pumpAndSettle();
      expect(find.text('échéance'), findsNothing);
      await tester.enterText(find.byType(TextField), '');
      await tester.tap(find.text('Ajouter une expression'));
      await tester.pumpAndSettle();
      final fields = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      );
      await tester.enterText(fields.at(0), 'provided that');
      await tester.enterText(fields.at(1), 'à condition que');
      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();
      expect(find.text('à condition que'), findsOneWidget);
      expect(
        (await db.dueCards(
          DateTime.now(),
        )).any((c) => c.card.back == 'à condition que'),
        isTrue,
      );
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('legacy feedback remains readable without an AI provider', (
    tester,
  ) async {
    final db = inMemoryDatabase();
    addTearDown(db.close);
    await db.insertWritingAttempt(
      promptFr: 'Présentez votre travail.',
      userText: 'Je suis analyste.',
      feedback: 'old-format',
      at: DateTime.now(),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const MaterialApp(home: FeedbackHistoryScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Expression écrite'));
    await tester.pumpAndSettle();
    expect(find.textContaining('format ancien'), findsOneWidget);
    await tester.tap(find.text('Revoir ma réponse originale'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Je suis analyste.'), findsOneWidget);
    expect(find.textContaining('Présentez votre travail.'), findsOneWidget);
  });

  testWidgets(
    'saved writing feedback opens with corrections and no AI configuration',
    (tester) async {
      final db = inMemoryDatabase();
      addTearDown(db.close);
      await db.insertWritingAttempt(
        promptFr: 'Présentez votre poste.',
        userText: 'Je suis analyste.',
        feedback: jsonEncode({
          'levelEstimate': 'B',
          'correctedText': 'Je suis analyste.',
          'errors': [],
          'tips': [
            'Développez votre argument avec un exemple concret.',
            'Variez les connecteurs logiques.',
          ],
        }),
        at: DateTime.now(),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [appDatabaseProvider.overrideWithValue(db)],
          child: const MaterialApp(home: FeedbackHistoryScreen()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Expression écrite'));
      await tester.pumpAndSettle();
      expect(find.text('Texte corrigé'), findsOneWidget);
      expect(find.text('Je suis analyste.'), findsOneWidget);
      final close = find.text('Fermer le rapport');
      await tester.ensureVisible(close);
      await tester.pumpAndSettle();
      await tester.tap(close);
      await tester.pumpAndSettle();
      expect(find.text('Mes rétroactions'), findsOneWidget);
    },
  );
}
