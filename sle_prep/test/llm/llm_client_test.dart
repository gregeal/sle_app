import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sle_prep/domain/llm/anthropic_client.dart';
import 'package:sle_prep/domain/llm/llm_client.dart';
import 'package:sle_prep/domain/llm/llm_config.dart';
import 'package:sle_prep/domain/llm/openai_compatible_client.dart';

void main() {
  group('Realtime endpoint policy', () {
    LlmConfig config(String baseUrl) => LlmConfig(
      provider: LlmProvider.openAiCompatible,
      baseUrl: baseUrl,
      model: 'gpt-test',
      hasApiKey: true,
    );

    test('accepts only the exact official HTTPS v1 destination', () {
      expect(
        supportsOpenAiRealtime(config('https://api.openai.com/v1/')),
        isTrue,
      );
      for (final value in [
        'http://api.openai.com/v1',
        'https://user@api.openai.com/v1',
        'https://api.openai.com:444/v1',
        'https://api.openai.com/v1?target=other',
        'https://api.openai.com/other',
      ]) {
        expect(supportsOpenAiRealtime(config(value)), isFalse, reason: value);
      }
    });
  });

  group('OpenAiCompatibleClient', () {
    test(
      'posts to chat/completions with auth header and parses the reply',
      () async {
        late http.Request captured;
        final client = OpenAiCompatibleClient(
          baseUrl: 'https://api.openai.com/v1',
          model: 'gpt-test',
          apiKey: 'sk-secret',
          httpClient: MockClient((request) async {
            captured = request;
            return http.Response(
              jsonEncode({
                'choices': [
                  {
                    'message': {'role': 'assistant', 'content': 'Bonjour !'},
                  },
                ],
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }),
        );

        final reply = await client.complete(
          system: 'Tu es un évaluateur.',
          user: 'Dis bonjour.',
        );

        expect(reply, 'Bonjour !');
        expect(
          captured.url.toString(),
          'https://api.openai.com/v1/chat/completions',
        );
        expect(captured.headers['Authorization'], 'Bearer sk-secret');

        final body = jsonDecode(captured.body) as Map<String, dynamic>;
        expect(body['model'], 'gpt-test');
        expect(body['store'], isFalse);
        final messages = (body['messages'] as List)
            .cast<Map<String, dynamic>>();
        expect(messages.first['role'], 'system');
        expect(messages.last['role'], 'user');
        expect(messages.last['content'], 'Dis bonjour.');
      },
    );

    test('tolerates a base URL with a trailing slash', () async {
      late Uri url;
      final client = OpenAiCompatibleClient(
        baseUrl: 'http://192.168.0.10:11434/v1/',
        model: 'llama',
        apiKey: null,
        httpClient: MockClient((request) async {
          url = request.url;
          return http.Response(
            jsonEncode({
              'choices': [
                {
                  'message': {'content': 'ok'},
                },
              ],
            }),
            200,
          );
        }),
      );

      await client.complete(system: 's', user: 'u');
      expect(url.toString(), 'http://192.168.0.10:11434/v1/chat/completions');
    });

    test('maps a 401 to an LlmException with the API message', () async {
      final client = OpenAiCompatibleClient(
        baseUrl: 'https://api.openai.com/v1',
        model: 'gpt-test',
        apiKey: 'bad-key',
        httpClient: MockClient((request) async {
          return http.Response(
            jsonEncode({
              'error': {'message': 'Incorrect API key provided'},
            }),
            401,
          );
        }),
      );

      await expectLater(
        client.complete(system: 's', user: 'u'),
        throwsA(
          isA<LlmException>()
              .having((e) => e.statusCode, 'statusCode', 401)
              .having(
                (e) => e.message,
                'message',
                contains('Incorrect API key'),
              ),
        ),
      );
    });

    test(
      'maps malformed choice shapes to a user-facing LlmException',
      () async {
        final client = OpenAiCompatibleClient(
          baseUrl: 'https://api.openai.com/v1',
          model: 'gpt-test',
          apiKey: 'key',
          httpClient: MockClient(
            (_) async => http.Response(
              jsonEncode({
                'choices': [42],
              }),
              200,
            ),
          ),
        );
        await expectLater(
          client.complete(system: 's', user: 'u'),
          throwsA(
            isA<LlmException>().having(
              (error) => error.message,
              'message',
              contains('Réponse vide ou inattendue'),
            ),
          ),
        );
      },
    );

    test(
      'retries with max_completion_tokens when the model rejects max_tokens',
      () async {
        final bodies = <Map<String, dynamic>>[];
        final client = OpenAiCompatibleClient(
          baseUrl: 'https://api.openai.com/v1',
          model: 'gpt-5.4-mini',
          apiKey: 'sk',
          httpClient: MockClient((request) async {
            final body = jsonDecode(request.body) as Map<String, dynamic>;
            bodies.add(body);
            if (body.containsKey('max_tokens')) {
              return http.Response(
                jsonEncode({
                  'error': {
                    'message':
                        "Unsupported parameter: 'max_tokens' is not supported "
                        "with this model. Use 'max_completion_tokens' "
                        'instead.',
                  },
                }),
                400,
              );
            }
            return http.Response(
              jsonEncode({
                'choices': [
                  {
                    'message': {'content': 'OK'},
                  },
                ],
              }),
              200,
            );
          }),
        );

        final reply = await client.complete(
          system: 's',
          user: 'u',
          maxTokens: 16,
        );

        expect(reply, 'OK');
        expect(bodies, hasLength(2));
        expect(bodies.first['max_tokens'], 16);
        expect(bodies.last.containsKey('max_tokens'), isFalse);
        expect(bodies.last['max_completion_tokens'], 16);
      },
    );

    test('retries without temperature when the model rejects it', () async {
      final bodies = <Map<String, dynamic>>[];
      final client = OpenAiCompatibleClient(
        baseUrl: 'https://api.openai.com/v1',
        model: 'gpt-5.4-mini',
        apiKey: 'sk',
        httpClient: MockClient((request) async {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          bodies.add(body);
          if (body.containsKey('temperature')) {
            return http.Response(
              jsonEncode({
                'error': {
                  'message':
                      "Unsupported value: 'temperature' does not support 0.8 "
                      'with this model. Only the default (1) value is '
                      'supported.',
                },
              }),
              400,
            );
          }
          return http.Response(
            jsonEncode({
              'choices': [
                {
                  'message': {'content': 'OK'},
                },
              ],
            }),
            200,
          );
        }),
      );

      final reply = await client.complete(system: 's', user: 'u');

      expect(reply, 'OK');
      expect(bodies, hasLength(2));
      expect(bodies.last.containsKey('temperature'), isFalse);
    });

    test('maps malformed JSON to an LlmException', () async {
      final client = OpenAiCompatibleClient(
        baseUrl: 'https://api.openai.com/v1',
        model: 'gpt-test',
        apiKey: 'sk',
        httpClient: MockClient(
          (request) async => http.Response('<html>gateway</html>', 200),
        ),
      );

      await expectLater(
        client.complete(system: 's', user: 'u'),
        throwsA(isA<LlmException>()),
      );
    });
  });

  group('AnthropicClient', () {
    test(
      'posts to v1/messages with anthropic headers and parses the reply',
      () async {
        late http.Request captured;
        final client = AnthropicClient(
          baseUrl: 'https://api.anthropic.com',
          model: 'claude-test',
          apiKey: 'sk-ant',
          httpClient: MockClient((request) async {
            captured = request;
            return http.Response(
              jsonEncode({
                'content': [
                  {'type': 'text', 'text': 'Bonjour !'},
                ],
              }),
              200,
            );
          }),
        );

        final reply = await client.complete(
          system: 'Tu es un évaluateur.',
          user: 'Dis bonjour.',
        );

        expect(reply, 'Bonjour !');
        expect(
          captured.url.toString(),
          'https://api.anthropic.com/v1/messages',
        );
        expect(captured.headers['x-api-key'], 'sk-ant');
        expect(captured.headers['anthropic-version'], isNotEmpty);

        final body = jsonDecode(captured.body) as Map<String, dynamic>;
        expect(body['model'], 'claude-test');
        expect(body['system'], 'Tu es un évaluateur.');
        expect(body['max_tokens'], isA<int>());
      },
    );

    test('maps API errors to LlmException', () async {
      final client = AnthropicClient(
        baseUrl: 'https://api.anthropic.com',
        model: 'claude-test',
        apiKey: 'sk-ant',
        httpClient: MockClient((request) async {
          return http.Response(
            jsonEncode({
              'error': {'type': 'overloaded_error', 'message': 'Overloaded'},
            }),
            529,
          );
        }),
      );

      await expectLater(
        client.complete(system: 's', user: 'u'),
        throwsA(
          isA<LlmException>()
              .having((e) => e.statusCode, 'statusCode', 529)
              .having((e) => e.message, 'message', contains('Overloaded')),
        ),
      );
    });
  });

  group('clientFor', () {
    LlmConfig config(LlmProvider provider) => LlmConfig(
      provider: provider,
      baseUrl: provider == LlmProvider.custom
          ? 'https://custom.example/v1'
          : defaultBaseUrl(provider),
      model: 'm',
      hasApiKey: true,
    );

    test('selects the Anthropic client for the Anthropic provider', () {
      expect(
        clientFor(config(LlmProvider.anthropic), apiKey: 'k'),
        isA<AnthropicClient>(),
      );
    });

    test('selects the OpenAI-compatible client for the other providers', () {
      for (final provider in [
        LlmProvider.openAiCompatible,
        LlmProvider.openRouter,
        LlmProvider.ollama,
        LlmProvider.custom,
      ]) {
        expect(
          clientFor(config(provider), apiKey: 'k'),
          isA<OpenAiCompatibleClient>(),
        );
      }
    });

    test('requires an API key except for Ollama', () {
      expect(
        () => clientFor(config(LlmProvider.openAiCompatible), apiKey: null),
        throwsA(isA<LlmException>()),
      );
      expect(
        clientFor(config(LlmProvider.ollama), apiKey: null),
        isA<OpenAiCompatibleClient>(),
      );
    });

    test('rejects key-bearing cleartext endpoints', () {
      final unsafe = LlmConfig(
        provider: LlmProvider.custom,
        baseUrl: 'http://example.com/v1',
        model: 'm',
        hasApiKey: true,
      );
      expect(
        () => clientFor(unsafe, apiKey: 'sk-must-not-leak'),
        throwsA(isA<LlmException>()),
      );
    });

    test('allows only keyless private HTTP Ollama endpoints', () {
      final local = LlmConfig(
        provider: LlmProvider.ollama,
        baseUrl: 'http://192.168.1.10:11434/v1',
        model: 'llama',
        hasApiKey: false,
      );
      final public = LlmConfig(
        provider: LlmProvider.ollama,
        baseUrl: 'http://ollama.example.com/v1',
        model: 'llama',
        hasApiKey: false,
      );
      expect(clientFor(local, apiKey: null), isA<OpenAiCompatibleClient>());
      expect(
        () => clientFor(public, apiKey: null),
        throwsA(isA<LlmException>()),
      );
    });

    test('API key storage is scoped to normalized provider destination', () {
      final first = apiKeyStorageKey(
        LlmProvider.openAiCompatible,
        'HTTPS://API.OPENAI.COM:443/v1/',
      );
      final equivalent = apiKeyStorageKey(
        LlmProvider.openAiCompatible,
        'https://api.openai.com/v1',
      );
      final differentHost = apiKeyStorageKey(
        LlmProvider.custom,
        'https://example.com/v1',
      );
      expect(first, equivalent);
      expect(first, isNot(differentHost));
      expect(first, isNot(contains('api.openai.com')));
    });
  });
}
