import '../auth/web_auth_service.dart';
import '../realtime/openai_realtime_api.dart';
import '../realtime/realtime_voice_session.dart';
import 'llm_client.dart';
import 'llm_config.dart';

/// How the app reaches AI providers. Mobile talks to the provider directly
/// with the user's own key; the web build will talk to the AI Broker
/// (P4 plan) so no long-lived credential ever reaches a browser.
abstract class AiGateway {
  /// Client for text features (drills, reading, writing, oral reports).
  Future<LlmClient> textClient();

  /// Creates a short-lived credential for a Realtime WebRTC connection.
  Future<String> realtimeClientSecret({
    required String model,
    required String voice,
  });

  /// Whether this platform lets the user configure a provider key locally.
  bool get supportsDirectConfiguration;
}

/// Mobile behaviour, unchanged: build a client from the locally stored
/// provider configuration and API key.
class DirectProviderGateway implements AiGateway {
  DirectProviderGateway({required this.loadConfig, required this.loadApiKey});

  final Future<LlmConfig> Function() loadConfig;
  final Future<String?> Function(LlmConfig config) loadApiKey;

  @override
  bool get supportsDirectConfiguration => true;

  @override
  Future<LlmClient> textClient() async {
    final config = await loadConfig();
    return clientFor(config, apiKey: await loadApiKey(config));
  }

  @override
  Future<String> realtimeClientSecret({
    required String model,
    required String voice,
  }) async {
    final config = await loadConfig();
    if (!supportsOpenAiRealtime(config)) {
      throw const RealtimeVoiceException(
        'L’entrevue en direct nécessite l’API OpenAI officielle.',
      );
    }
    final apiKey = (await loadApiKey(config))?.trim() ?? '';
    if (apiKey.isEmpty) {
      throw const RealtimeVoiceException(
        'Ajoutez d’abord votre clé API OpenAI dans les paramètres.',
      );
    }
    final api = OpenAiRealtimeApi(baseUrl: config.baseUrl, apiKey: apiKey);
    try {
      return await api.createClientSecret(model: model, voice: voice);
    } finally {
      api.close();
    }
  }
}

/// Web behavior: the same-origin broker owns the long-lived provider key and
/// authenticates requests through an HttpOnly cookie plus a CSRF header.
class BrokerGateway implements AiGateway {
  BrokerGateway({required this.auth, required this.loadSession});

  final WebAuthService auth;
  final Future<WebAuthSession> Function() loadSession;

  @override
  bool get supportsDirectConfiguration => false;

  @override
  Future<LlmClient> textClient() async =>
      BrokerLlmClient(auth: auth, session: await loadSession());

  @override
  Future<String> realtimeClientSecret({
    required String model,
    required String voice,
  }) async {
    try {
      final payload = await auth.postBroker(
        '/api/realtime/session',
        session: await loadSession(),
        body: {'model': model, 'voice': voice},
      );
      final value = payload['value'];
      if (value is! String || value.isEmpty) {
        throw const RealtimeVoiceException(
          'Le serveur sécurisé n’a pas retourné de jeton Realtime.',
        );
      }
      return value;
    } on WebAuthException catch (error) {
      throw RealtimeVoiceException(error.message, statusCode: error.statusCode);
    }
  }
}

class BrokerLlmClient implements LlmClient {
  BrokerLlmClient({required this.auth, required this.session});

  final WebAuthService auth;
  final WebAuthSession session;

  @override
  Future<String> complete({
    required String system,
    required String user,
    double temperature = 0.7,
    int? maxTokens,
  }) async {
    try {
      final payload = await auth.postBroker(
        '/api/chat',
        session: session,
        body: {
          'system': system,
          'user': user,
          'temperature': temperature,
          'max_tokens': ?maxTokens,
        },
      );
      final text = payload['text'];
      if (text is! String || text.trim().isEmpty) {
        throw const LlmException(
          'Le serveur sécurisé a retourné une réponse vide.',
        );
      }
      return text.trim();
    } on WebAuthException catch (error) {
      throw LlmException(error.message, statusCode: error.statusCode);
    }
  }
}
