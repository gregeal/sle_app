import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
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
  testWidgets('course selectable paragraph translates only the touched word', (
    tester,
  ) async {
    const passage = 'Nous préparons une réunion importante demain.';
    final key = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          navigatorKey: key,
          theme: ThemeData(
            pageTransitionsTheme: const LearningPageTransitionsTheme(),
          ),
          home: Scaffold(
            body: ListView(
              children: const [
                SizedBox(height: 100),
                SelectableText(
                  passage,
                  contextMenuBuilder: learningTextContextMenu,
                ),
                Text('Un autre paragraphe.'),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final editable = tester.state<EditableTextState>(find.byType(EditableText));
    final render = editable.renderEditable;
    final start = passage.indexOf('réunion');
    final point = render
        .getLocalRectForCaret(TextPosition(offset: start + 3))
        .center;
    await tester.longPressAt(render.localToGlobal(point));
    await tester.pumpAndSettle();
    expect(editable.textEditingValue.selection.textInside(passage), 'réunion');
    expect(find.text('Traduire'), findsOneWidget);
    await tester.tap(find.text('Traduire'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('word-selection')))
          .controller!
          .text,
      'réunion',
    );
  });
  testWidgets('long press copies only the touched word in a paragraph', (
    tester,
  ) async {
    const passage = 'Nous préparons une réunion importante demain.';
    final key = GlobalKey<NavigatorState>();
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          navigatorKey: key,
          theme: ThemeData(
            pageTransitionsTheme: const LearningPageTransitionsTheme(),
          ),
          home: Scaffold(
            body: ListView(
              children: const [
                SizedBox(height: 100),
                Text(
                  'Ce contenu masqué ne doit jamais être sélectionné.',
                  style: TextStyle(fontSize: 20),
                ),
                Text('Un autre paragraphe qui ne doit pas être copié.'),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    key.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          body: ListView(
            children: const [
              SizedBox(height: 100),
              Text(passage, style: TextStyle(fontSize: 20)),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final paragraph = tester.renderObject<RenderParagraph>(
      find.descendant(of: find.text(passage), matching: find.byType(RichText)),
    );
    final start = passage.indexOf('réunion');
    final boxes = paragraph.getBoxesForSelection(
      TextSelection(baseOffset: start, extentOffset: start + 7),
    );
    await tester.longPressAt(
      paragraph.localToGlobal(boxes.single.toRect().center),
    );
    await tester.pumpAndSettle();
    expect(paragraph.selections, [
      TextSelection(baseOffset: start, extentOffset: start + 7),
    ]);
    await tester.tap(find.text('Copy'));
    await tester.pumpAndSettle();
    expect(copied, 'réunion');

    // The visible selection handles must also let the learner extend a word.
    await tester.longPressAt(
      paragraph.localToGlobal(boxes.single.toRect().center),
    );
    await tester.pumpAndSettle();
    final endHandle = paragraph.localToGlobal(
      boxes.single.toRect().bottomRight,
    );
    final phraseEnd = passage.indexOf(' importante') + ' importante'.length;
    final phraseBoxes = paragraph.getBoxesForSelection(
      TextSelection(baseOffset: start, extentOffset: phraseEnd),
    );
    final drag = await tester.startGesture(endHandle + const Offset(4, 8));
    await drag.moveBy(const Offset(25, 0));
    await tester.pump();
    await drag.moveTo(
      paragraph.localToGlobal(
        phraseBoxes.last.toRect().bottomRight + const Offset(0, 5),
      ),
    );
    await tester.pump();
    await drag.up();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Copy'));
    await tester.pumpAndSettle();
    expect(copied, 'réunion importante');
  });
  testWidgets('hidden tabs cannot contribute to the selected text', (
    tester,
  ) async {
    const passage = 'Une réunion utile.';
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: ThemeData(
            pageTransitionsTheme: const LearningPageTransitionsTheme(),
          ),
          home: Scaffold(
            body: IndexedStack(
              index: 1,
              children: const [
                AppTextSelection(
                  child: Center(child: Text('Un ancien contenu masqué.')),
                ),
                AppTextSelection(child: Center(child: Text(passage))),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final paragraph = tester.renderObject<RenderParagraph>(
      find.descendant(of: find.text(passage), matching: find.byType(RichText)),
    );
    final box = paragraph
        .getBoxesForSelection(
          const TextSelection(baseOffset: 4, extentOffset: 11),
        )
        .single
        .toRect();
    await tester.longPressAt(paragraph.localToGlobal(box.center));
    await tester.pumpAndSettle();
    expect(paragraph.selections, [
      const TextSelection(baseOffset: 4, extentOffset: 11),
    ]);
    await tester.tap(find.text('Traduire'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('word-selection')))
          .controller!
          .text,
      'réunion',
    );
  });
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
            theme: ThemeData(
              pageTransitionsTheme: const LearningPageTransitionsTheme(),
            ),
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
            theme: ThemeData(
              pageTransitionsTheme: const LearningPageTransitionsTheme(),
            ),
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
