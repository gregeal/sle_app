import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sle_prep/data/db/database.dart';
import 'package:sle_prep/domain/speech/speech_services.dart';
import 'package:sle_prep/features/coach/oral_session_screen.dart';
import 'package:sle_prep/providers.dart';

class FakeSpeech implements SpeechService {
  void Function(String)? result;
  void Function()? done;
  int stops = 0;
  @override
  bool isListening = false;
  @override
  Future<bool> initialize() async => true;
  @override
  Future<void> listen({
    required void Function(String) onResult,
    required void Function() onDone,
  }) async {
    isListening = true;
    result = onResult;
    done = onDone;
  }

  @override
  Future<void> stop() async {
    stops++;
    isListening = false;
  }
}

class FakeTts implements TtsService {
  @override
  Future<void> speak(String textFr) async {}
  @override
  Future<void> stop() async {}
}

void main() {
  testWidgets(
    'interrupted answer can be edited and continued without data loss',
    (tester) async {
      final speech = FakeSpeech();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            speechServiceProvider.overrideWithValue(speech),
            ttsServiceProvider.overrideWithValue(FakeTts()),
          ],
          child: const MaterialApp(
            home: OralSessionScreen(
              mode: 'daily',
              questions: [
                OralQuestion(
                  id: 1,
                  tier: 'C',
                  questionFr: 'Pourquoi?',
                  source: 'test',
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.mic).last);
      await tester.pumpAndSettle();
      speech.result!('Première raison.');
      await tester.pump();
      speech.done!();
      await tester.pumpAndSettle();
      expect(find.text('Continuer ma réponse'), findsOneWidget);
      await tester.enterText(
        find.byType(TextFormField),
        'Première raison corrigée.',
      );
      await tester.tap(find.text('Continuer ma réponse'));
      await tester.pumpAndSettle();
      speech.result!('Deuxième raison.');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.stop));
      await tester.pumpAndSettle();
      final editor = tester.widget<TextFormField>(find.byType(TextFormField));
      expect(editor.initialValue, 'Première raison corrigée. Deuxième raison.');
      expect(find.text('Envoyer pour rétroaction'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      expect(speech.isListening, isFalse);
      expect(tester.takeException(), isNull);
    },
  );
}
