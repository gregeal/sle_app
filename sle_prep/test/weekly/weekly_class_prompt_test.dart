import 'package:flutter_test/flutter_test.dart';
import 'package:sle_prep/domain/realtime/realtime_interview_prompt.dart';
import 'package:sle_prep/domain/weekly/weekly_class_prompt.dart';

String teacher({
  String title = 'Défendre une recommandation',
  String objective = 'Soutenir une proposition avec deux arguments.',
  List<String> phrases = const ['à mon avis', 'en revanche'],
  String task = 'Recommandez un horaire à votre gestionnaire.',
}) => buildClassTeacherInstructions(
  lessonTitle: title,
  objective: objective,
  targetPhrases: phrases,
  speakingTask: task,
);

void main() {
  test('the class is bound to this week s lesson', () {
    final prompt = teacher();
    expect(prompt, contains('Défendre une recommandation'));
    expect(prompt, contains('deux arguments'));
    expect(prompt, contains('à mon avis'));
    expect(prompt, contains('en revanche'));
    expect(prompt, contains('Recommandez un horaire'));
  });

  test('the teacher teaches and corrects, unlike the examiner', () {
    final prompt = teacher();
    expect(prompt.toLowerCase(), contains('corrige avec douceur'));
    expect(prompt, contains('aucune note'));
    expect(
      prompt,
      contains('beaucoup plus que toi'),
      reason: 'the learner must dominate the airtime',
    );

    // The examiner deliberately does the opposite; the two must not drift
    // into each other.
    final examiner = buildRealtimeInterviewInstructions();
    expect(examiner, contains('ne corrige pas'));
    expect(prompt, isNot(equals(examiner)));
  });

  test('never recites itself and keeps the grading out of the room', () {
    final prompt = teacher();
    expect(prompt, contains('ne récite jamais'));
    expect(prompt, contains('bilan'));
  });

  test('survives missing or oversized lesson material', () {
    final empty = buildClassTeacherInstructions(
      lessonTitle: 'Titre',
      objective: 'Objectif',
      targetPhrases: const [],
      speakingTask: 'Tâche',
    );
    expect(empty, contains('celles de la classe'));

    final long = teacher(objective: List.filled(4000, 'très long').join(' '));
    expect(long.length, lessThan(6000), reason: 'one lesson cannot crowd out the rules');
    expect(long, contains('aucune note'));
  });

  test('the opening makes the learner speak first', () {
    final opening = buildClassOpeningInstruction(lessonTitle: 'Les réunions');
    expect(opening, contains('Les réunions'));
    expect(opening, contains('première question'));
    expect(opening, contains('avant qu\'elle ait parlé'));
  });

  test('is versioned so a prompt change is traceable', () {
    expect(weeklyClassPromptVersion, isPositive);
  });
}
