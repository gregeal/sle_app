import 'package:flutter_test/flutter_test.dart';
import 'package:sle_prep/domain/realtime/openai_realtime_voice_session.dart';

void main() {
  test(
    'teacher configuration requires confirmed instructions and manual turns',
    () {
      Map<String, dynamic> event(Object? instructions, Object? turn) => {
        'type': 'session.updated',
        'session': {
          'instructions': instructions,
          'audio': {
            'input': {'turn_detection': turn},
          },
        },
      };
      expect(
        matchesRealtimeConfiguration(event('teacher', null), 'teacher'),
        isTrue,
      );
      expect(
        matchesRealtimeConfiguration(event('examiner', null), 'teacher'),
        isFalse,
      );
      expect(
        matchesRealtimeConfiguration(
          event('teacher', {'type': 'server_vad'}),
          'teacher',
        ),
        isFalse,
      );
      expect(
        matchesRealtimeConfiguration({'type': 'session.created'}, 'teacher'),
        isFalse,
      );
      expect(
        matchesRealtimeConfiguration(event('examiner', null), null),
        isTrue,
      );
    },
  );
}
