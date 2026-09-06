import 'dart:async';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

/// Authenticated provider requests must not forward custom credential headers
/// through redirects, or buffer an unbounded/malicious upstream response.
Future<http.Response> sendProviderRequest(
  http.Client client,
  http.Request request, {
  required Duration timeout,
  int maxResponseBytes = 2 * 1024 * 1024,
}) async {
  request.followRedirects = false;
  final clock = Stopwatch()..start();
  final response = await client.send(request).timeout(timeout);
  final remaining = timeout - clock.elapsed;
  final bytes = BytesBuilder(copy: false);
  final result = Completer<List<int>>();
  final timer = Timer(remaining.isNegative ? Duration.zero : remaining, () {
    if (!result.isCompleted) {
      result.completeError(TimeoutException('Provider timeout'));
    }
  });
  final subscription = response.stream.listen(
    (chunk) {
      if (result.isCompleted) return;
      if (bytes.length + chunk.length > maxResponseBytes) {
        result.completeError(
          http.ClientException('Réponse IA trop volumineuse.'),
        );
      } else {
        bytes.add(chunk);
      }
    },
    onError: (Object error, StackTrace stack) {
      if (!result.isCompleted) result.completeError(error, stack);
    },
    onDone: () {
      if (!result.isCompleted) result.complete(bytes.takeBytes());
    },
  );
  try {
    return http.Response.bytes(
      await result.future,
      response.statusCode,
      headers: response.headers,
      request: request,
    );
  } finally {
    timer.cancel();
    await subscription.cancel();
  }
}
