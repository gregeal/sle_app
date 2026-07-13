import 'dart:convert';

import '../../data/db/daos.dart';
import '../../data/db/database.dart';
import 'llm_client.dart';

/// Prompt version — bump when the contract below changes so generated
/// content issues can be traced back to the prompt that produced them.
const drillPromptVersion = 1;

class GeneratedDrill {
  const GeneratedDrill({
    required this.topic,
    required this.prompt,
    required this.options,
    required this.correctIndex,
    required this.explanationFr,
  });

  final String topic;
  final String prompt;
  final List<String> options;
  final int correctIndex;
  final String explanationFr;
}

String buildDrillSystemPrompt() =>
    'Tu es un concepteur d\'exercices pour l\'Évaluation de langue seconde '
    '(ELS) de la Commission de la fonction publique du Canada, volet '
    'Expression écrite. Tu rédiges des questions à choix multiple en français '
    'canadien de registre professionnel (fonction publique fédérale : '
    'courriels, notes de service, réunions, dossiers). Tu réponds UNIQUEMENT '
    'avec du JSON valide, sans texte avant ni après.';

String buildDrillUserPrompt({
  required List<String> topics,
  required int count,
}) =>
    'Génère $count questions à choix multiple de type ELS. '
    'Chaque question porte sur un de ces sujets de grammaire (utilise la clé '
    'EXACTE) : ${topics.join(', ')}. '
    'Contraintes : phrase à compléter ou repérage d\'erreur en contexte de '
    'travail; exactement 4 options distinctes et plausibles; une seule '
    'bonne réponse; explication brève en français qui cite la règle. '
    'Réponds avec ce JSON exactement : '
    '{"items":[{"topic":"<clé du sujet>","prompt":"<question>",'
    '"options":["<a>","<b>","<c>","<d>"],"correctIndex":<0-3>,'
    '"explanationFr":"<explication>"}]}';

/// Parses the model reply, keeping only well-formed items on allowed topics.
/// Malformed individual items are dropped; an unparseable payload throws.
List<GeneratedDrill> parseGeneratedDrills(
  String raw, {
  required Set<String> allowedTopics,
}) {
  final Object? decoded;
  try {
    decoded = jsonDecode(_extractJson(raw));
  } on FormatException {
    throw const LlmException(
        'La réponse du fournisseur IA n\'était pas du JSON valide.');
  }

  final items = decoded is Map<String, dynamic> ? decoded['items'] : null;
  if (items is! List) {
    throw const LlmException(
        'La réponse du fournisseur IA ne contient pas de liste « items ».');
  }

  final drills = <GeneratedDrill>[];
  for (final item in items) {
    final drill = _validateItem(item, allowedTopics);
    if (drill != null) drills.add(drill);
  }
  return drills;
}

GeneratedDrill? _validateItem(Object? item, Set<String> allowedTopics) {
  if (item is! Map) return null;
  final topic = item['topic'];
  final prompt = item['prompt'];
  final options = item['options'];
  final correctIndex = item['correctIndex'];
  final explanation = item['explanationFr'];

  if (topic is! String || !allowedTopics.contains(topic)) return null;
  if (prompt is! String || prompt.trim().isEmpty) return null;
  if (explanation is! String || explanation.trim().isEmpty) return null;
  if (options is! List || options.length != 4) return null;
  final optionStrings = <String>[];
  for (final option in options) {
    if (option is! String || option.trim().isEmpty) return null;
    optionStrings.add(option);
  }
  if (optionStrings.toSet().length != 4) return null;
  if (correctIndex is! int || correctIndex < 0 || correctIndex > 3) {
    return null;
  }

  return GeneratedDrill(
    topic: topic,
    prompt: prompt,
    options: optionStrings,
    correctIndex: correctIndex,
    explanationFr: explanation,
  );
}

/// Models sometimes wrap JSON in ``` fences or add a sentence around it.
String _extractJson(String raw) {
  final start = raw.indexOf('{');
  final end = raw.lastIndexOf('}');
  if (start == -1 || end <= start) return raw;
  return raw.substring(start, end + 1);
}

/// Generates [count] drills for [topics] and stores the usable ones with
/// source 'generated'. Retries once on an unusable reply. Returns how many
/// items were inserted.
Future<int> generateDrills({
  required AppDatabase db,
  required LlmClient client,
  required List<String> topics,
  int count = 10,
}) async {
  final allowed = topics.toSet();
  var drills = const <GeneratedDrill>[];

  for (var attempt = 0; attempt < 2; attempt++) {
    final reply = await client.complete(
      system: buildDrillSystemPrompt(),
      user: buildDrillUserPrompt(topics: topics, count: count),
      temperature: 0.8,
      maxTokens: 4000,
    );
    try {
      drills = parseGeneratedDrills(reply, allowedTopics: allowed);
    } on LlmException {
      if (attempt == 1) rethrow;
      continue;
    }
    if (drills.isNotEmpty) break;
  }

  if (drills.isEmpty) {
    throw const LlmException(
        'Le fournisseur IA n\'a produit aucun exercice utilisable. Réessayez.');
  }

  await db.transaction(() async {
    for (final drill in drills) {
      await db.insertDrillItem(
        topic: drill.topic,
        prompt: drill.prompt,
        options: drill.options,
        correctIndex: drill.correctIndex,
        explanationFr: drill.explanationFr,
        source: 'generated',
      );
    }
  });
  return drills.length;
}
