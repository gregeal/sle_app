import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'llm_client.dart';

/// Client for any endpoint speaking the OpenAI chat-completions dialect:
/// OpenAI itself, OpenRouter, a local Ollama, LM Studio, vLLM…
class OpenAiCompatibleClient implements LlmClient, ClosableLlmClient {
  OpenAiCompatibleClient({
    required this.baseUrl,
    required this.model,
    required this.apiKey,
    http.Client? httpClient,
    this.timeout = const Duration(seconds: 90),
  }) : _http = httpClient ?? http.Client(),
       _ownsHttp = httpClient == null;

  final String baseUrl;
  final String model;
  final String? apiKey;
  final Duration timeout;
  final http.Client _http;
  final bool _ownsHttp;

  @override
  void close() {
    if (_ownsHttp) _http.close();
  }

  @override
  Future<String> complete({
    required String system,
    required String user,
    double temperature = 0.7,
    int? maxTokens,
  }) async {
    final body = <String, dynamic>{
      'model': model,
      'temperature': temperature,
      'max_tokens': ?maxTokens,
      if (Uri.tryParse(baseUrl)?.host.toLowerCase() == 'api.openai.com')
        'store': false,
      'messages': [
        {'role': 'system', 'content': system},
        {'role': 'user', 'content': user},
      ],
    };

    // Newer OpenAI models reject legacy parameter names/values that the rest
    // of the OpenAI-compatible ecosystem still expects, so adapt based on the
    // server's own error message instead of hardcoding per provider.
    for (var attempt = 0; ; attempt++) {
      final response = await _post(body);
      final payload = _decode(response);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final content = _firstChoiceContent(payload);
        if (content == null || content.isEmpty) {
          throw const LlmException(
            'Réponse vide ou inattendue du fournisseur IA.',
          );
        }
        return content;
      }

      final message = _errorMessage(payload);
      if (response.statusCode == 400 && message != null && attempt < 2) {
        if (body.containsKey('max_tokens') &&
            message.contains('max_completion_tokens')) {
          body['max_completion_tokens'] = body.remove('max_tokens');
          continue;
        }
        if (body.containsKey('temperature') &&
            message.toLowerCase().contains("'temperature'")) {
          body.remove('temperature');
          continue;
        }
      }

      throw LlmException(
        message ?? 'Le fournisseur IA a refusé la requête.',
        statusCode: response.statusCode,
      );
    }
  }

  Future<http.Response> _post(Map<String, dynamic> body) async {
    final base = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final url = Uri.parse('$base/chat/completions');
    final key = apiKey;
    final authorization = key != null && key.isNotEmpty ? 'Bearer $key' : null;

    try {
      return await _http
          .post(
            url,
            headers: {
              'content-type': 'application/json',
              'Authorization': ?authorization,
            },
            body: jsonEncode(body),
          )
          .timeout(timeout);
    } on TimeoutException {
      throw const LlmException(
        'Le fournisseur IA n\'a pas répondu à temps. Réessayez.',
      );
    } on http.ClientException catch (error) {
      // package:http wraps socket-level failures in ClientException on
      // every platform, including the web.
      throw LlmException('Connexion impossible : ${error.message}');
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

  String? _errorMessage(Map<String, dynamic>? payload) {
    final error = payload?['error'];
    if (error is Map && error['message'] is String) {
      return error['message'] as String;
    }
    if (error is String) return error;
    return null;
  }

  String? _firstChoiceContent(Map<String, dynamic>? payload) {
    final choices = payload?['choices'];
    if (choices is! List || choices.isEmpty) return null;
    final first = choices.first;
    if (first is! Map) return null;
    final message = first['message'];
    if (message is! Map) return null;
    final content = message['content'];
    return content is String ? content : null;
  }
}
