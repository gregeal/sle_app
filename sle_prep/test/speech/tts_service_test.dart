import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sle_prep/domain/speech/speech_services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'stop cancels speech queued while the French voice initializes',
    () async {
      final ready = Completer<int>();
      final calls = <String>[];
      const channel = MethodChannel('flutter_tts');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls.add(call.method);
            if (call.method == 'setLanguage') return ready.future;
            return 1;
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null),
      );
      final tts = DeviceTtsService();
      final speaking = tts.speak('Ne pas lire après fermeture.');
      final stopping = tts.stop();
      ready.complete(1);
      await Future.wait([speaking, stopping]);
      expect(calls.where((method) => method == 'speak'), isEmpty);
      await tts.speak('Une nouvelle demande reste possible.');
      expect(calls.where((method) => method == 'speak'), hasLength(1));
    },
  );
}
