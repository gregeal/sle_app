import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sle_prep/domain/auth/web_auth_service.dart';
import 'package:sle_prep/domain/llm/ai_gateway.dart';
import 'package:sle_prep/domain/llm/llm_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const session = WebAuthSession(
    authenticated: true,
    email: 'owner@example.com',
    csrfToken: 'csrf-test',
    googleEnabled: true,
    passkeysEnabled: true,
  );

  test(
    'BrokerLlmClient sends normalized same-origin request with CSRF',
    () async {
      late http.Request captured;
      final service = WebAuthService(
        baseUri: Uri.parse('https://sle-prep.example/'),
        httpClient: MockClient((request) async {
          captured = request;
          return http.Response(jsonEncode({'text': ' Bonjour '}), 200);
        }),
      );
      final client = BrokerLlmClient(auth: service, session: session);

      final result = await client.complete(
        system: 'Réponds en français.',
        user: 'Bonjour',
        temperature: 0.2,
        maxTokens: 50,
      );

      expect(result, 'Bonjour');
      expect(captured.url, Uri.parse('https://sle-prep.example/api/chat'));
      expect(captured.headers['X-CSRF-Token'], 'csrf-test');
      final body = jsonDecode(captured.body) as Map<String, dynamic>;
      expect(body['system'], 'Réponds en français.');
      expect(body['max_tokens'], 50);
      expect(body, isNot(contains('apiKey')));
    },
  );

  test('BrokerLlmClient maps broker errors to LlmException', () async {
    final service = WebAuthService(
      baseUri: Uri.parse('https://sle-prep.example/'),
      httpClient: MockClient(
        (_) async =>
            http.Response(jsonEncode({'detail': 'Plafond atteint.'}), 429),
      ),
    );
    final client = BrokerLlmClient(auth: service, session: session);

    await expectLater(
      client.complete(system: 's', user: 'u'),
      throwsA(
        isA<LlmException>()
            .having((error) => error.statusCode, 'statusCode', 429)
            .having((error) => error.message, 'message', 'Plafond atteint.'),
      ),
    );
  });

  test('BrokerGateway obtains a short-lived Realtime credential', () async {
    final service = WebAuthService(
      baseUri: Uri.parse('https://sle-prep.example/'),
      httpClient: MockClient((request) async {
        expect(request.url.path, '/api/realtime/session');
        expect(request.body, contains('gpt-realtime'));
        return http.Response(jsonEncode({'value': 'ek_short'}), 200);
      }),
    );
    final gateway = BrokerGateway(
      auth: service,
      loadSession: () async => session,
    );

    expect(
      await gateway.realtimeClientSecret(model: 'gpt-realtime', voice: 'marin'),
      'ek_short',
    );
  });
}
