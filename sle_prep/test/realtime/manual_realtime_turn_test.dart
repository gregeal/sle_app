import 'package:flutter_test/flutter_test.dart';
import 'package:sle_prep/domain/realtime/manual_realtime_turn.dart';
import 'package:sle_prep/domain/realtime/realtime_voice_session.dart';

void main() {
  testWidgets(
    'silence never submits; acknowledgement gates interviewer response',
    (tester) async {
      final sent = <String>[];
      final muted = <bool>[];
      final turn = ManualRealtimeTurn(
        send: (event) async => sent.add(event['type'] as String),
        mute: (value) async => muted.add(value),
      );
      await turn.start();
      await tester.pump(const Duration(minutes: 5));
      expect(sent, ['input_audio_buffer.clear']);
      expect(muted, [false]);
      final submitting = turn.submit();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(sent.last, 'input_audio_buffer.commit');
      expect(sent, isNot(contains('response.create')));
      turn.handleEvent({'type': 'input_audio_buffer.committed'});
      await submitting;
      expect(sent.last, 'response.create');
      expect(muted, [false, true]);
      await turn.submit();
      expect(sent.where((e) => e == 'response.create'), hasLength(1));
      turn.close();
    },
  );

  testWidgets('finish commits audio without triggering another question', (
    tester,
  ) async {
    final sent = <String>[];
    late ManualRealtimeTurn turn;
    turn = ManualRealtimeTurn(
      send: (event) async {
        sent.add(event['type'] as String);
        if (event['type'] == 'input_audio_buffer.commit') {
          turn.handleEvent({'type': 'input_audio_buffer.committed'});
        }
      },
      mute: (_) async {},
    );
    await turn.start();
    final submitting = turn.submit(requestResponse: false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await submitting;
    expect(sent, ['input_audio_buffer.clear', 'input_audio_buffer.commit']);
    turn.close();
  });

  testWidgets(
    'rejected commit preserves control and does not request a response',
    (tester) async {
      final sent = <String>[];
      final turn = ManualRealtimeTurn(
        send: (event) async => sent.add(event['type'] as String),
        mute: (_) async {},
      );
      await turn.start();
      final submitting = turn.submit();
      final expected = expectLater(
        submitting,
        throwsA(isA<RealtimeVoiceException>()),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      turn.handleEvent({'type': 'error'});
      await expected;
      expect(sent, isNot(contains('response.create')));
      await turn.start();
      expect(sent.last, 'input_audio_buffer.clear');
      turn.close();
    },
  );

  test('consecutive user transcript fragments are not discarded', () {
    final paired = pairRealtimeTranscript(const [
      RealtimeTranscriptEvent(isUser: false, text: 'Pourquoi?'),
      RealtimeTranscriptEvent(isUser: true, text: 'Première raison.'),
      RealtimeTranscriptEvent(isUser: true, text: 'Deuxième raison.'),
    ]);
    expect(paired.single['answer'], 'Première raison. Deuxième raison.');
  });
}
