import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sle_prep/domain/llm/provider_http.dart';

void main() {
  test(
    'provider request disables redirects before sending any credentials',
    () async {
      final client = MockClient((request) async {
        expect(request.followRedirects, isFalse);
        return http.Response(
          '',
          302,
          headers: {'location': 'https://other.example'},
        );
      });
      final response = await sendProviderRequest(
        client,
        http.Request('POST', Uri.parse('https://provider.example'))
          ..headers['x-api-key'] = 'test-secret',
        timeout: const Duration(seconds: 1),
      );
      expect(response.statusCode, 302);
    },
  );

  test('oversized upstream response is rejected before decoding', () async {
    final client = MockClient((_) async => http.Response('12345', 200));
    await expectLater(
      sendProviderRequest(
        client,
        http.Request('POST', Uri.parse('https://provider.example')),
        timeout: const Duration(seconds: 1),
        maxResponseBytes: 4,
      ),
      throwsA(isA<http.ClientException>()),
    );
  });

  test('stalled response body is cancelled on the overall deadline', () async {
    var cancelled = false;
    final stream = StreamController<List<int>>(
      onCancel: () => cancelled = true,
    );
    final client = MockClient.streaming(
      (_, _) async => http.StreamedResponse(stream.stream, 200),
    );
    final response = sendProviderRequest(
      client,
      http.Request('POST', Uri.parse('https://provider.example')),
      timeout: const Duration(milliseconds: 100),
    );
    final expected = expectLater(response, throwsA(isA<TimeoutException>()));
    await expected;
    expect(cancelled, isTrue);
    await stream.close();
  });
}
