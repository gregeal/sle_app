import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'llm_client.dart';

/// Client for any endpoint speaking the OpenAI chat-completions dialect:
/// OpenAI itself, OpenRouter, a local Ollama, LM Studio, vLLM…
class OpenAiCompatibleClient implements LlmClient {
  OpenAiCompatibleClient({
    required this.baseUrl,
    required this.model,
    required this.apiKey,
    http.Client? httpClient,
    this.timeout = const Duration(seconds: 90),
  }) : _http = httpClient ?? http.Client();

  final String baseUrl;
  final String model;
  final String? apiKey;
  final Duration timeout;
  final http.Client _http;

  @override
  Future<String> complete({
    required String system,
    required String user,
    double temperature = 0.7,
    int? maxTokens,
  }) async {
    final base = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final url = Uri.parse('$base/chat/completions');
    final key = apiKey;
    final authorization =
        key != null && key.isNotEmpty ? 'Bearer $key' : null;

    final http.Response response;
    try {
      response = await _http
          .post(
            url,
            headers: {
              'content-type': 'application/json',
              'Authorization': ?authorization,
            },
            body: jsonEncode({
              'model': model,
              'temperature': temperature,
              'max_tokens': ?maxTokens,
              'messages': [
                {'role': 'system', 'content': system},
                {'role': 'user', 'content': user},
              ],
            }),
          )
          .timeout(timeout);
    } on TimeoutException {
      throw const LlmException(
          'Le fournisseur IA n\'a pas répondu à temps. Réessayez.');
    } on SocketException catch (error) {
      throw LlmException('Connexion impossible : ${error.message}');
    } on http.ClientException catch (error) {
      throw LlmException('Connexion impossible : ${error.message}');
    }

    final payload = _decode(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw LlmException(
        _errorMessage(payload) ?? 'Le fournisseur IA a refusé la requête.',
        statusCode: response.statusCode,
      );
    }

    final content = _firstChoiceContent(payload);
    if (content == null || content.isEmpty) {
      throw const LlmException('Réponse vide ou inattendue du fournisseur IA.');
    }
    return content;
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
    final message = (choices.first as Map<String, dynamic>?)?['message'];
    final content = (message as Map<String, dynamic>?)?['content'];
    return content is String ? content : null;
  }
}
