import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sle_prep/data/db/daos.dart';
import 'package:sle_prep/data/db/database.dart';
import 'package:sle_prep/data/db/habit_daos.dart';
import 'package:sle_prep/data/db/weekly_daos.dart';
import 'package:sle_prep/domain/habit/habit_settings.dart';
import 'package:sle_prep/domain/habit/reminder_plan.dart';
import 'package:sle_prep/domain/weekly/weekly_plan.dart';
import 'package:sle_prep/features/habit/habit_providers.dart';
import 'package:sle_prep/features/habit/reminder_service.dart';
import 'package:sle_prep/features/habit/rhythm_screen.dart';
import 'package:sle_prep/features/today/today_screen.dart';
import 'package:sle_prep/features/weekly/weekly_home_screen.dart';
import 'package:sle_prep/providers.dart';

import '../support/test_db.dart';

class FakeReminders implements ReminderService {
  FakeReminders({this.granted = true});

  final bool granted;
  var permissionRequests = 0;
  final applied = <List<ReminderSpec>>[];

  @override
  bool get supported => true;

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    return granted;
  }

  @override
  Future<void> apply(
    List<ReminderSpec> specs, {
    required int dailyMinutes,
  }) async => applied.add(specs);
}

// November 2026: the 2nd is a Monday.
DateTime nov(int day, [int hour = 12]) => DateTime(2026, 11, day, hour);

const ownerRhythm = HabitSettings(studyDays: [1, 3, 5, 6], classDays: [2, 4]);

