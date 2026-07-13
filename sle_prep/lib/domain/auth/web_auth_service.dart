import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'browser_bridge.dart';

class WebAuthException implements Exception {
  const WebAuthException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class WebAuthSession {
  const WebAuthSession({
    required this.authenticated,
    required this.googleEnabled,
    required this.passkeysEnabled,
    this.email,
    this.userId,
    this.csrfToken,
    this.passkeyCount = 0,
    this.offline = false,
  });

  final bool authenticated;
  final bool googleEnabled;
  final bool passkeysEnabled;
  final String? email;
  final String? userId;
  final String? csrfToken;
  final int passkeyCount;
  final bool offline;

  bool get canCallBroker => authenticated && !offline && csrfToken != null;
}

class WebAuthService {
  WebAuthService({
    http.Client? httpClient,
    Uri? baseUri,
    String? Function()? readHint,
    void Function(String?)? writeHint,
  }) : _http = httpClient ?? http.Client(),
       _ownsClient = httpClient == null,
       _baseUri = baseUri ?? Uri.base,
       _readHint = readHint ?? readAuthHint,
       _writeHint = writeHint ?? writeAuthHint;

  final http.Client _http;
  final bool _ownsClient;
  final Uri _baseUri;
  final String? Function() _readHint;
  final void Function(String?) _writeHint;

  Future<WebAuthSession> session() async {
    try {
      final response = await _http
          .get(_uri('/api/auth/session'))
          .timeout(const Duration(seconds: 15));
      final payload = _decode(response);
      if (response.statusCode != 200) {
        if (response.statusCode >= 500) return _offlineSessionOrRethrow();
        throw _error(response, payload);
      }
      final authenticatedValue = payload['authenticated'];
      if (authenticatedValue is! bool) return _offlineSessionOrRethrow();
      final authenticated = authenticatedValue;
      final email = payload['email'] is String
          ? payload['email'] as String
          : null;
      final userId = payload['userId'] is String
          ? payload['userId'] as String
          : null;
      final csrfToken = payload['csrfToken'] is String
          ? payload['csrfToken'] as String
          : null;
      if (authenticated &&
          _validUserId(userId) &&
          (csrfToken?.isNotEmpty ?? false)) {
        _writeAuthHintSafely(
          encodeOfflineProfileHint(
            userId!,
            DateTime.now().add(offlineProfileTtl),
          ),
        );
      } else if (authenticated) {
        return _offlineSessionOrRethrow();
      } else {
        _writeAuthHintSafely(null);
      }
      return WebAuthSession(
        authenticated: authenticated,
        email: email,
        userId: userId,
        csrfToken: csrfToken,
        googleEnabled: payload['googleEnabled'] == true,
        passkeysEnabled:
            payload['passkeysEnabled'] == true && browserSupportsPasskeys,
        passkeyCount: (payload['passkeyCount'] as num?)?.toInt() ?? 0,
      );
    } on http.ClientException {
      return _offlineSessionOrRethrow();
    } on TimeoutException {
      return _offlineSessionOrRethrow();
    }
  }

  WebAuthSession _offlineSessionOrRethrow() {
    final hint = decodeOfflineProfileHint(
      _readAuthHintSafely(),
      now: DateTime.now(),
    );
    if (hint != null) {
      return WebAuthSession(
        authenticated: true,
        userId: hint.userId,
        googleEnabled: false,
        passkeysEnabled: false,
        offline: true,
      );
    }
    throw const WebAuthException(
      'Le serveur sécurisé est inaccessible et aucune session hors ligne '
      'n’est disponible.',
    );
  }

  void signInWithGoogle() =>
      navigateBrowser(_uri('/auth/google/start').toString());

  Future<void> signInWithPasskey(String email) async {
    final options = await _post(
      '/api/auth/passkeys/login/options',
      body: {'email': email.trim().toLowerCase()},
    );
    final credential = jsonDecode(
      await getPasskey(jsonEncode(options['publicKey'])),
    );
    await _post(
      '/api/auth/passkeys/login/finish',
      body: {'challenge_id': options['challengeId'], 'credential': credential},
    );
  }

  Future<void> registerPasskey(WebAuthSession session) async {
    final csrf = _requireCsrf(session);
    final options = await _post(
      '/api/auth/passkeys/register/options',
      csrfToken: csrf,
    );
    final credential = jsonDecode(
      await createPasskey(jsonEncode(options['publicKey'])),
    );
    await _post(
      '/api/auth/passkeys/register/finish',
      csrfToken: csrf,
      body: {'challenge_id': options['challengeId'], 'credential': credential},
    );
  }

