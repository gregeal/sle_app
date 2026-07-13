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
  var _isSaving = false;
  var _isTesting = false;

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
    try {
      // Persist the form first so the test exercises exactly what will be used.
      await _persist();
      final client = await ref.read(llmClientProvider.future);
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
      if (mounted) setState(() => _isTesting = false);
    }
  }

  Future<void> _persist() async {
    final database = ref.read(appDatabaseProvider);
    await database.setSetting('llmProvider', _provider.name);
    await database.setSetting('llmBaseUrl', _baseUrlController.text.trim());
    await database.setSetting('llmModel', _modelController.text.trim());
    await database.setSetting(
      'realtimeModel',
      _realtimeModelController.text.trim(),
    );
    await database.setSetting('realtimeVoice', _realtimeVoice);
    if (_apiKeyController.text.trim().isNotEmpty) {
      await ref
          .read(secureStorageProvider)
          .write(key: 'llmApiKey', value: _apiKeyController.text.trim());
    }
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
                      'fonctionne que sur l’émulateur Android.'
                : null,
          ),
          validator: (value) {
            final uri = Uri.tryParse(value?.trim() ?? '');
            if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
              return 'Entrez une URL complète.';
            }
            return null;
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
          enabled: !_isSaving,
          obscureText: true,
          autocorrect: false,
          enableSuggestions: false,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: widget.config.hasApiKey
                ? 'Nouvelle clé API (facultatif)'
                : 'Clé API',
            helperText: widget.config.hasApiKey
                ? 'Une clé est déjà enregistrée. Laissez vide pour la conserver.'
                : 'Stockée dans le stockage chiffré Android.',
          ),
        ),
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
