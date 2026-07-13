import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sle_prep/domain/realtime/openai_realtime_api.dart';
import 'package:sle_prep/domain/realtime/realtime_interview_prompt.dart';
import 'package:sle_prep/domain/realtime/realtime_voice_session.dart';

void main() {
  group('Realtime event parser', () {
    test('maps activity and completed transcripts', () {
      expect(
        parseRealtimeServerEvent(
          jsonEncode({'type': 'input_audio_buffer.speech_started'}),
        ).single,
        isA<RealtimeActivityEvent>().having(
          (event) => event.activity,
          'activity',
          RealtimeVoiceActivity.userSpeaking,
        ),
      );

      final user =
          parseRealtimeServerEvent(
                jsonEncode({
                  'type':
                      'conversation.item.input_audio_transcription.completed',
                  'transcript': '  Je travaille en finances.  ',
                }),
              ).single
              as RealtimeTranscriptEvent;
      expect(user.isUser, isTrue);
      expect(user.text, 'Je travaille en finances.');

      final assistant =
          parseRealtimeServerEvent(
                jsonEncode({
                  'type': 'response.output_audio_transcript.done',
                  'transcript': 'Pourquoi avez-vous choisi ce domaine?',
                }),
              ).single
              as RealtimeTranscriptEvent;
      expect(assistant.isUser, isFalse);
    });

    test('ignores unknown and malformed events', () {
      expect(parseRealtimeServerEvent('not-json'), isEmpty);
      expect(
        parseRealtimeServerEvent(jsonEncode({'type': 'rate_limits.updated'})),
        isEmpty,
      );
    });

    test('surfaces server error messages', () {
      final event =
          parseRealtimeServerEvent(
                jsonEncode({
                  'type': 'error',
                  'error': {'message': 'invalid session'},
                }),
              ).single
              as RealtimeErrorEvent;
      expect(event.message, 'invalid session');
    });
  });

  test('pairs adaptive interviewer and candidate turns for assessment', () {
    final exchanges = pairRealtimeTranscript(const [
      RealtimeTranscriptEvent(isUser: false, text: 'Bonjour.'),
      RealtimeTranscriptEvent(
        isUser: false,
        text: 'Décrivez votre travail actuel.',
      ),
      RealtimeTranscriptEvent(isUser: true, text: 'Je conseille mon équipe.'),
      RealtimeTranscriptEvent(
        isUser: false,
        text: 'Que feriez-vous en cas de désaccord?',
      ),
      RealtimeTranscriptEvent(
        isUser: true,
        text: 'Je chercherais un compromis.',
      ),
    ]);

    expect(exchanges, hasLength(2));
    expect(
      exchanges.first['question'],
      'Bonjour. Décrivez votre travail actuel.',
    );
    expect(exchanges.last['answer'], 'Je chercherais un compromis.');
  });

  test('orders asynchronous transcripts by conversation item links', () {
    final buffer = RealtimeTranscriptBuffer();
    buffer
      ..add(
        const RealtimeConversationItemEvent(
          itemId: 'assistant-1',
          previousItemId: null,
        ),
      )
      ..add(
        const RealtimeConversationItemEvent(
          itemId: 'user-1',
          previousItemId: 'assistant-1',
        ),
      )
      ..add(
        const RealtimeConversationItemEvent(
          itemId: 'assistant-2',
          previousItemId: 'user-1',
        ),
      )
      // The next question arrives before asynchronous transcription of the
      // candidate's previous answer completes.
      ..add(
        const RealtimeTranscriptEvent(
          isUser: false,
          text: 'Question A',
          itemId: 'assistant-1',
        ),
      )
      ..add(
        const RealtimeTranscriptEvent(
          isUser: false,
          text: 'Question B',
          itemId: 'assistant-2',
        ),
      )
      ..add(
        const RealtimeTranscriptEvent(
          isUser: true,
          text: 'Réponse A',
          itemId: 'user-1',
        ),
      );

    expect(buffer.orderedTurns.map((turn) => turn.text), [
      'Question A',
      'Réponse A',
      'Question B',
    ]);
    final exchanges = pairRealtimeTranscript(buffer.orderedTurns);
    expect(exchanges, hasLength(1));
    expect(exchanges.single['question'], 'Question A');
    expect(exchanges.single['answer'], 'Réponse A');
  });

  group('OpenAI Realtime REST bootstrap', () {
    test(
      'mints a scoped client secret with the interview session config',
      () async {
        late http.Request captured;
        final api = OpenAiRealtimeApi(
          baseUrl: 'https://api.openai.com/v1/',
          apiKey: 'sk-personal',
          httpClient: MockClient((request) async {
            captured = request;
            return http.Response(jsonEncode({'value': 'ek_short_lived'}), 200);
          }),
        );

        final secret = await api.createClientSecret(
          model: 'gpt-realtime',
          voice: 'marin',
        );

        expect(secret, 'ek_short_lived');
        expect(
          captured.url.toString(),
          'https://api.openai.com/v1/realtime/client_secrets',
        );
        expect(captured.headers['authorization'], 'Bearer sk-personal');
        final body = jsonDecode(captured.body) as Map<String, dynamic>;
        final session = body['session'] as Map<String, dynamic>;
        expect(session['type'], 'realtime');
        expect(session['model'], 'gpt-realtime');
        expect(session['output_modalities'], ['audio']);
        expect(
          ((session['audio'] as Map<String, dynamic>)['input']
              as Map<String, dynamic>)['turn_detection'],
          containsPair('type', 'semantic_vad'),
        );
        expect(session['instructions'], contains('niveau C'));
      },
    );

    test('exchanges SDP using only the short-lived secret', () async {
      late http.Request captured;
      final api = OpenAiRealtimeApi(
        baseUrl: 'https://api.openai.com/v1',
        apiKey: 'sk-personal',
        httpClient: MockClient((request) async {
          captured = request;
          return http.Response('v=0\r\na=answer', 201);
        }),
      );

      final answer = await api.exchangeSdp(
        clientSecret: 'ek_short_lived',
        offerSdp: 'v=0\r\na=offer',
      );

      expect(answer, 'v=0\r\na=answer');
      expect(
        captured.url.toString(),
        'https://api.openai.com/v1/realtime/calls',
      );
      expect(captured.headers['authorization'], 'Bearer ek_short_lived');
      expect(captured.headers['content-type'], 'application/sdp');
      expect(captured.body, 'v=0\r\na=offer');
    });

    test('converts API failures to a safe typed exception', () async {
      final api = OpenAiRealtimeApi(
        baseUrl: 'https://api.openai.com/v1',
        apiKey: 'sk-personal',
        httpClient: MockClient(
          (_) async => http.Response(
            jsonEncode({
              'error': {'message': 'The requested model is unavailable.'},
            }),
            400,
          ),
        ),
      );

      expect(
        () => api.createClientSecret(model: 'bad-model', voice: 'marin'),
        throwsA(
          isA<RealtimeVoiceException>()
              .having((error) => error.statusCode, 'status', 400)
              .having(
                (error) => error.message,
                'message',
                'The requested model is unavailable.',
              ),
        ),
      );
    });
  });

  test('Realtime prompt preserves the SLE interview guardrails', () {
    final prompt = buildRealtimeInterviewInstructions();
    expect(prompt, contains('fonction publique du Canada'));
    expect(prompt, contains('une seule question à la fois'));
    expect(prompt, contains('ne donne aucune note pendant'));
    expect(prompt, contains('prononciation'));
  });
}
