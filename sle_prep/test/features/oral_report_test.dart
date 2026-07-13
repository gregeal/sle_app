import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sle_prep/domain/llm/oral_coach.dart';
import 'package:sle_prep/features/coach/oral_session_screen.dart';

void main() {
  testWidgets('oral report renders level, five criteria, tips and transcript',
      (tester) async {
    const feedback = OralFeedback(
      levelEstimate: 'B',
      summary: 'La compréhension atteint déjà le niveau C.',
      criteria: [
        OralCriterion(name: 'aisance', level: 'B', comment: 'Débit régulier.'),
        OralCriterion(name: 'comprehension', level: 'C', comment: ''),
        OralCriterion(name: 'vocabulaire', level: 'B+', comment: ''),
        OralCriterion(name: 'grammaire', level: 'B', comment: ''),
        OralCriterion(name: 'prononciation', level: 'B', comment: ''),
      ],
      tips: ['Accordez les participes.', 'Structurez vos réponses.'],
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: OralReportView(
            feedback: feedback,
            exchanges: [
              {'question': 'Décrivez votre poste.', 'answer': 'Je suis analyste.'},
            ],
          ),
        ),
      ),
    );

    expect(find.text('Niveau estimé : B'), findsOneWidget);
    expect(find.text('Aisance'), findsOneWidget);
    expect(find.text('Prononciation'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNWidgets(5));
    expect(find.text('Accordez les participes.'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Revoir la transcription'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Revoir la transcription'));
    await tester.pumpAndSettle();
    expect(find.text('Je suis analyste.'), findsOneWidget);
  });
}
