import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sle_prep/data/db/learning_daos.dart';
import 'package:sle_prep/features/word_help/app_text_selection.dart';
import 'package:sle_prep/features/word_help/word_help_screen.dart';
import 'package:sle_prep/features/word_help/word_help_guard.dart';
import 'package:sle_prep/providers.dart';
import '../support/test_db.dart';
import 'word_help_test.dart' show WordClient;

void main() {
  testWidgets(
    'a voice session starting after selection blocks helper navigation',
    (tester) async {
      final key = GlobalKey<NavigatorState>();
      final guard = WordHelpGuard();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [wordHelpGuardProvider.overrideWithValue(guard)],
          child: MaterialApp(
            navigatorKey: key,
            builder: (context, child) =>
                AppTextSelection(navigatorKey: key, child: child!),
            home: const Scaffold(body: Center(child: Text('échéance'))),
          ),
        ),
      );
      await tester.longPress(find.text('échéance'));
      await tester.pumpAndSettle();
      final release = guard.register(() => true);
      await tester.tap(find.text('Traduire'));
      await tester.pumpAndSettle();
      expect(find.byType(WordHelpScreen), findsNothing);
      release();
    },
  );
  testWidgets(
    'normal app text supports selection and opening help without an AI call',
    (tester) async {
      final key = GlobalKey<NavigatorState>();
      final client = WordClient();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [llmClientProvider.overrideWith((ref) async => client)],
          child: MaterialApp(
            navigatorKey: key,
            builder: (context, child) =>
                AppTextSelection(navigatorKey: key, child: child!),
            home: const Scaffold(body: Center(child: Text('échéance'))),
          ),
        ),
      );
      await tester.longPress(find.text('échéance'));
      await tester.pumpAndSettle();
      expect(find.text('Traduire'), findsOneWidget);
      expect(find.text('Poser une question'), findsOneWidget);
      await tester.tap(find.text('Traduire'));
      await tester.pumpAndSettle();
      expect(find.byType(WordHelpScreen), findsOneWidget);
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('word-selection')))
            .controller!
            .text,
        'échéance',
      );
      expect(client.calls, 0);
    },
  );

  testWidgets(
    'helper sends only on demand, retains errors, and saves a reviewed vocabulary card',
    (tester) async {
      final db = inMemoryDatabase();
      addTearDown(db.close);
      final client = WordClient();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            llmClientProvider.overrideWith((ref) async => client),
          ],
          child: const MaterialApp(home: WordHelpScreen(selection: 'échéance')),
        ),
      );
      await tester.pumpAndSettle();
      expect(client.calls, 0);
      Future<void> tap(Finder finder) async {
        await tester.scrollUntilVisible(
          finder,
          300,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        await tester.ensureVisible(finder);
        await tester.pumpAndSettle();
        await tester.tap(finder);
        await tester.pumpAndSettle();
      }

      client.fail = true;
      await tap(find.byKey(const Key('word-send')));
      expect(find.text('Offline'), findsOneWidget);
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('word-selection')))
            .controller!
            .text,
        'échéance',
      );
      client.fail = false;
      await tap(find.byKey(const Key('word-send')));
      expect(client.calls, 2);
      await tap(find.text('Garder dans mon vocabulaire à réviser'));
      await tap(find.byKey(const Key('word-save')));
      expect((await db.vocabularyLibrary()).single.back, 'une échéance');
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('word-save')))
            .onPressed,
        isNull,
      );
    },
  );

  testWidgets(
    'editable study text has helper actions but obscured text does not',
    (tester) async {
      final controller = TextEditingController(text: 'une échéance');
      addTearDown(controller.dispose);
      Future<void> show(bool obscure) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: TextField(
                  controller: controller,
                  obscureText: obscure,
                  contextMenuBuilder: learningTextContextMenu,
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.byType(TextField));
        controller.selection = TextSelection(
          baseOffset: 4,
          extentOffset: controller.text.length,
        );
        await tester.pump();
        tester
            .state<EditableTextState>(find.byType(EditableText))
            .showToolbar();
        await tester.pumpAndSettle();
      }

      await show(false);
      expect(find.text('Traduire'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      await show(true);
      expect(find.text('Traduire'), findsNothing);
    },
  );
}
