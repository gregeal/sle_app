import 'dart:convert';

import '../../data/db/daos.dart';
import '../../data/db/database.dart';
import 'llm_client.dart';

const writingPromptVersion = 1;

class WritingError {
  const WritingError({
    required this.extrait,
    required this.correction,
    required this.explication,
  });

  final String extrait;
  final String correction;
  final String explication;
}

class WritingFeedback {
  const WritingFeedback({
    required this.levelEstimate,
    required this.correctedText,
    required this.errors,
    required this.tips,
  });

  final String levelEstimate;
  final String correctedText;
  final List<WritingError> errors;
  final List<String> tips;
}

/// Rotating composition prompts anchored to the week's theme. [variant] lets
/// the UI offer "another prompt" without an API call.
String compositionPromptFor(String themeFr, int variant) {
  final templates = [
    'Rédigez un courriel professionnel (120 à 180 mots) à votre gestionnaire '
        'au sujet de « $themeFr ». Exposez la situation, proposez une action '
        'et demandez une directive.',
    'Rédigez une courte note de service (120 à 180 mots) destinée à votre '
        'équipe sur le thème « $themeFr ». Annoncez un changement, expliquez '
        'la raison et précisez la marche à suivre.',
    'Un collègue vous demande votre avis sur une question liée à '
        '« $themeFr ». Répondez-lui par écrit (120 à 180 mots) : donnez votre '
        'position, deux arguments et une recommandation.',
  ];
  return templates[variant % templates.length];
}

String buildWritingSystemPrompt() =>
    'Tu es un évaluateur d\'expression écrite pour l\'Évaluation de langue '
    'seconde (ELS) de la Commission de la fonction publique du Canada. Tu '
    'corriges des textes de fonctionnaires en français canadien de registre '
    'professionnel. Repères des niveaux : B = textes courants, structures '
    'simples maîtrisées, erreurs qui ne nuisent pas au sens; C = structures '
    'complexes maîtrisées, vocabulaire précis, organisation soignée, seules '
    'des erreurs mineures subsistent. Ton estimation est NON OFFICIELLE. Tu '
    'réponds UNIQUEMENT avec du JSON valide, sans texte avant ni après.';

String buildWritingUserPrompt({
  required String promptFr,
  required String userText,
}) =>
    'Consigne donnée au candidat : $promptFr\n\n'
    'Texte du candidat :\n$userText\n\n'
    'Corrige ce texte et réponds avec ce JSON exactement : '
    '{"levelEstimate":"<A, A+, B, B+ ou C>",'
    '"correctedText":"<texte corrigé complet>",'
    '"errors":[{"extrait":"<passage fautif>","correction":"<forme correcte>",'
    '"explication":"<règle, en français>"}],'
    '"tips":["<conseil 1>","<conseil 2>","<conseil 3>"]}';

WritingFeedback parseWritingFeedback(String raw) {
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

  final level = decoded['levelEstimate'];
  final corrected = decoded['correctedText'];
  if (level is! String || level.trim().isEmpty) {
    throw const LlmException(
        'La rétroaction générée ne contient pas d\'estimation de niveau.');
  }
  if (corrected is! String || corrected.trim().isEmpty) {
    throw const LlmException(
        'La rétroaction générée ne contient pas de texte corrigé.');
  }

  final errors = <WritingError>[];
  final rawErrors = decoded['errors'];
  if (rawErrors is List) {
    for (final error in rawErrors) {
      if (error is! Map) continue;
      final extrait = error['extrait'];
      final correction = error['correction'];
      final explication = error['explication'];
      if (extrait is String &&
          correction is String &&
          explication is String &&
          extrait.trim().isNotEmpty) {
        errors.add(WritingError(
          extrait: extrait,
          correction: correction,
          explication: explication,
        ));
      }
    }
  }

  final tips = <String>[];
  final rawTips = decoded['tips'];
  if (rawTips is List) {
    for (final tip in rawTips) {
      if (tip is String && tip.trim().isNotEmpty) tips.add(tip);
    }
  }

  return WritingFeedback(
    levelEstimate: level.trim(),
    correctedText: corrected,
    errors: errors,
    tips: tips,
  );
}

String _extractJson(String raw) {
  final start = raw.indexOf('{');
  final end = raw.lastIndexOf('}');
  if (start == -1 || end <= start) return raw;
  return raw.substring(start, end + 1);
}

/// Requests feedback, persists the attempt, and returns the parsed result.
/// Retries once on an unusable reply; nothing is persisted on failure.
Future<WritingFeedback> requestWritingFeedback({
  required AppDatabase db,
  required LlmClient client,
  required String promptFr,
  required String userText,
}) async {
  WritingFeedback? feedback;
  String reply = '';
  for (var attempt = 0; attempt < 2; attempt++) {
    reply = await client.complete(
      system: buildWritingSystemPrompt(),
      user: buildWritingUserPrompt(promptFr: promptFr, userText: userText),
      temperature: 0.3,
      maxTokens: 3000,
    );
    try {
      feedback = parseWritingFeedback(reply);
      break;
    } on LlmException {
      if (attempt == 1) rethrow;
    }
  }

  await db.insertWritingAttempt(
    promptFr: promptFr,
    userText: userText,
    feedback: _extractJson(reply),
    at: DateTime.now(),
  );
  return feedback!;
}
