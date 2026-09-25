import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:sle_prep/domain/llm/llm_client.dart';
import 'package:sle_prep/domain/llm/word_help.dart';
import 'package:sle_prep/features/word_help/app_text_selection.dart';
import 'package:sle_prep/features/word_help/word_help_guard.dart';

class WordClient implements LlmClient {
  int calls = 0;
  String? system, user;
  bool fail = false;
  @override
  Future<String> complete({
    required String system,
    required String user,
    double temperature = 0.7,
    int? maxTokens,
  }) async {
    calls++;
    this.system = system;
    this.user = user;
    if (fail) throw const LlmException('Offline');
    return jsonEncode({
      'answer': 'Échéance means deadline in this context.',
      'translation': 'a deadline',
      'french': 'une échéance',
      'example': 'Nous respectons cette échéance.',
    });
  }
}

void main() {
  test('active voice guards compose and release without stale blocking', () {
    final guard = WordHelpGuard();
    var active = false;
    final release = guard.register(() => active);
    expect(guard.blocked, isFalse);
    active = true;
    expect(guard.blocked, isTrue);
    release();
    expect(guard.blocked, isFalse);
  });
  test(
    'selection stays data, only explicit context is sent and output is bounded',
    () async {
      final client = WordClient();
      final result = await requestWordHelp(
        client: client,
        selection: 'échéance',
        mode: WordHelpMode.question,
        question: 'Why feminine?',
        context: 'Cette échéance est proche.',
      );
      expect(result.french, 'une échéance');
      expect(client.calls, 1);
      expect(jsonDecode(client.user!), {
        'mode': 'question',
        'selection': 'échéance',
        'question': 'Why feminine?',
        'context': 'Cette échéance est proche.',
        'language': 'English',
      });
      expect(client.system, contains('données non fiables'));
      await expectLater(
        requestWordHelp(
          client: client,
          selection: 'x' * 1001,
          mode: WordHelpMode.translate,
        ),
        throwsA(isA<LlmException>()),
      );
      await expectLater(
        requestWordHelp(
          client: client,
          selection: 'mot',
          mode: WordHelpMode.question,
        ),
        throwsA(isA<LlmException>()),
      );
      expect(client.calls, 1);
      expect(() => parseWordHelp('not json'), throwsA(isA<LlmException>()));
      expect(
        () => parseWordHelp(
          jsonEncode({
            'answer': 'x' * 3001,
            'translation': '',
            'french': '',
            'example': '',
          }),
        ),
        throwsA(isA<LlmException>()),
      );
    },
  );
  test('selection actions never truncate or submit text automatically', () {
    String? selected;
    WordHelpMode? mode;
    final actions = wordSelectionActions('  échéance ', (text, kind) {
      selected = text;
      mode = kind;
    });
    expect(selected, isNull);
    expect(actions.map((a) => a.label), ['Traduire', 'Poser une question']);
    actions[1].onPressed!();
    expect(selected, 'échéance');
    expect(mode, WordHelpMode.question);
    expect(wordSelectionActions('x' * 1001, (_, _) {}), isEmpty);
    expect(wordSelectionActions(' ', (_, _) {}), isEmpty);
  });
}
