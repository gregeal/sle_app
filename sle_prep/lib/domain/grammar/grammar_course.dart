/// "Grammaire pas à pas": the grammar a classroom teacher would cover, in the
/// order a classroom teacher would cover it.
///
/// Original teaching material, not official or recalled SLE test questions.
/// Each lesson is self-contained and works offline; the external links are
/// extra practice, never a requirement.
library;

import '../course/course_catalog.dart' show CourseQuestion;
import 'grammar_content_a.dart';
import 'grammar_content_b.dart';

/// Share of the quiz that marks a lesson as acquired.
const kGrammarPassShare = 0.75;

class GrammarUnit {
  const GrammarUnit(this.number, this.title, this.goal);
  final int number;
  final String title;
  final String goal;
}

const grammarUnits = [
  GrammarUnit(
    1,
    'Les bases de la phrase',
    'Construire une phrase correcte au présent : sujet, verbe, article, '
        'adjectif, négation, question.',
  ),
  GrammarUnit(
    2,
    'Parler de l’avenir',
    'Dire ce que vous allez faire et ce qui arrivera.',
  ),
  GrammarUnit(
    3,
    'Raconter le passé',
    'Raconter ce qui s’est passé et décrire comment c’était.',
  ),
  GrammarUnit(
    4,
    'Éviter de répéter : les pronoms',
    'Remplacer un nom et relier deux phrases pour parler plus naturellement.',
  ),
  GrammarUnit(
    5,
    'Demander, conseiller, nuancer',
    'Donner une consigne, demander poliment, faire une hypothèse, exprimer '
        'une nécessité.',
  ),
];

class GrammarTable {
  const GrammarTable(this.title, this.rows);
  final String title;

  /// Each row is `left|right`.
  final List<String> rows;

  List<(String, String)> get cells => [for (final row in rows) _pair(row)];
}

class GrammarLesson {
  const GrammarLesson({
    required this.id,
    required this.unit,
    required this.title,
    required this.summary,
    required this.englishKey,
    required this.whenToUse,
    required this.howToForm,
    required this.tables,
    required this.examples,
    required this.pitfalls,
    required this.questions,
    required this.sayAloud,
    required this.videoQuery,
    this.drillTopics = const [],
    this.referencePages = const [],
    this.conjugationVerb,
  });

  final String id;
  final int unit;
  final String title;

  /// What the learner will be able to do after the lesson.
  final String summary;

  /// The one idea to keep, in English, for a learner who is not yet
  /// comfortable reading explanations in French.
  final String englishKey;
  final List<String> whenToUse;
  final List<String> howToForm;
  final List<GrammarTable> tables;

  /// `français|English`.
  final List<String> examples;

  /// `incorrect|correct|pourquoi`.
  final List<String> pitfalls;
  final List<CourseQuestion> questions;

  /// `consigne|réponse modèle`.
  final List<String> sayAloud;

  /// Topics of the offline drill bank that train this point, if any.
  final List<String> drillTopics;

  /// `page|libellé` on Tex's French Grammar (University of Texas at Austin),
  /// an open resource with audio and self-correcting exercises.
  final List<String> referencePages;

  /// A model verb whose full conjugation is worth seeing.
  final String? conjugationVerb;
  final String videoQuery;

  List<(String, String)> get examplePairs => [
    for (final example in examples) _pair(example),
  ];

  List<(String, String, String)> get pitfallTriples => [
    for (final pitfall in pitfalls) _triple(pitfall),
  ];

  List<(String, String)> get speakingTasks => [
    for (final task in sayAloud) _pair(task),
  ];

  List<GrammarLink> get links => [
    for (final page in referencePages)
      GrammarLink(
        '${_pair(page).$2} · leçon avec audio et exercices (en anglais)',
        'https://www.laits.utexas.edu/tex/gr/${_pair(page).$1}.html',
      ),
    if (conjugationVerb case final verb?)
      GrammarLink(
        'Conjugaison complète de « ${verb.replaceAll('-', ' ')} »',
        'https://leconjugueur.lefigaro.fr/conjugaison/verbe/$verb.html',
      ),
    GrammarLink(
      'Vidéos sur ce point',
      'https://www.youtube.com/results?search_query='
          '${Uri.encodeQueryComponent('français $videoQuery')}',
    ),
  ];

  /// Correct answers needed for the lesson to count as acquired.
  int get passMark => (questions.length * kGrammarPassShare).ceil();
}

class GrammarLink {
  const GrammarLink(this.label, this.url);
  final String label;
  final String url;
}

const grammarLessons = <GrammarLesson>[...grammarLessonsA, ...grammarLessonsB];

GrammarUnit unitOf(GrammarLesson lesson) =>
    grammarUnits.firstWhere((unit) => unit.number == lesson.unit);

GrammarLesson? findGrammarLesson(String id) {
  for (final lesson in grammarLessons) {
    if (lesson.id == id) return lesson;
  }
  return null;
}

(String, String) _pair(String raw) {
  final parts = raw.split('|');
  if (parts.length != 2) throw FormatException('Expected two parts: $raw');
  return (parts[0], parts[1]);
}

(String, String, String) _triple(String raw) {
  final parts = raw.split('|');
  if (parts.length != 3) throw FormatException('Expected three parts: $raw');
  return (parts[0], parts[1], parts[2]);
}
