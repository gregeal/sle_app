import 'package:flutter_test/flutter_test.dart';
import 'package:sle_prep/domain/realtime/realtime_voice_session.dart';
import 'package:sle_prep/features/coach/realtime_interview_screen.dart';

void main() {
  test('interview survives recoverable server errors', () {
    const event = RealtimeErrorEvent(
      'A single request was rejected.',
      type: 'invalid_request_error',
      code: 'invalid_value',
    );

    expect(shouldTerminateRealtimeInterview(event), isFalse);
  });

  test('interview terminates after a fatal transport error', () {
    const event = RealtimeErrorEvent(
      'The WebRTC connection failed.',
      type: 'transport_error',
      isFatal: true,
    );

    expect(shouldTerminateRealtimeInterview(event), isTrue);
  });
}
