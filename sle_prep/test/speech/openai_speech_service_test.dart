import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sle_prep/domain/realtime/openai_realtime_api.dart';
import 'package:sle_prep/domain/speech/openai_dictation_transport.dart';
import 'package:sle_prep/domain/speech/openai_speech_service.dart';
import 'package:sle_prep/domain/speech/transcription_config.dart';

class FakeDictationTransport implements DictationTransport {
  late void Function(Map<String, dynamic>) receive;
  late void Function() fail;
  final sent = <Map<String, dynamic>>[];
  final mutes = <bool>[];
  Completer<void>? connecting;
  int closes = 0;
  void Function()? onCommit;
  @override
  Future<void> connect({
    required void Function(Map<String, dynamic>) onEvent,
    required void Function() onFailure,
  }) async {
    receive = onEvent;
    fail = onFailure;
    await connecting?.future;
  }

  @override
  Future<void> mute(bool muted) async {
    mutes.add(muted);
  }

  @override
  Future<void> send(Map<String, dynamic> event) async {
    sent.add(event);
    if (event['type'] == 'input_audio_buffer.commit') onCommit?.call();
  }

  @override
  Future<void> close() async {
    closes++;
  }

  void delta(String text, {String? eventId}) => receive({
    'type': 'conversation.item.input_audio_transcription.delta',
    'item_id': 'one',
    'delta': text,
    'event_id': ?eventId,
  });
  void complete(String text) => receive({
    'type': 'conversation.item.input_audio_transcription.completed',
    'item_id': 'one',
    'transcript': text,
  });
  void commitAck() =>
      receive({'type': 'input_audio_buffer.committed', 'item_id': 'one'});
}

OpenAiSpeechService service(FakeDictationTransport transport) =>
    OpenAiSpeechService(
      createTransport: () => transport,
      drainDelay: Duration.zero,
      finalTimeout: const Duration(milliseconds: 50),
    );

void main() {
  test(
    'live deltas remain provisional; stop mutes, commits once and waits for final wording',
    () async {
      final transport = FakeDictationTransport();
      final speech = service(transport);
      final results = <String>[];
      var done = 0;
      await speech.listen(onResult: results.add, onDone: () => done++);
      transport.delta('Si je ', eventId: 'a');
      transport.delta('Si je ', eventId: 'a');
      transport.delta('pourrais', eventId: 'b');
      expect(results.last, 'Si je pourrais');
      expect(transport.sent, isEmpty);
      expect(done, 0);
      transport.onCommit = () {
        // Completion may beat the commit acknowledgement; never drop it.
        transport.complete('Si je pouvais, je le ferais.');
        transport.commitAck();
      };
      final stopping = speech.stop();
      expect(identical(stopping, speech.stop()), isTrue);
      await stopping;
      expect(transport.mutes.last, isTrue);
      expect(results.last, 'Si je pouvais, je le ferais.');
      expect(transport.sent.single['type'], 'input_audio_buffer.commit');
      expect(
        transport.sent.any((e) => e['type'] == 'response.create'),
        isFalse,
      );
      expect(speech.isListening, isFalse);
      expect(transport.closes, 1);
      transport.delta('late');
      expect(results.last, 'Si je pouvais, je le ferais.');
    },
  );

  test(
    'missing final text reports uncertainty and keeps the partial transcript',
    () async {
      final transport = FakeDictationTransport();
      final speech = service(transport);
      final results = <String>[];
      await speech.listen(onResult: results.add, onDone: () {});
      transport.delta('Mes derniers mots');
      await expectLater(speech.stop(), throwsA(isA<DictationException>()));
      expect(results.last, 'Mes derniers mots');
      expect(speech.lastError, contains('incomplet'));
      expect(transport.closes, 1);
      expect(transport.mutes.last, isTrue);
    },
  );

  test(
    'cancel during startup cannot later unmute or emit a stale transcript',
    () async {
      final transport = FakeDictationTransport()
        ..connecting = Completer<void>();
      final speech = service(transport);
      final results = <String>[];
      final starting = speech.listen(onResult: results.add, onDone: () {});
      await Future<void>.delayed(Duration.zero);
      await speech.cancel();
      transport.connecting!.complete();
      await starting;
      transport.delta('stale');
      expect(results, isEmpty);
      expect(transport.mutes, isNot(contains(false)));
      expect(speech.isListening, isFalse);
      expect(transport.closes, greaterThan(0));
    },
  );

  test(
    'transport error closes capture and does not expose provider diagnostics',
    () async {
      final transport = FakeDictationTransport();
      final speech = service(transport);
      var done = 0;
      await speech.listen(onResult: (_) {}, onDone: () => done++);
      transport.receive({
        'type': 'error',
        'error': {'message': 'secret diagnostic'},
      });
      await Future<void>.delayed(Duration.zero);
      expect(done, 1);
      expect(transport.closes, 1);
      expect(speech.lastError, isNot(contains('secret')));
      expect(speech.isListening, isFalse);
    },
  );

  test('empty capture finishes without inventing a transcript', () async {
    final transport = FakeDictationTransport();
    final speech = service(transport);
    final results = <String>[];
    await speech.listen(onResult: results.add, onDone: () {});
    transport.onCommit = () => transport.receive({
      'type': 'error',
      'error': {'code': 'input_audio_buffer_commit_empty'},
    });
    await speech.stop();
    expect(results, isEmpty);
    expect(speech.lastError, isNull);
  });

  test(
    'transcription credential is short-lived, French, input-only and manual',
    () async {
      final requests = <http.Request>[];
      final api = OpenAiRealtimeApi(
        baseUrl: 'https://api.openai.com/v1',
        apiKey: 'test-key',
        httpClient: MockClient((request) async {
          requests.add(request);
          return http.Response('{"value":"ek_test"}', 200);
        }),
      );
      expect(await api.createTranscriptionSecret(), 'ek_test');
      final payload = jsonDecode(requests.single.body) as Map;
      expect(payload, buildTranscriptionSessionConfig());
      final session = payload['session'] as Map;
      expect(session['type'], 'transcription');
      expect(session.containsKey('model'), isFalse);
      final input = session['audio']['input'] as Map;
      expect(input['turn_detection'], isNull);
      expect(input['transcription']['languages'], ['fr']);
      expect(input['transcription']['delay'], 'high');
      expect(requests.single.followRedirects, isFalse);
    },
  );
}
