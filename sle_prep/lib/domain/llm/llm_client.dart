import 'anthropic_client.dart';
import 'llm_config.dart';
import 'openai_compatible_client.dart';

/// A single failure type for every provider so the UI can show one clear,
/// user-facing message regardless of which backend failed.
class LlmException implements Exception {
  const LlmException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() =>
      statusCode == null ? message : '$message (HTTP $statusCode)';
}

abstract class LlmClient {
  /// Sends one system+user exchange and returns the assistant's text.
  Future<String> complete({
    required String system,
    required String user,
    double temperature = 0.7,
    int? maxTokens,
  });
}

/// Implemented only by clients that own transport resources.
abstract interface class ClosableLlmClient {
  void close();
}

void closeLlmClient(LlmClient client) {
  if (client case ClosableLlmClient closable) closable.close();
}

extension LlmConnectionTest on LlmClient {
  /// Cheap round-trip used by the settings screen's "Tester la connexion".
  Future<void> testConnection() => complete(
    system: 'Réponds uniquement « OK ».',
    user: 'Test de connexion.',
    temperature: 0,
    maxTokens: 16,
  );
}

/// Builds the right client for the stored configuration.
///
/// Every provider except a local Ollama needs an API key; failing fast here
/// gives the settings screen a precise French error instead of a 401 later.
LlmClient clientFor(LlmConfig config, {required String? apiKey}) {
  final needsKey = config.provider != LlmProvider.ollama;
  final endpointError = validateProviderEndpoint(
    provider: config.provider,
    baseUrl: config.baseUrl,
    willSendApiKey: needsKey && (apiKey?.isNotEmpty ?? false),
  );
  if (endpointError != null) throw LlmException(endpointError);
  if (needsKey && (apiKey == null || apiKey.isEmpty)) {
    throw const LlmException(
      'Aucune clé API enregistrée. Ajoutez votre clé dans les paramètres.',
    );
  }

  return switch (config.provider) {
    LlmProvider.anthropic => AnthropicClient(
      baseUrl: config.baseUrl,
      model: config.model,
      apiKey: apiKey!,
    ),
    _ => OpenAiCompatibleClient(
      baseUrl: config.baseUrl,
      model: config.model,
      apiKey: config.provider == LlmProvider.ollama ? null : apiKey,
    ),
  };
}