void tallScreen(WidgetTester tester) {
  // Tall enough that every card of a lazily built list exists and is
  // tappable without scrolling.
  tester.view.physicalSize = const Size(800, 2800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<void> pumpHome(
  WidgetTester tester,
  AppDatabase db,
  DateTime day, {
  ReminderService? reminders,
}) async {
  tallScreen(tester);
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        studyDayProvider.overrideWithValue(day),
        reminderServiceProvider.overrideWithValue(reminders ?? FakeReminders()),
      ],
      child: const MaterialApp(home: Scaffold(body: TodayScreen())),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> unmount(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a new learner gets one setup card and the five-minute door', (
    tester,
  ) async {
    final db = inMemoryDatabase();
    addTearDown(db.close);
    await pumpHome(tester, db, nov(2));

    expect(find.text('Étape 1 · Installer l’habitude'), findsOneWidget);
    expect(find.textContaining('Aucun objectif de niveau'), findsOneWidget);
    expect(find.byKey(const Key('habit-setup')), findsOneWidget);
    expect(find.byKey(const Key('habit-open-week')), findsOneWidget);
    expect(find.byKey(const Key('habit-quick')), findsOneWidget);
    expect(find.text('Jour de cours'), findsNothing);
    expect(find.byKey(const Key('habit-checkin')), findsNothing);
    await unmount(tester);
  });

  testWidgets('a study day offers exactly one thing to start', (tester) async {
    final db = inMemoryDatabase();
    addTearDown(db.close);
    await db.createStudyWeek(
      plan: composeWeeklyPlan(
        weekNumber: 1,
        trackId: 'b-to-c-v1',
        lessonId: '01-detail',
        lessonTitleFr: 'Décrire',
        studyDays: 4,
        minutesPerDay: 20,
      ),
      startDate: nov(2),
      weekdays: const [1, 3, 5, 6],
    );
    await db.saveHabitSettings(ownerRhythm);
    await pumpHome(tester, db, nov(2));

    expect(find.text('Séance d’aujourd’hui'), findsOneWidget);
    expect(find.text('Commencer · 20 min'), findsOneWidget);
    expect(find.byKey(const Key('habit-start')), findsOneWidget);
    expect(find.text('Classe de la semaine'), findsOneWidget);
    expect(find.text('Cette semaine : 0 jour sur 6'), findsOneWidget);
    expect(find.byKey(const Key('habit-setup')), findsNothing);
    expect(find.text('Aucun rappel actif'), findsOneWidget);
    await unmount(tester);

    // Real time, once logged, is what moves the streak and the week.
    await db.logActivity(startedAt: nov(2, 7), seconds: 420, kind: 'vocab');
    await pumpHome(tester, db, nov(2));
    expect(find.text('1 j'), findsOneWidget);
    expect(find.text('Cette semaine : 1 jour sur 6'), findsOneWidget);
    expect(
      find.text('Aujourd’hui : 7 min · la journée compte.'),
      findsOneWidget,
    );
    await unmount(tester);
  });

  testWidgets('a group-class day asks only for a warm-up and a note', (
    tester,
  ) async {
    final db = inMemoryDatabase();
    addTearDown(db.close);
    await db.saveHabitSettings(ownerRhythm);
    await pumpHome(tester, db, nov(3));

    expect(find.text('Jour de cours'), findsOneWidget);
    expect(find.byKey(const Key('habit-class-warmup')), findsOneWidget);
    expect(find.byKey(const Key('habit-start')), findsNothing);

    await tester.tap(find.byKey(const Key('habit-class-capture')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('class-note-covered')),
      'Le subjonctif après il faut que',
    );
    await tester.enterText(
      find.byKey(const Key('class-note-corrections')),
      'il faut que je fasse, pas que je fais',
    );
    await tester.tap(find.byKey(const Key('class-note-save')));
    await tester.pumpAndSettle();

    expect(find.text('Jour de cours'), findsOneWidget, reason: 'back home');
    final note = (await db.groupClassNoteFor(nov(3)))!;
    expect(note.covered, 'Le subjonctif après il faut que');
    expect(note.corrections, contains('je fasse'));
    await unmount(tester);
  });

  testWidgets('a rest day asks for nothing', (tester) async {
    final db = inMemoryDatabase();
    addTearDown(db.close);
    await db.createStudyWeek(
      plan: composeWeeklyPlan(
        weekNumber: 1,
        trackId: 'b-to-c-v1',
        lessonId: '01-detail',
        lessonTitleFr: 'Décrire',
        studyDays: 4,
        minutesPerDay: 20,
      ),
      startDate: nov(2),
      weekdays: const [1, 3, 5, 6],
    );
    await db.saveHabitSettings(ownerRhythm);
    await pumpHome(tester, db, nov(8));

    expect(find.textContaining('le repos fait partie du plan'), findsOneWidget);
    expect(find.byKey(const Key('habit-start')), findsNothing);
    expect(find.text('Jour de cours'), findsNothing);
    expect(
      find.byKey(const Key('habit-quick')),
      findsOneWidget,
      reason: 'optional, never required',
    );
    await unmount(tester);
  });

  testWidgets('last week is offered for review once, the week after', (
    tester,
  ) async {
    final db = inMemoryDatabase();
    addTearDown(db.close);
    await db.saveHabitSettings(ownerRhythm);
    for (final day in [2, 4, 6, 7]) {
      await db.logActivity(startedAt: nov(day), seconds: 600, kind: 'vocab');
    }
    await pumpHome(tester, db, nov(9));
    expect(find.byKey(const Key('habit-checkin')), findsOneWidget);

    await tester.tap(find.byKey(const Key('habit-checkin')));
    await tester.pumpAndSettle();
    expect(find.text('Semaine tenue.'), findsOneWidget);
    expect(find.textContaining('4 jours sur 6'), findsOneWidget);
    await tester.tap(find.byKey(const Key('checkin-done')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('habit-checkin')), findsNothing);
    expect(await db.getSetting('habit:lastCheckin'), '2026-11-09');
    expect(
      find.textContaining('1 semaine tenue sur 4'),
      findsOneWidget,
      reason: 'the kept week counts toward the habit stage',
    );
    await unmount(tester);
  });

  group('rhythm screen', () {
    Future<FakeReminders> open(
      WidgetTester tester,
      AppDatabase db, {
      bool granted = true,
    }) async {
      tallScreen(tester);
      final reminders = FakeReminders(granted: granted);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            studyDayProvider.overrideWithValue(nov(2)),
            reminderServiceProvider.overrideWithValue(reminders),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const RhythmScreen(),
                      ),
                    ),
                    child: const Text('ouvrir'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('ouvrir'));
      await tester.pumpAndSettle();
      return reminders;
    }

    Future<void> setRole(WidgetTester tester, int day, String label) async {
      await tester.tap(
        find.descendant(
          of: find.byKey(Key('rhythm-day-$day')),
          matching: find.text(label),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('saving asks permission and schedules the reminders', (
      tester,
    ) async {
      final db = inMemoryDatabase();
      addTearDown(db.close);
      final reminders = await open(tester, db);

      // The owner's week: class on Tuesday and Thursday, Saturday instead.
      await setRole(tester, 2, 'Cours');
      await setRole(tester, 4, 'Cours');
      await setRole(tester, 6, 'Étude');
      await tester.tap(find.byKey(const Key('rhythm-save')));
      await tester.pumpAndSettle();

      expect(find.byType(RhythmScreen), findsNothing, reason: 'saved, closed');
      expect(reminders.permissionRequests, 1);
      final saved = await db.habitSettings();
      expect(saved.configured, isTrue);
      expect(saved.remindersEnabled, isTrue);
      expect(saved.studyDays, [1, 3, 5, 6]);
      expect(saved.classDays, [2, 4]);
      expect(saved.dailyMinutes, 20);
      expect(
        reminders.applied.last,
        hasLength(12),
        reason: 'a reminder and a nudge for each of six active days',
      );
      expect(reminders.applied.last.where((s) => s.weekday == 7), isEmpty);
      await unmount(tester);
    });

    testWidgets('a refused permission is explained, not hidden', (
      tester,
    ) async {
      final db = inMemoryDatabase();
      addTearDown(db.close);
      final reminders = await open(tester, db, granted: false);

      await tester.tap(find.byKey(const Key('rhythm-save')));
      await tester.pumpAndSettle();

      expect(find.byType(RhythmScreen), findsOneWidget);
      expect(
        find.textContaining('notifications sont refusées'),
        findsOneWidget,
      );
      final saved = await db.habitSettings();
      expect(saved.configured, isTrue, reason: 'the rhythm itself is kept');
      expect(saved.remindersEnabled, isFalse);
      expect(reminders.applied.last, isEmpty);
      await unmount(tester);
    });

    testWidgets('a week with no rest day cannot be saved', (tester) async {
      final db = inMemoryDatabase();
      addTearDown(db.close);
      final reminders = await open(tester, db);

      await setRole(tester, 6, 'Étude');
      await setRole(tester, 7, 'Étude');
      await tester.tap(find.byKey(const Key('rhythm-save')));
      await tester.pumpAndSettle();

      expect(
        find.text('Gardez au moins un jour de repos complet.'),
        findsOneWidget,
      );
      expect((await db.habitSettings()).configured, isFalse);
      expect(reminders.permissionRequests, 0);
      expect(reminders.applied, isEmpty);
      await unmount(tester);
    });
  });

  testWidgets('closing a week asks first and can be cancelled', (tester) async {
    final db = inMemoryDatabase();
    addTearDown(db.close);
    tallScreen(tester);
    final week = await db.createStudyWeek(
      plan: composeWeeklyPlan(
        weekNumber: 1,
        trackId: 'b-to-c-v1',
        lessonId: '01-detail',
        lessonTitleFr: 'Décrire',
      ),
      startDate: nov(2),
    );
    await db.setSetting('weekly:autoReports', 'false');
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          studyDayProvider.overrideWithValue(nov(2)),
          reminderServiceProvider.overrideWithValue(FakeReminders()),
        ],
        child: const MaterialApp(home: Scaffold(body: WeeklyHomeScreen())),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Clore et préparer le bilan'));
    await tester.pumpAndSettle();
    expect(find.text('Clore cette semaine ?'), findsOneWidget);
    expect(find.textContaining('ne sont pas terminées'), findsOneWidget);
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
    expect((await db.activeStudyWeek())?.id, week, reason: 'nothing frozen');

    await tester.tap(find.text('Clore et préparer le bilan'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('weekly-close-confirm')));
    await tester.pumpAndSettle();
    expect(await db.activeStudyWeek(), isNull);
    expect((await db.studyWeek(week))!.status, 'closed');
    await unmount(tester);
  });
}
