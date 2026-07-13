import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/daos.dart';
import '../../domain/llm/llm_config.dart';
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
  final _apiKeyController = TextEditingController();
  late LlmProvider _provider;
  var _isSaving = false;

  @override
  void initState() {
    super.initState();
    _provider = widget.config.provider;
    _baseUrlController = TextEditingController(text: widget.config.baseUrl);
    _modelController = TextEditingController(text: widget.config.model);
  }

  @override
  void dispose() {
    _baseUrlController.dispose();
    _modelController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSaving = true);
    try {
      final database = ref.read(appDatabaseProvider);
      await database.setSetting('llmProvider', _provider.name);
      await database.setSetting('llmBaseUrl', _baseUrlController.text.trim());
      await database.setSetting('llmModel', _modelController.text.trim());
      if (_apiKeyController.text.trim().isNotEmpty) {
        await ref
            .read(secureStorageProvider)
            .write(key: 'llmApiKey', value: _apiKeyController.text.trim());
      }
      ref.invalidate(llmConfigProvider);
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
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'URL de base',
            hintText: 'https://…',
          ),
          validator: (value) {
            final uri = Uri.tryParse(value?.trim() ?? '');
            if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
              return 'Entrez une URL complète.';
            }
            return null;
          },
        ),
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
          onPressed: _isSaving ? null : _save,
          icon: const Icon(Icons.save_outlined),
          label: Text(_isSaving ? 'Enregistrement…' : 'Enregistrer'),
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
                  'Le vocabulaire et la grammaire restent hors ligne. Une clé sera utilisée seulement pour les futures fonctions de génération et de rétroaction. Prévoyez un budget mensuel d’environ 15 \$ pour les fonctions texte; les simulations orales en temps réel sont distinctes.',
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
