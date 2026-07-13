import 'dart:convert';

import '../../data/db/daos.dart';
import '../../data/db/database.dart';
import 'llm_client.dart';

const readingPromptVersion = 1;

const readingKinds = ['note_service', 'courriel', 'politique', 'article'];

class GeneratedReadingSet {
  const GeneratedReadingSet({
    required this.title,
    required this.kind,
    required this.bodyFr,
    required this.questions,
  });

  final String title;
  final String kind;
  final String bodyFr;
  final List<Map<String, dynamic>> questions;
}

String buildReadingSystemPrompt() =>
    'Tu es un concepteur d\'épreuves de compréhension de l\'écrit pour '
    'l\'Évaluation de langue seconde (ELS) de la Commission de la fonction '
    'publique du Canada. Tu rédiges des textes administratifs authentiques en '
    'français canadien (fonction publique fédérale) et des questions à choix '
    'multiple qui testent la compréhension globale, les détails, l\'inférence '
    'et le vocabulaire en contexte. Tu réponds UNIQUEMENT avec du JSON '
    'valide, sans texte avant ni après.';

String buildReadingUserPrompt({required String themeFr, required String kind}) =>
    'Rédige UN texte de type « $kind » (250 à 400 mots) lié au thème '
    '« $themeFr », puis 5 questions à choix multiple sur ce texte. '
    'Chaque question : 4 options distinctes et plausibles, une seule bonne '
    'réponse, et une explication brève. Réponds avec ce JSON exactement : '
    '{"title":"<titre>","kind":"$kind","bodyFr":"<texte>",'
    '"questions":[{"prompt":"<question>","options":["<a>","<b>","<c>","<d>"],'
    '"correctIndex":<0-3>,"explanationFr":"<explication>"}]}';

/// Parses and validates a generated reading set. Individual malformed
/// questions are dropped; fewer than three usable questions, a missing
/// field, or a too-short passage throws.
GeneratedReadingSet parseGeneratedReadingSet(String raw) {
  final Object? decoded;
  try {
    decoded = jsonDecode(_extractJson(raw));
  } on FormatException {
    throw const LlmException(
        'La réponse du fournisseur IA n\'était pas du JSON valide.');
  }
  if (decoded is! Map<String, dynamic>) {
    throw const LlmException('Réponse inattendue du fournisseur IA.');
  }

  final title = decoded['title'];
  final kind = decoded['kind'];
  final bodyFr = decoded['bodyFr'];
  final rawQuestions = decoded['questions'];
  if (title is! String || title.trim().isEmpty) {
    throw const LlmException('Le texte généré n\'a pas de titre.');
  }
  if (kind is! String || kind.trim().isEmpty) {
    throw const LlmException('Le texte généré n\'a pas de genre.');
  }
  if (bodyFr is! String || bodyFr.trim().length < 200) {
    throw const LlmException(
        'Le texte généré est trop court pour une lecture de type ELS.');
  }
  if (rawQuestions is! List) {
    throw const LlmException('Le texte généré n\'a pas de questions.');
  }

  final questions = <Map<String, dynamic>>[];
  for (final question in rawQuestions) {
    final valid = _validateQuestion(question);
    if (valid != null) questions.add(valid);
  }
  if (questions.length < 3) {
    throw const LlmException(
        'Trop peu de questions utilisables dans le texte généré.');
  }

  return GeneratedReadingSet(
    title: title,
    kind: kind,
    bodyFr: bodyFr,
    questions: questions,
  );
}

Map<String, dynamic>? _validateQuestion(Object? question) {
  if (question is! Map) return null;
  final prompt = question['prompt'];
  final options = question['options'];
  final correctIndex = question['correctIndex'];
  final explanation = question['explanationFr'];

  if (prompt is! String || prompt.trim().isEmpty) return null;
  if (explanation is! String || explanation.trim().isEmpty) return null;
  if (options is! List || options.length != 4) return null;
  final optionStrings = <String>[];
  for (final option in options) {
    if (option is! String || option.trim().isEmpty) return null;
    optionStrings.add(option);
  }
  if (optionStrings.toSet().length != 4) return null;
  if (correctIndex is! int || correctIndex < 0 || correctIndex > 3) return null;

  return {
    'prompt': prompt,
    'options': optionStrings,
    'correctIndex': correctIndex,
    'explanationFr': explanation,
  };
}

String _extractJson(String raw) {
  final start = raw.indexOf('{');
  final end = raw.lastIndexOf('}');
  if (start == -1 || end <= start) return raw;
  return raw.substring(start, end + 1);
}

/// Generates one passage on the week's theme, stores it with source
/// 'generated', and returns its title. Retries once on an unusable reply.
Future<String> generateReadingSet({
  required AppDatabase db,
  required LlmClient client,
  required String themeFr,
  String kind = 'note_service',
}) async {
  GeneratedReadingSet? set;
  for (var attempt = 0; attempt < 2; attempt++) {
    final reply = await client.complete(
      system: buildReadingSystemPrompt(),
      user: buildReadingUserPrompt(themeFr: themeFr, kind: kind),
      temperature: 0.8,
      maxTokens: 4000,
    );
    try {
      set = parseGeneratedReadingSet(reply);
      break;
    } on LlmException {
      if (attempt == 1) rethrow;
    }
  }

  final result = set!;
  await db.insertReadingSet(
    title: result.title,
    kind: result.kind,
    bodyFr: result.bodyFr,
    questions: result.questions,
    source: 'generated',
  );
  return result.title;
}
