enum LlmProvider { openAiCompatible, openRouter, ollama, anthropic, custom }

class LlmConfig {
  const LlmConfig({
    required this.provider,
    required this.baseUrl,
    required this.model,
    required this.hasApiKey,
  });

  final LlmProvider provider;
  final String baseUrl;
  final String model;
  final bool hasApiKey;

  factory LlmConfig.defaults() => LlmConfig(
    provider: LlmProvider.openAiCompatible,
    baseUrl: defaultBaseUrl(LlmProvider.openAiCompatible),
    model: '',
    hasApiKey: false,
  );
}

String providerLabel(LlmProvider provider) => switch (provider) {
  LlmProvider.openAiCompatible => 'OpenAI compatible',
  LlmProvider.openRouter => 'OpenRouter',
  LlmProvider.ollama => 'Ollama local',
  LlmProvider.anthropic => 'Anthropic',
  LlmProvider.custom => 'Personnalisé',
};

String defaultBaseUrl(LlmProvider provider) => switch (provider) {
  LlmProvider.openAiCompatible => 'https://api.openai.com/v1',
  LlmProvider.openRouter => 'https://openrouter.ai/api/v1',
  LlmProvider.ollama => 'http://10.0.2.2:11434/v1',
  LlmProvider.anthropic => 'https://api.anthropic.com',
  LlmProvider.custom => '',
};

LlmProvider providerFromStorage(String? value) =>
    LlmProvider.values
        .where((provider) => provider.name == value)
        .firstOrNull ??
    LlmProvider.openAiCompatible;
