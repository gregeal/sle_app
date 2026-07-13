import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sle_prep/domain/auth/web_auth_service.dart';
import 'package:sle_prep/providers.dart';

void main() {
  const userA =
      'sle_aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
  const userB =
      'sle_bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';

  test('web database names are stable and isolated by opaque user id', () {
    expect(webDatabaseName(userA), webDatabaseName(userA));
    expect(webDatabaseName(userA), isNot(webDatabaseName(userB)));
    expect(() => webDatabaseName('owner@example.com'), throwsStateError);
  });

  test('offline profile hint expires and contains no email', () {
    final now = DateTime.utc(2026, 7, 13, 12);
    final encoded = encodeOfflineProfileHint(
      userA,
      now.add(const Duration(days: 7)),
    );
    expect(encoded, isNot(contains('@')));
    expect(decodeOfflineProfileHint(encoded, now: now)?.userId, userA);
    expect(
      decodeOfflineProfileHint(encoded, now: now.add(const Duration(days: 8))),
      isNull,
    );
  });

  test('offline profile rejects malformed and implausibly extended hints', () {
    final now = DateTime.utc(2026, 7, 13, 12);
    expect(decodeOfflineProfileHint('owner@example.com', now: now), isNull);
    expect(decodeOfflineProfileHint('{"version":1}', now: now), isNull);
    expect(
      decodeOfflineProfileHint(
        encodeOfflineProfileHint(userB, now.add(const Duration(days: 30))),
        now: now,
      ),
      isNull,
    );
  });

  test(
    'server failures fall back to a recent opaque offline profile',
    () async {
      final hint = encodeOfflineProfileHint(
        userA,
        DateTime.now().add(const Duration(days: 1)),
      );
      final service = WebAuthService(
        baseUri: Uri.parse('https://sle-prep.example/'),
        httpClient: MockClient((_) async => http.Response('unavailable', 503)),
        readHint: () => hint,
      );

      final session = await service.session();

      expect(session.authenticated, isTrue);
      expect(session.offline, isTrue);
      expect(session.userId, userA);
      expect(session.email, isNull);
    },
  );

  test(
    'unavailable browser storage does not break an online session',
    () async {
      final service = WebAuthService(
        baseUri: Uri.parse('https://sle-prep.example/'),
        httpClient: MockClient(
          (_) async => http.Response(
            jsonEncode({
              'authenticated': true,
              'userId': userA,
              'csrfToken': 'csrf-test',
            }),
            200,
          ),
        ),
        writeHint: (_) => throw StateError('storage blocked'),
      );

      final session = await service.session();

      expect(session.authenticated, isTrue);
      expect(session.offline, isFalse);
      expect(session.csrfToken, 'csrf-test');
    },
  );
}
