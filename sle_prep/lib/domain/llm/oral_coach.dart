import 'dart:convert';

import '../../data/db/daos.dart';
import '../../data/db/database.dart';
import 'llm_client.dart';

const oralPromptVersion = 1;

/// The five official OLA criteria, in display order.
const olaCriteria = [
  'aisance',
  'comprehension',
  'vocabulaire',
  'grammaire',
  'prononciation',
];

String criterionLabel(String name) => switch (name) {
      'aisance' => 'Aisance',
      'comprehension' => 'Compréhension',
      'vocabulaire' => 'Vocabulaire',
      'grammaire' => 'Grammaire',
      'prononciation' => 'Prononciation',
      _ => name,
    };

/// Approximate bar fill for a level letter in the report UI.
double levelProgress(String level) => switch (level.trim().toUpperCase()) {
      'A-' => 0.28,
      'A' => 0.35,
      'A+' => 0.45,
      'B-' => 0.55,
      'B' => 0.62,
      'B+' => 0.75,
      'C-' => 0.85,
      'C' => 0.9,
      'C+' => 0.97,
      _ => 0.5,
    };

class OralCriterion {
  const OralCriterion({
    required this.name,
    required this.level,
    required this.comment,
  });

  final String name;
  final String level;
  final String comment;
}

class OralFeedback {
  const OralFeedback({
    required this.levelEstimate,
    required this.summary,
    required this.criteria,
    required this.tips,
  });

  final String levelEstimate;
  final String summary;
  final List<OralCriterion> criteria;
  final List<String> tips;

  OralCriterion? criterion(String name) {
    for (final criterion in criteria) {
      if (criterion.name == name) return criterion;
    }
    return null;
  }
}

String buildOralSystemPrompt() =>
    'Tu es un évaluateur de l\'Évaluation de langue orale (ELO) de la '
    'Commission de la fonction publique du Canada. Tu évalues des réponses '
    'orales transcrites (français, langue seconde, contexte de la fonction '
    'publique fédérale) selon les cinq critères officiels : aisance, '
    'compréhension, vocabulaire, grammaire et prononciation. Repères : B = '
    'peut raconter et expliquer des faits, structures simples maîtrisées; '
    'C = peut défendre une opinion, traiter l\'hypothétique et l\'abstrait '
    'avec une aisance constante et seulement des erreurs mineures. La '
    'prononciation ne peut être qu\'approximée à partir de la transcription '
    '— dis-le dans ton commentaire. Ton estimation est NON OFFICIELLE. Tu '
    'réponds UNIQUEMENT avec du JSON valide, sans texte avant ni après.';

String buildOralUserPrompt(List<Map<String, dynamic>> exchanges) {
  final transcript = StringBuffer();
  for (var i = 0; i < exchanges.length; i++) {
    transcript
      ..writeln('Question ${i + 1} : ${exchanges[i]['question']}')
      ..writeln('Réponse du candidat : ${exchanges[i]['answer']}')
      ..writeln();
  }
  return 'Voici la transcription d\'une simulation d\'entrevue ELO.\n\n'
      '$transcript'
      'Évalue le candidat et réponds avec ce JSON exactement : '
      '{"levelEstimate":"<A, B, B+ ou C>",'
      '"summary":"<bilan en une ou deux phrases>",'
      '"criteria":[{"name":"aisance","level":"<niveau>","comment":"<…>"},'
      '{"name":"comprehension","level":"<niveau>","comment":"<…>"},'
      '{"name":"vocabulaire","level":"<niveau>","comment":"<…>"},'
      '{"name":"grammaire","level":"<niveau>","comment":"<…>"},'
      '{"name":"prononciation","level":"<niveau>","comment":"<…>"}],'
      '"tips":["<piste 1>","<piste 2>","<piste 3>"]}';
}

OralFeedback parseOralFeedback(String raw) {
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
  if (level is! String || level.trim().isEmpty) {
    throw const LlmException(
        'La rétroaction générée ne contient pas d\'estimation de niveau.');
  }
  final summary = decoded['summary'];

  final criteria = <OralCriterion>[];
  final rawCriteria = decoded['criteria'];
  if (rawCriteria is List) {
    for (final criterion in rawCriteria) {
      if (criterion is! Map) continue;
      final name = criterion['name'];
      final criterionLevel = criterion['level'];
      final comment = criterion['comment'];
      if (name is String &&
          olaCriteria.contains(name) &&
          criterionLevel is String &&
          criterionLevel.trim().isNotEmpty) {
        criteria.add(OralCriterion(
          name: name,
          level: criterionLevel.trim(),
          comment: comment is String ? comment : '',
        ));
      }
    }
  }
  final names = criteria.map((c) => c.name).toSet();
  if (!names.containsAll(olaCriteria)) {
    throw const LlmException(
        'La rétroaction générée ne couvre pas les cinq critères de l\'ELO.');
  }

  final tips = <String>[];
  final rawTips = decoded['tips'];
  if (rawTips is List) {
    for (final tip in rawTips) {
      if (tip is String && tip.trim().isNotEmpty) tips.add(tip);
    }
  }

  return OralFeedback(
    levelEstimate: level.trim(),
    summary: summary is String ? summary : '',
    criteria: criteria,
    tips: tips,
  );
}

String _extractJson(String raw) {
  final start = raw.indexOf('{');
  final end = raw.lastIndexOf('}');
  if (start == -1 || end <= start) return raw;
  return raw.substring(start, end + 1);
}

/// Assesses one or more question/answer exchanges, persists the attempt,
/// and returns the parsed report. Retries once; persists nothing on failure.
Future<OralFeedback> requestOralFeedback({
  required AppDatabase db,
  required LlmClient client,
  required String mode,
  required List<Map<String, dynamic>> exchanges,
}) async {
  OralFeedback? feedback;
  String reply = '';
  for (var attempt = 0; attempt < 2; attempt++) {
    reply = await client.complete(
      system: buildOralSystemPrompt(),
      user: buildOralUserPrompt(exchanges),
      temperature: 0.3,
      maxTokens: 2500,
    );
    try {
      feedback = parseOralFeedback(reply);
      break;
    } on LlmException {
      if (attempt == 1) rethrow;
    }
  }

  await db.recordOralAttempt(
    mode: mode,
    exchanges: exchanges,
    feedback: _extractJson(reply),
    at: DateTime.now(),
  );
  return feedback!;
}
