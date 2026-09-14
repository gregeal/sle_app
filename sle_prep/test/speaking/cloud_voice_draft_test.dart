import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sle_prep/data/db/daos.dart';
import 'package:sle_prep/features/speaking/voice_draft.dart';
import 'package:sle_prep/providers.dart';
import '../support/test_db.dart';
import 'speaking_screens_test.dart' show TestSpeech, TestTts;

void main() {
  testWidgets(
    'cloud capture requires opt-in and retains the final editable wording',
    (tester) async {
      final db = inMemoryDatabase();
      addTearDown(db.close);
      final controller = TextEditingController(text: 'Début.');
      addTearDown(controller.dispose);
      final cloud = TestSpeech()
        ..finalTextOnStop = 'Voici ma réponse complète.';
      final device = TestSpeech();
      var cloudCreated = 0;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            speechServiceProvider.overrideWithValue(device),
            ttsServiceProvider.overrideWithValue(TestTts()),
            cloudSpeechFactoryProvider.overrideWithValue(() {
              cloudCreated++;
              return cloud;
            }),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: VoiceDraft(
                  controller: controller,
                  onChanged: (_) {},
                  onBusy: (_) {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      Future<void> chooseCloud() async {
        await tester.tap(find.byType(DropdownButtonFormField<bool>));
        await tester.pumpAndSettle();
        await tester.tap(find.text('OpenAI en direct · recommandé').last);
        await tester.pumpAndSettle();
      }

      await chooseCloud();
      expect(cloudCreated, 0);
      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<DropdownButtonFormField<bool>>(
              find.byType(DropdownButtonFormField<bool>),
            )
            .initialValue,
        isFalse,
      );
      expect(await db.getSetting('speakingDictationEngine'), isNull);
      await chooseCloud();
      await tester.tap(find.text('Activer'));
      await tester.pumpAndSettle();
      expect(cloudCreated, 1);
      expect(cloud.isListening, isFalse);
      expect(await db.getSetting('speakingDictationEngine'), 'openai');
      await tester.ensureVisible(find.byKey(const Key('partner-mic')));
      await tester.tap(find.byKey(const Key('partner-mic')));
      await tester.pumpAndSettle();
      expect(device.isListening, isFalse);
      cloud.result!('Voici ma réponse');
      await tester.pump();
      expect(controller.text, 'Début. Voici ma réponse');
      expect(tester.widget<TextField>(find.byType(TextField)).readOnly, isTrue);
      await tester.tap(find.byKey(const Key('partner-mic')));
      await tester.pumpAndSettle();
      expect(controller.text, 'Début. Voici ma réponse complète.');
      expect(
        tester.widget<TextField>(find.byType(TextField)).readOnly,
        isFalse,
      );
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );
}