  Future<void> logout(WebAuthSession session) async {
    final response = await _postResponse(
      '/api/auth/logout',
      headers: {'X-CSRF-Token': _requireCsrf(session)},
    );
    if (response.statusCode != 204) {
      throw _error(response, _decode(response));
    }
    _writeAuthHintSafely(null);
  }

  Future<Map<String, dynamic>> postBroker(
    String path, {
    required WebAuthSession session,
    required Map<String, dynamic> body,
  }) => _post(path, csrfToken: _requireCsrf(session), body: body);

  Future<Map<String, dynamic>> _post(
    String path, {
    String? csrfToken,
    Map<String, dynamic>? body,
  }) async {
    final response = await _postResponse(
      path,
      headers: {'Content-Type': 'application/json', 'X-CSRF-Token': ?csrfToken},
      body: jsonEncode(body ?? const <String, dynamic>{}),
    );
    final payload = _decode(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _error(response, payload);
    }
    return payload;
  }

  Future<http.Response> _postResponse(
    String path, {
    required Map<String, String> headers,
    String? body,
  }) async {
    try {
      return await _http
          .post(_uri(path), headers: headers, body: body)
          .timeout(const Duration(seconds: 45));
    } on TimeoutException {
      throw const WebAuthException(
        'Le serveur sécurisé n’a pas répondu à temps.',
      );
    } on http.ClientException catch (error) {
      throw WebAuthException('Connexion impossible : ${error.message}');
    }
  }

  String _requireCsrf(WebAuthSession session) {
    if (!session.canCallBroker) {
      throw const WebAuthException(
        'La session web est hors ligne ou expirée. Reconnectez-vous.',
        statusCode: 401,
      );
    }
    return session.csrfToken!;
  }

  Uri _uri(String path) => _baseUri.resolve(path);

  Map<String, dynamic> _decode(http.Response response) {
    try {
      final value = jsonDecode(utf8.decode(response.bodyBytes));
      return value is Map<String, dynamic> ? value : const <String, dynamic>{};
    } on FormatException {
      return const <String, dynamic>{};
    }
  }

  WebAuthException _error(
    http.Response response,
    Map<String, dynamic> payload,
  ) => WebAuthException(
    payload['detail'] is String
        ? payload['detail'] as String
        : 'Le serveur sécurisé n’a pas pu traiter la demande.',
    statusCode: response.statusCode,
  );

  void close() {
    if (_ownsClient) _http.close();
  }

  String? _readAuthHintSafely() {
    try {
      return _readHint();
    } catch (_) {
      return null;
    }
  }

  void _writeAuthHintSafely(String? value) {
    try {
      _writeHint(value);
    } catch (_) {
      // localStorage can be unavailable in restricted/private browser modes.
      // A cache failure must not invalidate a valid server session or logout.
    }
  }
}

const offlineProfileTtl = Duration(days: 7);

class OfflineProfileHint {
  const OfflineProfileHint({required this.userId, required this.expiresAt});

  final String userId;
  final DateTime expiresAt;
}

String encodeOfflineProfileHint(String userId, DateTime expiresAt) =>
    jsonEncode({
      'version': 1,
      'userId': userId,
      'expiresAt': expiresAt.toUtc().toIso8601String(),
    });

OfflineProfileHint? decodeOfflineProfileHint(
  String? source, {
  required DateTime now,
}) {
  if (source == null || source.isEmpty) return null;
  try {
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic> || decoded['version'] != 1) {
      return null;
    }
    final userId = decoded['userId'];
    final expiresAt = DateTime.tryParse(decoded['expiresAt'] as String? ?? '');
    if (!_validUserId(userId) || expiresAt == null) return null;
    final utcNow = now.toUtc();
    final utcExpiry = expiresAt.toUtc();
    // Reject expired and implausibly extended values. localStorage is a
    // convenience for an offline profile, never a broker authentication token.
    if (!utcExpiry.isAfter(utcNow) ||
        utcExpiry.isAfter(
          utcNow.add(offlineProfileTtl + const Duration(hours: 1)),
        )) {
      return null;
    }
    return OfflineProfileHint(userId: userId as String, expiresAt: utcExpiry);
  } catch (_) {
    return null;
  }
}

bool _validUserId(Object? value) =>
    value is String && RegExp(r'^sle_[0-9a-f]{64}$').hasMatch(value);
