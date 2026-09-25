import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'word_help_guard.dart';
import '../../domain/llm/word_help.dart';
import 'word_help_screen.dart';

/// Gives each route its own selection surface while retaining native transitions.
/// A selection area above Navigator also sees retained, hidden routes and can
/// select their text instead of the word under the user's finger.
class LearningPageTransitionsTheme extends PageTransitionsTheme {
  const LearningPageTransitionsTheme();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => super.buildTransitions(
    route,
    context,
    animation,
    secondaryAnimation,
    AppTextSelection(child: child),
  );
}

/// Selection is local to a route or tab, never shared across hidden pages.
class AppTextSelection extends StatefulWidget {
  const AppTextSelection({super.key, required this.child});
  final Widget child;
  @override
  State<AppTextSelection> createState() => _AppTextSelectionState();
}

class _AppTextSelectionState extends State<AppTextSelection> {
  String _selected = '';
  @override
  Widget build(BuildContext context) => SelectionArea(
    onSelectionChanged: (content) => _selected = content?.plainText ?? '',
    contextMenuBuilder: (context, state) =>
        AdaptiveTextSelectionToolbar.buttonItems(
          anchors: state.contextMenuAnchors,
          buttonItems: [
            ...state.contextMenuButtonItems,
            ...wordSelectionActions(
              _helpAllowed(this.context) ? _selected : '',
              (text, mode) {
                ContextMenuController.removeAny();
                if (!mounted || !_helpAllowed(this.context)) return;
                state.clearSelection();
                Navigator.of(this.context).push(
                  MaterialPageRoute(
                    builder: (_) => WordHelpScreen(selection: text, mode: mode),
                  ),
                );
              },
            ),
          ],
        ),
    child: widget.child,
  );
}

List<ContextMenuButtonItem> wordSelectionActions(
  String text,
  void Function(String text, WordHelpMode mode) open,
) {
  final selection = text.trim();
  if (selection.isEmpty || selection.length > 1000) return const [];
  return [
    ContextMenuButtonItem(
      label: 'Traduire',
      onPressed: () => open(selection, WordHelpMode.translate),
    ),
    ContextMenuButtonItem(
      label: 'Poser une question',
      onPressed: () => open(selection, WordHelpMode.question),
    ),
  ];
}

Widget learningTextContextMenu(BuildContext context, EditableTextState state) {
  // The menu context belongs to an overlay and may sit above Navigator.
  // Resolve navigation and provider state from the originating text widget.
  final sourceContext = state.context;
  final value = state.textEditingValue;
  final selection = value.selection;
  final selected =
      !state.widget.obscureText &&
          selection.isValid &&
          selection.start >= 0 &&
          selection.end <= value.text.length
      ? selection.textInside(value.text)
      : '';
  return AdaptiveTextSelectionToolbar.buttonItems(
    anchors: state.contextMenuAnchors,
    buttonItems: [
      ...state.contextMenuButtonItems,
      ...wordSelectionActions(_helpAllowed(sourceContext) ? selected : '', (
        text,
        mode,
      ) {
        if (!state.mounted || !_helpAllowed(sourceContext)) return;
        state.hideToolbar();
        Navigator.of(sourceContext).push(
          MaterialPageRoute(
            builder: (_) => WordHelpScreen(selection: text, mode: mode),
          ),
        );
      }),
    ],
  );
}

bool _helpAllowed(BuildContext context) => !ProviderScope.containerOf(
  context,
  listen: false,
).read(wordHelpGuardProvider).blocked;
