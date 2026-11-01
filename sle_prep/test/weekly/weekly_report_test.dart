import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sle_prep/domain/weekly/weekly_report.dart';
import 'package:sle_prep/domain/weekly/weekly_service.dart';
import 'package:sle_prep/domain/weekly/weekly_plan.dart';
import 'package:sle_prep/domain/llm/llm_client.dart';
import 'package:sle_prep/data/db/weekly_daos.dart';
import '../support/test_db.dart';
import 'package:sle_prep/features/weekly/weekly_practice_screen.dart';
import 'package:sle_prep/providers.dart';

String report({int? evidence}) => jsonEncode({
  'version': 1,
  'skills': {
    for (final s in ['speaking', 'listening', 'reading', 'writing'])
      s: {
        'level': null,
        'confidence': 'unknown',
        'observation': 'Preuves limitées.',
        'evidenceIds': evidence == null ? [] : [evidence],
      },
  },
  'strengths': ['Votre pratique est suivie.', 'Les activités sont variées.'],
  'priorities': [
    'Recueillir une preuve orale.',
    'Revoir la lecture.',
    'Réviser la rédaction.',
  ],
  'reinforce': ['writing'],
});

class Client implements LlmClient {
  Client(this.responses);
  final List<String> responses;
  int calls = 0;
  @override
  Future<String> complete({
    required String system,
    required String user,
    double temperature = .7,
    int? maxTokens,
  }) async {
    calls++;
    return responses.removeAt(0);
  }
}

void main() {
  testWidgets(
    'long practice feedback is chunked and successful chunks are reused',
    (tester) async {
      final db = inMemoryDatabase();
      addTearDown(db.close);
      final id = await db.createStudyWeek(
        plan: composeWeeklyPlan(
          weekNumber: 1,
          trackId: 'b-to-c-v1',
          lessonId: '01-detail',
          lessonTitleFr: 'Décrire',
        ),
        startDate: DateTime(2026, 11, 2),
      );
      final a = (await db.assignmentsForWeek(
        id,
      )).firstWhere((a) => a.skill == 'speaking');
      await db.saveAssignmentEvidence(
        a.id,
        AssignmentEvidence(
          kind: EvidenceKind.spokenPractice,
          data: {
            'exchanges': List.generate(
              41,
              (i) => {
                'question': 'Décrivez votre travail.',
                'answer': 'Je prépare des rapports pour mon équipe.',
              },
            ),
          },
        ),
        at: DateTime.now(),
      );
      final response = jsonEncode({
        'summary': 'La réponse est claire.',
        'corrections': [],
        'nextTask': 'Présentez un autre exemple.',
      });
      final client = Client([response, response, response]);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            llmClientProvider.overrideWith((ref) async => client),
          ],
          child: MaterialApp(home: WeeklyPracticeScreen(assignment: a)),
        ),
      );
      await tester.pumpAndSettle();
      final button = find.text(
        'Demander une rétroaction sur la pratique enregistrée · IA',
      );
      await tester.ensureVisible(button);
      await tester.pumpAndSettle();
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(client.calls, 3);
      await tester.ensureVisible(button);
      await tester.pumpAndSettle();
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(
        client.calls,
        3,
        reason: 'No additional paid requests for stored chunks',
      );
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );
  test(
    'strict report parser rejects absent skills, invalid levels and emphasis',
    () {
      expect(WeeklyReport.parse(report()).skills, hasLength(4));
      for (final change in [
        {'skills': {}},
        {
          'reinforce': ['speaking'],
        },
        {
          'priorities': ['one'],
        },
      ]) {
        expect(
          () => WeeklyReport.parse(
            jsonEncode({
              ...jsonDecode(report()) as Map<String, dynamic>,
              ...change,
            }),
          ),
          throwsFormatException,
        );
      }
    },
  );
  test(
    'weekly feedback retries malformed output and stores only canonical result',
    () async {
      final db = inMemoryDatabase();
      addTearDown(db.close);
      final id = await db.createStudyWeek(
        plan: composeWeeklyPlan(
          weekNumber: 1,
          trackId: 'b-to-c-v1',
          lessonId: '01-detail',
          lessonTitleFr: 'Décrire',
        ),
        startDate: DateTime(2026, 11, 2),
      );
      await db.closeStudyWeek(id, at: DateTime(2026, 11, 7));
      final client = Client(['{}', report()]);
      await db.generateWeeklyFeedback(id, client);
      expect(client.calls, 2);
      expect((await db.weeklyFeedback(id))!.status, 'ready');
      await db.generateWeeklyFeedback(id, client);
      expect(client.calls, 2);
    },
  );
  test(
    'bad evidence references fail without overwriting the frozen snapshot',
    () async {
      final db = inMemoryDatabase();
      addTearDown(db.close);
      final id = await db.createStudyWeek(
        plan: composeWeeklyPlan(
          weekNumber: 1,
          trackId: 'b-to-c-v1',
          lessonId: '01-detail',
          lessonTitleFr: 'Décrire',
        ),
        startDate: DateTime(2026, 11, 2),
      );
      await db.closeStudyWeek(id, at: DateTime(2026, 11, 7));
      final before = (await db.weeklyFeedback(id))!.snapshotJson;
      await expectLater(
        db.generateWeeklyFeedback(id, Client([report(evidence: 999)])),
        throwsFormatException,
      );
      expect((await db.weeklyFeedback(id))!.status, 'failed');
      expect((await db.weeklyFeedback(id))!.snapshotJson, before);
    },
  );
  test('study dates are date-only across DST and midweek starts', () {
    expect(
      scheduledStudyDates(DateTime(2026, 10, 30), [
        1,
        2,
        3,
        4,
        5,
      ]).map(studyDateKey),
      ['2026-10-30', '2026-11-02', '2026-11-03', '2026-11-04', '2026-11-05'],
    );
    expect(
      () => scheduledStudyDates(DateTime(2026), [1, 2, 3]),
      throwsArgumentError,
    );
  });
}
