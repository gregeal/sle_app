import 'llm_client.dart';
import 'llm_config.dart';

/// How the app reaches AI providers. Mobile talks to the provider directly
/// with the user's own key; the web build will talk to the AI Broker
/// (P4 plan) so no long-lived credential ever reaches a browser.
abstract class AiGateway {
  /// Client for text features (drills, reading, writing, oral reports).
  Future<LlmClient> textClient();

  /// Whether this platform lets the user configure a provider key locally.
  bool get supportsDirectConfiguration;
}

/// Mobile behaviour, unchanged: build a client from the locally stored
/// provider configuration and API key.
class DirectProviderGateway implements AiGateway {
  DirectProviderGateway({
    required this.loadConfig,
    required this.loadApiKey,
  });

  final Future<LlmConfig> Function() loadConfig;
  final Future<String?> Function() loadApiKey;

  @override
  bool get supportsDirectConfiguration => true;

  @override
  Future<LlmClient> textClient() async =>
      clientFor(await loadConfig(), apiKey: await loadApiKey());
}

/// Placeholder for the web build until the AI Broker (P4-2/P4-3) exists.
/// Keeping keys out of the browser is the point of the broker, so the web
/// build refuses direct configuration instead of imitating mobile.
class WebPendingGateway implements AiGateway {
  const WebPendingGateway();

  @override
  bool get supportsDirectConfiguration => false;

  @override
  Future<LlmClient> textClient() async {
    throw const LlmException(
      'Sur le web, les fonctions IA passeront par un serveur sécurisé — '
      'à venir. Utilisez l\'application Android en attendant.',
    );
  }
}
