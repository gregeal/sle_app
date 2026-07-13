import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/daos.dart';
import '../../domain/llm/llm_client.dart';
import '../../domain/llm/llm_config.dart';
import '../../domain/realtime/openai_realtime_api.dart';
import '../../providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(aiGatewayProvider).supportsDirectConfiguration) {
      return const SafeArea(child: _WebSettingsPanel());
    }
    final config = ref.watch(llmConfigProvider);
    return SafeArea(
      child: config.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (value) => _SettingsForm(
          key: ValueKey(
            '${value.provider.name}-${value.baseUrl}-${value.model}',
          ),
          config: value,
        ),
      ),
    );
  }
}

class _SettingsForm extends ConsumerStatefulWidget {
  const _SettingsForm({super.key, required this.config});

  final LlmConfig config;

  @override
  ConsumerState<_SettingsForm> createState() => _SettingsFormState();
}

class _SettingsFormState extends ConsumerState<_SettingsForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _baseUrlController;
  late final TextEditingController _modelController;
  late final TextEditingController _realtimeModelController;
  final _apiKeyController = TextEditingController();
  late LlmProvider _provider;
  late String _realtimeVoice;
  String? _draftKeyDestination;
  var _isSaving = false;
  var _isTesting = false;

  String get _currentDestination =>
      apiKeyStorageKey(_provider, _baseUrlController.text);

  bool get _hasBoundDraftKey =>
      _apiKeyController.text.trim().isNotEmpty &&
      _draftKeyDestination == _currentDestination;

  bool get _destinationChanged => !sameProviderDestination(
    widget.config.provider,
    widget.config.baseUrl,
    _provider,
    _baseUrlController.text,
  );

  bool get _draftWillSendKey =>
      _provider != LlmProvider.ollama &&
      (_hasBoundDraftKey || (!_destinationChanged && widget.config.hasApiKey));

  void _clearDraftKeyIfDestinationChanged() {
    if (_apiKeyController.text.isNotEmpty &&
        _draftKeyDestination != _currentDestination) {
      _apiKeyController.clear();
      _draftKeyDestination = null;
    }
  }

  @override
  void initState() {
    super.initState();
    _provider = widget.config.provider;
    _baseUrlController = TextEditingController(text: widget.config.baseUrl);
    _modelController = TextEditingController(text: widget.config.model);
    _realtimeModelController = TextEditingController(
      text: widget.config.realtimeModel,
    );
    _realtimeVoice = widget.config.realtimeVoice;
  }

  @override
  void dispose() {
    _baseUrlController.dispose();
    _modelController.dispose();
    _realtimeModelController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isTesting = true);
    LlmClient? client;
    try {
      final baseUrl = normalizeBaseUrl(_baseUrlController.text);
      var apiKey = _hasBoundDraftKey ? _apiKeyController.text.trim() : '';
      if (apiKey.isEmpty && !_destinationChanged) {
        apiKey =
            await ref
                .read(secureStorageProvider)
                .read(key: apiKeyStorageKey(_provider, baseUrl)) ??
            '';
      }
      client = clientFor(
        LlmConfig(
          provider: _provider,
          baseUrl: baseUrl,
          model: _modelController.text.trim(),
          hasApiKey: apiKey.isNotEmpty,
          realtimeModel: _realtimeModelController.text.trim(),
          realtimeVoice: _realtimeVoice,
        ),
        apiKey: apiKey,
      );
      await client.testConnection();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Connexion réussie : le fournisseur IA répond.'),
          ),
        );
      }
    } on LlmException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Échec du test : $error')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Échec du test : $error')));
      }
    } finally {
      if (client != null) closeLlmClient(client);
      if (mounted) setState(() => _isTesting = false);
    }
  }

  Future<void> _persist() async {
    final database = ref.read(appDatabaseProvider);
    final baseUrl = normalizeBaseUrl(_baseUrlController.text);
    final draftKey = _hasBoundDraftKey ? _apiKeyController.text.trim() : '';
    if (draftKey.isNotEmpty) {
      await ref
          .read(secureStorageProvider)
          .write(key: apiKeyStorageKey(_provider, baseUrl), value: draftKey);
    }
    await database.transaction(() async {
      await database.setSetting('llmProvider', _provider.name);
      await database.setSetting('llmBaseUrl', baseUrl);
      await database.setSetting('llmModel', _modelController.text.trim());
      await database.setSetting(
        'realtimeModel',
        _realtimeModelController.text.trim(),
      );
      await database.setSetting('realtimeVoice', _realtimeVoice);
    });
    _apiKeyController.clear();
    _draftKeyDestination = null;
    ref.invalidate(llmConfigProvider);
    ref.invalidate(llmClientProvider);
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSaving = true);
    try {
      await _persist();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Paramètres IA enregistrés localement.'),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Enregistrement impossible : $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteKey() async {
    setState(() => _isSaving = true);
    try {
      await ref
          .read(secureStorageProvider)
          .delete(
            key: apiKeyStorageKey(
              widget.config.provider,
              widget.config.baseUrl,
            ),
          );
      await ref.read(secureStorageProvider).delete(key: 'llmApiKey');
      ref.invalidate(llmConfigProvider);
      ref.invalidate(llmClientProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Clé API supprimée de cet appareil.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Suppression impossible : $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Form(
    key: _formKey,
    child: ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      children: [
        Text('Paramètres', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 4),
        const Text('Toutes les données d’étude restent sur cet appareil.'),
        const SizedBox(height: 24),
        Text('FOURNISSEUR IA', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        DropdownButtonFormField<LlmProvider>(
          initialValue: _provider,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Fournisseur',
          ),
          items: LlmProvider.values
              .map(
                (provider) => DropdownMenuItem(
                  value: provider,
                  child: Text(providerLabel(provider)),
                ),
              )
              .toList(growable: false),
          onChanged: _isSaving
              ? null
              : (provider) {
                  if (provider == null) return;
                  setState(() {
                    _provider = provider;
                    _baseUrlController.text = defaultBaseUrl(provider);
                    _clearDraftKeyIfDestinationChanged();
                  });
                },
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _baseUrlController,
          enabled: !_isSaving,
          keyboardType: TextInputType.url,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: 'URL de base',
            hintText: 'https://…',
            helperMaxLines: 3,
            helperText: _provider == LlmProvider.ollama
                ? 'Sur un téléphone physique, utilisez l’adresse IP de votre '
                      'PC sur le réseau local (p. ex. '
                      'http://192.168.1.10:11434/v1). L’adresse 10.0.2.2 ne '
                      'fonctionne que sur l’émulateur Android. HTTP local est '
                      'réservé au développement; une version Android publiée '
                      'doit passer par un relais HTTPS.'
                : null,
          ),
          validator: (value) {
            return validateProviderEndpoint(
              provider: _provider,
              baseUrl: value?.trim() ?? '',
              willSendApiKey: _draftWillSendKey,
            );
          },
          onChanged: (_) {
            _clearDraftKeyIfDestinationChanged();
            setState(() {});
          },
        ),
        if (_provider == LlmProvider.openAiCompatible) ...[
          const SizedBox(height: 24),
          Text(
            'ENTREVUE VOIX-À-VOIX',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _realtimeModelController,
            enabled: !_isSaving,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Modèle Realtime',
              hintText: defaultRealtimeModel,
              helperText:
                  'Distinct du modèle texte. Utilisé uniquement par le coach en direct.',
            ),
            validator: (value) =>
                _provider == LlmProvider.openAiCompatible &&
                    (value == null || value.trim().isEmpty)
                ? 'Entrez le modèle Realtime.'
                : null,
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: realtimeVoices.contains(_realtimeVoice)
                ? _realtimeVoice
                : defaultRealtimeVoice,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Voix de l’évaluatrice',
            ),
            items: realtimeVoices
                .map(
                  (voice) => DropdownMenuItem(value: voice, child: Text(voice)),
                )
                .toList(growable: false),
            onChanged: _isSaving
                ? null
                : (voice) {
                    if (voice != null) {
                      setState(() => _realtimeVoice = voice);
                    }
                  },
          ),
          const SizedBox(height: 10),
          const Text(
            'Le mode Realtime fonctionne avec l’API OpenAI officielle. '
            'Pour cette application personnelle, la clé enregistrée demande '
            'un jeton de session de courte durée. Ne préchargez jamais une clé '
            'dans une APK distribuée à d’autres personnes.',
            style: TextStyle(fontSize: 12.5),
          ),
        ],
        const SizedBox(height: 14),
        TextFormField(
          controller: _modelController,
          enabled: !_isSaving,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Nom du modèle',
            hintText: 'Choisissez un modèle disponible chez votre fournisseur',
          ),
          validator: (value) => value == null || value.trim().isEmpty
              ? 'Entrez le nom du modèle.'
              : null,
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _apiKeyController,
          enabled: !_isSaving && _provider != LlmProvider.ollama,
          obscureText: true,
          autocorrect: false,
          enableSuggestions: false,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: _provider == LlmProvider.ollama
                ? 'Clé API non requise'
                : widget.config.hasApiKey
                ? 'Nouvelle clé API (facultatif)'
                : 'Clé API',
            helperText: _provider == LlmProvider.ollama
                ? 'SLE Prep n’envoie jamais de clé à Ollama.'
                : widget.config.hasApiKey
                ? _destinationChanged
                      ? 'La destination a changé : entrez sa propre clé. '
                            'L’ancienne ne sera jamais transférée.'
                      : 'Une clé est déjà enregistrée pour cette destination. '
                            'Laissez vide pour la conserver.'
                : 'Stockée dans le stockage chiffré Android.',
          ),
          onChanged: (value) {
            setState(() {
              _draftKeyDestination = value.trim().isEmpty
                  ? null
                  : _currentDestination;
            });
          },
          validator: (value) {
            if (_provider == LlmProvider.ollama) return null;
            if ((value?.trim().isEmpty ?? true) &&
                (_destinationChanged || !widget.config.hasApiKey)) {
              return 'Entrez la clé propre à cette destination.';
            }
            return null;
          },
        ),
        if (widget.config.hasApiKey && !_destinationChanged) ...[
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _isSaving || _isTesting ? null : _deleteKey,
            icon: const Icon(Icons.delete_outline),
            label: const Text('Supprimer la clé enregistrée'),
          ),
        ],
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: _isSaving || _isTesting ? null : _save,
          icon: const Icon(Icons.save_outlined),
          label: Text(_isSaving ? 'Enregistrement…' : 'Enregistrer'),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: _isSaving || _isTesting ? null : _testConnection,
          icon: _isTesting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.wifi_tethering),
          label: Text(_isTesting ? 'Test en cours…' : 'Tester la connexion'),
        ),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Coûts et confidentialité',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Le vocabulaire et la grammaire restent hors ligne. Les '
                  'fonctions IA envoient uniquement le contenu nécessaire au '
                  'fournisseur configuré. Les entrevues Realtime transmettent '
                  'l’audio à OpenAI et sont facturées séparément des fonctions '
                  'texte; consultez toujours la tarification actuelle avant '
                  'une longue session.',
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _WebSettingsPanel extends ConsumerStatefulWidget {
  const _WebSettingsPanel();

  @override
  ConsumerState<_WebSettingsPanel> createState() => _WebSettingsPanelState();
}

