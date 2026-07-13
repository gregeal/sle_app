import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'realtime_interview_prompt.dart';
import 'realtime_voice_session.dart';

const defaultRealtimeModel = 'gpt-realtime';
const defaultRealtimeVoice = 'marin';
const realtimeVoices = [
  'marin',
  'cedar',
  'coral',
  'sage',
  'verse',
  'alloy',
  'ash',
  'ballad',
  'echo',
  'shimmer',
];

typedef RealtimeClientSecretProvider =
    Future<String> Function({required String model, required String voice});

Map<String, dynamic> buildRealtimeSessionConfig({
  required String model,
  required String voice,
}) => {
  'session': {
    'type': 'realtime',
    'model': model,
    'output_modalities': ['audio'],
    'instructions': buildRealtimeInterviewInstructions(),
    'audio': {
      'input': {
        'noise_reduction': {'type': 'near_field'},
        'transcription': {'model': 'gpt-4o-mini-transcribe', 'language': 'fr'},
        'turn_detection': {
          'type': 'semantic_vad',
          'eagerness': 'medium',
          'create_response': true,
          'interrupt_response': true,
        },
      },
      'output': {'voice': voice},
    },
    'max_output_tokens': 800,
  },
};

class OpenAiRealtimeApi {
  OpenAiRealtimeApi({
    required this.baseUrl,
    this.apiKey = '',
    this.clientSecretProvider,
    http.Client? httpClient,
    this.timeout = const Duration(seconds: 30),
  }) : _http = httpClient ?? http.Client(),
       _ownsClient = httpClient == null;

  final String baseUrl;
  final String apiKey;
  final RealtimeClientSecretProvider? clientSecretProvider;
  final Duration timeout;
  final http.Client _http;
  final bool _ownsClient;

  Future<String> createClientSecret({
    required String model,
    required String voice,
  }) async {
    final provider = clientSecretProvider;
    if (provider != null) return provider(model: model, voice: voice);
    final response = await _post(
      _endpoint('realtime/client_secrets'),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(buildRealtimeSessionConfig(model: model, voice: voice)),
    );
    final payload = _decode(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _responseError(response, payload);
    }
    final value = payload?['value'];
    if (value is! String || value.isEmpty) {
      throw const RealtimeVoiceException(
        'OpenAI n’a pas retourné de jeton Realtime valide.',
      );
    }
    return value;
  }

  Future<String> exchangeSdp({
    required String clientSecret,
    required String offerSdp,
  }) async {
    final response = await _post(
      _endpoint('realtime/calls'),
      headers: {
        'Authorization': 'Bearer $clientSecret',
        'Content-Type': 'application/sdp',
      },
      body: offerSdp,
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _responseError(response, _decode(response));
    }
    final answer = utf8.decode(response.bodyBytes).trim();
    if (answer.isEmpty) {
      throw const RealtimeVoiceException(
        'OpenAI n’a pas retourné de réponse WebRTC valide.',
      );
    }
    return answer;
  }

  Uri _endpoint(String suffix) {
    final normalized = baseUrl.trim().replaceFirst(RegExp(r'/+$'), '');
    return Uri.parse('$normalized/$suffix');
  }

  Future<http.Response> _post(
    Uri uri, {
    required Map<String, String> headers,
    required String body,
  }) async {
    try {
      return await _http
          .post(uri, headers: headers, body: body)
          .timeout(timeout);
    } on TimeoutException {
      throw const RealtimeVoiceException(
        'OpenAI n’a pas répondu à temps. Réessayez.',
      );
    } on http.ClientException catch (error) {
      throw RealtimeVoiceException(
        'Connexion Realtime impossible : ${error.message}',
      );
    }
  }

  Map<String, dynamic>? _decode(http.Response response) {
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      return decoded is Map<String, dynamic> ? decoded : null;
    } on FormatException {
      return null;
    }
  }

  RealtimeVoiceException _responseError(
    http.Response response,
    Map<String, dynamic>? payload,
  ) {
    final error = payload?['error'];
    final message = error is Map ? error['message'] : null;
    return RealtimeVoiceException(
      message is String && message.isNotEmpty
          ? message
          : 'OpenAI a refusé la connexion Realtime.',
      statusCode: response.statusCode,
    );
  }

  void close() {
    if (_ownsClient) _http.close();
  }
}
