import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'word_help_guard.dart';
import '../../domain/llm/word_help.dart';
import 'word_help_screen.dart';

/// One selection surface covers normal rendered text on app routes. Editable
/// and explicitly selectable text use the shared builder below instead.
class AppTextSelection extends StatefulWidget {
  const AppTextSelection({
    super.key,
    required this.child,
    required this.navigatorKey,
  });
  final Widget child;
  final GlobalKey<NavigatorState> navigatorKey;
  @override
  State<AppTextSelection> createState() => _AppTextSelectionState();
}

class _AppTextSelectionState extends State<AppTextSelection> {
  String _selected = '';
  @override
  Widget build(BuildContext context) => Overlay.wrap(
    child: SelectionArea(
      onSelectionChanged: (content) => _selected = content?.plainText ?? '',
      contextMenuBuilder: (context, state) =>
          AdaptiveTextSelectionToolbar.buttonItems(
            anchors: state.contextMenuAnchors,
            buttonItems: [
              ...state.contextMenuButtonItems,
              ...wordSelectionActions(_helpAllowed(context) ? _selected : '', (
                text,
                mode,
              ) {
                ContextMenuController.removeAny();
                if (!_helpAllowed(context)) return;
                state.clearSelection();
                widget.navigatorKey.currentState?.push(
                  MaterialPageRoute(
                    builder: (_) => WordHelpScreen(selection: text, mode: mode),
                  ),
                );
              }),
            ],
          ),
      child: widget.child,
    ),
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
      ...wordSelectionActions(_helpAllowed(context) ? selected : '', (
        text,
        mode,
      ) {
        state.hideToolbar();
        if (!_helpAllowed(context)) return;
        Navigator.of(context).push(
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