class _WebSettingsPanelState extends ConsumerState<_WebSettingsPanel> {
  var _busy = false;

  Future<void> _registerPasskey() async {
    final session = await ref.read(webAuthSessionProvider.future);
    setState(() => _busy = true);
    try {
      await ref.read(webAuthServiceProvider).registerPasskey(session);
      ref.invalidate(webAuthSessionProvider);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Passkey enregistrée.')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Impossible d’enregistrer la passkey : $error'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _logout() async {
    final session = await ref.read(webAuthSessionProvider.future);
    setState(() => _busy = true);
    try {
      await ref.read(webAuthServiceProvider).logout(session);
      ref.invalidate(webAuthSessionProvider);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Déconnexion impossible : $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(webAuthSessionProvider);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      children: [
        Text('Paramètres', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: auth.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Text('$error'),
              data: (session) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.verified_user_outlined,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Compte web sécurisé',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(session.email ?? 'Compte autorisé'),
                  const SizedBox(height: 8),
                  Text(
                    session.offline
                        ? 'Mode hors ligne. Les fonctions IA sont temporairement indisponibles.'
                        : 'Les appels IA passent par le serveur sécurisé. Aucune clé API n’est stockée dans ce navigateur.',
                  ),
                  if (session.passkeysEnabled && !session.offline) ...[
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      onPressed: _busy ? null : _registerPasskey,
                      icon: const Icon(Icons.fingerprint),
                      label: Text(
                        session.passkeyCount == 0
                            ? 'Créer une passkey'
                            : 'Ajouter une autre passkey (${session.passkeyCount})',
                      ),
                    ),
                  ],
                  if (!session.offline) ...[
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: _busy ? null : _logout,
                      icon: const Icon(Icons.logout),
                      label: const Text('Se déconnecter'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Card(
          child: Padding(
            padding: EdgeInsets.all(18),
            child: Text(
              'Votre vocabulaire, vos résultats et votre progression restent '
              'dans ce navigateur. Le serveur impose une limite de fréquence '
              'et des plafonds de dépenses avant chaque appel IA. Les '
              'estimations de niveau demeurent non officielles.',
            ),
          ),
        ),
      ],
    );
  }
}
