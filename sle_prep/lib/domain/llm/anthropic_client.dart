import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'llm_client.dart';

class AnthropicClient implements LlmClient {
  AnthropicClient({
    required this.baseUrl,
    required this.model,
    required this.apiKey,
    http.Client? httpClient,
    this.timeout = const Duration(seconds: 90),
  }) : _http = httpClient ?? http.Client();

  static const _apiVersion = '2023-06-01';

  final String baseUrl;
  final String model;
  final String apiKey;
  final Duration timeout;
  final http.Client _http;

  @override
  Future<String> complete({
    required String system,
    required String user,
    double temperature = 0.7,
    int? maxTokens,
  }) async {
    var base = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    if (!base.endsWith('/v1')) base = '$base/v1';
    final url = Uri.parse('$base/messages');

    final http.Response response;
    try {
      response = await _http
          .post(
            url,
            headers: {
              'content-type': 'application/json',
              'x-api-key': apiKey,
              'anthropic-version': _apiVersion,
            },
            body: jsonEncode({
              'model': model,
              'max_tokens': maxTokens ?? 1024,
              'temperature': temperature,
              'system': system,
              'messages': [
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
      final error = payload?['error'];
      final message = error is Map && error['message'] is String
          ? error['message'] as String
          : 'Le fournisseur IA a refusé la requête.';
      throw LlmException(message, statusCode: response.statusCode);
    }

    final content = payload?['content'];
    if (content is List) {
      for (final block in content) {
        if (block is Map && block['text'] is String) {
          return block['text'] as String;
        }
      }
    }
    throw const LlmException('Réponse vide ou inattendue du fournisseur IA.');
  }

  Map<String, dynamic>? _decode(http.Response response) {
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      return decoded is Map<String, dynamic> ? decoded : null;
    } on FormatException {
      return null;
    }
  }
}
