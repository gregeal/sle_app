import 'dart:convert';

import 'package:flutter/foundation.dart';

enum LlmProvider { openAiCompatible, openRouter, ollama, anthropic, custom }

class LlmConfig {
  const LlmConfig({
    required this.provider,
    required this.baseUrl,
    required this.model,
    required this.hasApiKey,
    this.realtimeModel = 'gpt-realtime',
    this.realtimeVoice = 'marin',
  });

  final LlmProvider provider;
  final String baseUrl;
  final String model;
  final bool hasApiKey;
  final String realtimeModel;
  final String realtimeVoice;

  factory LlmConfig.defaults() => LlmConfig(
    provider: LlmProvider.openAiCompatible,
    baseUrl: defaultBaseUrl(LlmProvider.openAiCompatible),
    model: '',
    hasApiKey: false,
    realtimeModel: 'gpt-realtime',
    realtimeVoice: 'marin',
  );
}

bool supportsOpenAiRealtime(LlmConfig config) {
  if (config.provider != LlmProvider.openAiCompatible) return false;
  final uri = Uri.tryParse(config.baseUrl);
  if (uri == null) return false;
  final usesDefaultPort = !uri.hasPort || uri.port == 443;
  final normalizedPath = uri.path.replaceFirst(RegExp(r'/+$'), '');
  return uri.scheme == 'https' &&
      uri.host == 'api.openai.com' &&
      usesDefaultPort &&
      normalizedPath == '/v1' &&
      uri.userInfo.isEmpty &&
      !uri.hasQuery &&
      !uri.hasFragment;
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

String normalizeBaseUrl(String value) {
  final uri = Uri.tryParse(value.trim());
  if (uri == null || !uri.hasScheme || !uri.hasAuthority) return value.trim();
  final scheme = uri.scheme.toLowerCase();
  final host = uri.host.toLowerCase();
  final defaultPort =
      (scheme == 'https' && uri.port == 443) ||
      (scheme == 'http' && uri.port == 80);
  final path = uri.path.replaceFirst(RegExp(r'/+$'), '');
  return Uri(
    scheme: scheme,
    host: host,
    port: defaultPort || !uri.hasPort ? null : uri.port,
    path: path,
    query: uri.hasQuery ? uri.query : null,
  ).toString();
}

String apiKeyStorageKey(LlmProvider provider, String baseUrl) {
  final identity = '${provider.name}|${normalizeBaseUrl(baseUrl)}';
  final encoded = base64Url.encode(utf8.encode(identity)).replaceAll('=', '');
  return 'llmApiKey.$encoded';
}

bool sameProviderDestination(
  LlmProvider firstProvider,
  String firstBaseUrl,
  LlmProvider secondProvider,
  String secondBaseUrl,
) =>
    firstProvider == secondProvider &&
    normalizeBaseUrl(firstBaseUrl) == normalizeBaseUrl(secondBaseUrl);

String? validateProviderEndpoint({
  required LlmProvider provider,
  required String baseUrl,
  required bool willSendApiKey,
}) {
  final uri = Uri.tryParse(baseUrl.trim());
  if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
    return 'Entrez une URL complète.';
  }
  if (uri.userInfo.isNotEmpty || uri.hasQuery || uri.hasFragment) {
    return 'L’URL ne doit contenir ni identifiants, ni paramètres, ni fragment.';
  }
  if (uri.scheme == 'https') return null;
  if (provider != LlmProvider.ollama || uri.scheme != 'http') {
    return 'Utilisez HTTPS pour protéger les données et la clé API.';
  }
  if (willSendApiKey) {
    return 'Une clé API ne peut pas être envoyée à une adresse HTTP.';
  }
  if (!kDebugMode && defaultTargetPlatform == TargetPlatform.android) {
    return 'Seule une version Android de débogage accepte Ollama en HTTP; '
        'les versions profile/publiées exigent un relais HTTPS.';
  }
  if (!_isPrivateHost(uri.host)) {
    return 'Ollama en HTTP doit utiliser une adresse locale ou privée.';
  }
  return null;
}

bool _isPrivateHost(String host) {
  final value = host.toLowerCase();
  if (value == 'localhost' || value == '::1') return true;
  final parts = value.split('.').map(int.tryParse).toList();
  if (parts.length != 4 || parts.any((part) => part == null)) return false;
  final first = parts[0]!;
  final second = parts[1]!;
  return first == 10 ||
      first == 127 ||
      (first == 192 && second == 168) ||
      (first == 172 && second >= 16 && second <= 31);
}
