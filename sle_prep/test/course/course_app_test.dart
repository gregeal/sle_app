import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sle_prep/app.dart';
import 'package:sle_prep/data/seed/seed_loader.dart';
import 'package:sle_prep/domain/course/course_catalog.dart';
import 'package:sle_prep/domain/llm/llm_config.dart';
import 'package:sle_prep/features/course/course_library_screen.dart';
import 'package:sle_prep/features/course/course_screen.dart';
import 'package:sle_prep/providers.dart';
import '../support/test_db.dart';
import '../features/learning_hub_test.dart' show FakeTts;

void main() {
  testWidgets(
    'real app opens the course library and A to B class with global selection enabled',
    (tester) async {
      final db = inMemoryDatabase();
      addTearDown(db.close);
      // Asset decoding can use an isolate, outside the widget fake-async clock.
      await tester.runAsync(() => importSeedFromAssets(db));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            llmConfigProvider.overrideWith((ref) async => LlmConfig.defaults()),
            ttsServiceProvider.overrideWithValue(FakeTts()),
          ],
          child: const SlePrepApp(),
        ),
      );
      await tester.pumpAndSettle();
      final entry = find.text('Mes parcours · A → B et B → C');
      await tester.ensureVisible(entry);
      await tester.pumpAndSettle();
      await tester.tap(entry);
      await tester.pumpAndSettle();
      expect(find.byType(CourseLibraryScreen), findsOneWidget);
      await tester.tap(find.byKey(const Key('track-a-to-b-v1')));
      await tester.pumpAndSettle();
      expect(find.text('Parcours A → B'), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('course-continue')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('course-continue')));
      await tester.pumpAndSettle();
      expect(find.text(aToBCourse.lessons.first.objective), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(CourseLessonScreen), findsNothing);
      expect(find.byType(CourseScreen), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );
}
