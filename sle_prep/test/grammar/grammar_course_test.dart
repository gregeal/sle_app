import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sle_prep/data/db/daos.dart';
import 'package:sle_prep/data/db/grammar_daos.dart';
import 'package:sle_prep/domain/grammar/grammar_course.dart';
import 'package:sle_prep/features/grammar/grammar_screens.dart';
import 'package:sle_prep/providers.dart';

import '../speaking/speaking_screens_test.dart' show TestTts;
import '../support/test_db.dart';

void main() {
  group('content', () {
    test('twenty lessons in class order, each with a unique id', () {
      expect(grammarLessons, hasLength(20));
      expect(grammarLessons.map((l) => l.id).toSet(), hasLength(20));
      var unit = 1;
      for (final lesson in grammarLessons) {
        expect(lesson.unit, greaterThanOrEqualTo(unit), reason: lesson.id);
        unit = lesson.unit;
        expect(unitOf(lesson).number, lesson.unit);
      }
      expect(
        grammarLessons.map((l) => l.unit).toSet(),
        grammarUnits.map((u) => u.number).toSet(),
        reason: 'no empty unit',
      );
    });

    test('covers the tenses a beginner class is built on, in order', () {
      int position(String fragment) {
        final index = grammarLessons.indexWhere(
          (l) => l.title.toLowerCase().contains(fragment),
        );
        expect(index, isNonNegative, reason: fragment);
        return index;
      }

      final present = position('présent des verbes en -er');
      final nearFuture = position('futur proche');
      final simpleFuture = position('futur simple');
      final pastWithAvoir = position('passé composé avec avoir');
      final pastWithEtre = position('passé composé avec être');
      final imperfect = position('l’imparfait');
      final contrast = position('passé composé ou imparfait');
      expect(position('être et avoir'), lessThan(present));
      expect(present, lessThan(nearFuture));
      expect(nearFuture, lessThan(simpleFuture));
      expect(pastWithAvoir, lessThan(pastWithEtre));
      expect(pastWithEtre, lessThan(imperfect));
      expect(imperfect, lessThan(contrast));
      expect(position('subjonctif'), grammarLessons.length - 1);
    });

    test('every lesson is complete and internally consistent', () {
      for (final lesson in grammarLessons) {
        final id = lesson.id;
        expect(lesson.title, isNotEmpty, reason: id);
        expect(lesson.summary, isNotEmpty, reason: id);
        expect(lesson.englishKey.length, greaterThan(40), reason: id);
        expect(lesson.whenToUse.length, greaterThanOrEqualTo(2), reason: id);
        expect(lesson.howToForm.length, greaterThanOrEqualTo(3), reason: id);

        expect(lesson.tables, isNotEmpty, reason: id);
        for (final table in lesson.tables) {
          expect(table.cells.length, greaterThanOrEqualTo(2), reason: id);
          for (final (left, right) in table.cells) {
            expect(left.trim(), isNotEmpty, reason: '$id ${table.title}');
            expect(right.trim(), isNotEmpty, reason: '$id ${table.title}');
          }
        }

        expect(lesson.examplePairs, hasLength(5), reason: id);
        for (final (fr, en) in lesson.examplePairs) {
          expect(fr.trim(), isNotEmpty, reason: id);
          expect(en.trim(), isNotEmpty, reason: id);
          expect(fr, isNot(en), reason: id);
        }

        expect(lesson.pitfallTriples, hasLength(3), reason: id);
        for (final (wrong, right, why) in lesson.pitfallTriples) {
          expect(wrong, isNot(right), reason: '$id: $wrong');
          expect(why.trim(), isNotEmpty, reason: id);
        }

        expect(lesson.questions, hasLength(4), reason: id);
        for (final question in lesson.questions) {
          expect(question.options, hasLength(4), reason: question.prompt);
          expect(
            question.options.toSet(),
            hasLength(4),
            reason: 'distinct options: ${question.prompt}',
          );
          expect(
            question.correct,
            inInclusiveRange(0, 3),
            reason: question.prompt,
          );
          expect(question.explanation.trim(), isNotEmpty);
        }
        expect(lesson.passMark, 3, reason: 'three of four acquires a lesson');

        expect(lesson.speakingTasks, hasLength(3), reason: id);
        for (final (prompt, model) in lesson.speakingTasks) {
          expect(prompt.trim(), isNotEmpty, reason: id);
          expect(model.split(' ').length, greaterThan(3), reason: id);
        }
      }
    });

    test('links are https, and only to the pages that were verified', () {
      final verifiedPages = {
        'virr1', 'virr2', 'det2', 'det4', 'det5', 'tapr1', 'ver1', 'vir1',
        'vre1', 'vm1', 'neg2', 'int2', 'int7', 'adj2', 'vpr1', 'taf1',
        'taf2', 'taf3', 'tap2', 'tap3', 'tap4', 'tap5', 'tap6', 'tap8',
        'pro5', 'pro8', 'pro6', 'pro7', 'pror1', 'pror3', 'tai1', 'tac1',
        'tac3', 'tas1', 'tas2', 'tas3a', //
      };
      const verifiedVerbs = {
        'etre', 'avoir', 'parler', 'finir', 'vendre', 'aller', 'faire',
        'prendre', 'se-lever', 'pouvoir', 'venir', //
      };
      for (final lesson in grammarLessons) {
        expect(lesson.referencePages, isNotEmpty, reason: lesson.id);
        for (final page in lesson.referencePages) {
          expect(
            verifiedPages,
            contains(page.split('|').first),
            reason: '${lesson.id}: $page',
          );
        }
        if (lesson.conjugationVerb case final verb?) {
          expect(verifiedVerbs, contains(verb), reason: lesson.id);
        }
        expect(lesson.links.length, greaterThanOrEqualTo(2));
        for (final link in lesson.links) {
          final uri = Uri.parse(link.url);
          expect(uri.scheme, 'https', reason: link.url);
          expect(uri.host, isNotEmpty, reason: link.url);
          expect(link.label.trim(), isNotEmpty);
        }
        expect(
          lesson.links.last.url,
          startsWith('https://www.youtube.com/results?search_query=fran'),
        );
      }
    });

    test('drill topics exist in the offline drill bank', () {
      final bank = jsonDecode(
        File('assets/seed/drills_core.json').readAsStringSync(),
      );
      final topics = {
        for (final item in bank['items'] as List) item['topic'] as String,
      };
      var linked = 0;
      for (final lesson in grammarLessons) {
        for (final topic in lesson.drillTopics) {
          expect(topics, contains(topic), reason: lesson.id);
          linked++;
        }
      }
      expect(linked, greaterThan(12), reason: 'most lessons offer more drills');
    });

    test('lessons are found by id', () {
      expect(findGrammarLesson('g12-imparfait')!.title, 'L’imparfait');
      expect(findGrammarLesson('nope'), isNull);
    });
  });

  group('progress', () {
    test(
      'keeps the best result and decides when a lesson is acquired',
      () async {
        final db = inMemoryDatabase();
        addTearDown(db.close);
        const id = 'g01-etre-avoir';
        expect(await db.grammarProgress(), isEmpty);

        await db.markGrammarOpened(id);
        var progress = (await db.grammarProgress())[id]!;
        expect(
          (progress.opened, progress.attempted, progress.acquired),
          (true, false, false),
        );

        progress = await db.saveGrammarQuiz(id, score: 2);
        expect((progress.bestScore, progress.acquired), (2, false));
        progress = await db.saveGrammarQuiz(id, score: 3);
        expect((progress.bestScore, progress.acquired), (3, true));
        progress = await db.saveGrammarQuiz(id, score: 1);
        expect(
          (progress.bestScore, progress.acquired),
          (3, true),
          reason: 'a tired retry never takes a lesson away',
        );
        await db.markGrammarOpened(id);
        expect((await db.grammarProgress())[id]!.bestScore, 3);
      },
    );

    test('refuses unknown lessons and impossible scores', () async {
      final db = inMemoryDatabase();
      addTearDown(db.close);
      await expectLater(db.markGrammarOpened('nope'), throwsArgumentError);
      await expectLater(
        db.saveGrammarQuiz('nope', score: 1),
        throwsArgumentError,
      );
      await expectLater(
        db.saveGrammarQuiz('g01-etre-avoir', score: 5),
        throwsArgumentError,
      );
      await expectLater(
        db.saveGrammarQuiz('g01-etre-avoir', score: -1),
        throwsArgumentError,
      );
    });

    test('a damaged entry reads as not started', () async {
      final db = inMemoryDatabase();
      addTearDown(db.close);
      await db.setSetting('grammar:g01-etre-avoir', '{]');
      await db.setSetting('grammar:g02-articles', '{"best":9,"total":4}');
      final progress = await db.grammarProgress();
      expect(progress.containsKey('g01-etre-avoir'), isFalse);
      expect(progress['g02-articles']!.attempted, isFalse);
      expect(nextGrammarLesson(progress).id, 'g01-etre-avoir');
    });
  });

  group('screens', () {
    Future<void> pump(WidgetTester tester, db) async {
      // Tall enough for a whole lesson to be on screen and tappable.
      tester.view.physicalSize = const Size(800, 9000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            ttsServiceProvider.overrideWithValue(TestTts()),
          ],
          child: const MaterialApp(home: GrammarPathScreen()),
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> answer(WidgetTester tester, List<int> choices) async {
      for (var i = 0; i < choices.length; i++) {
        await tester.tap(find.byKey(Key('grammar-q$i-o${choices[i]}')));
        await tester.pump();
      }
    }

    testWidgets('a lesson is read, checked and acquired, then the path moves '
        'on', (tester) async {
      final db = inMemoryDatabase();
      addTearDown(db.close);
      await pump(tester, db);
      final first = grammarLessons.first;
      expect(find.text('0 leçon acquise sur 20'), findsOneWidget);
      expect(find.text('Commencer · ${first.title}'), findsOneWidget);

      await tester.tap(find.byKey(const Key('grammar-continue')));
      await tester.pumpAndSettle();
      expect(find.text(first.englishKey), findsOneWidget);
      expect(find.text('je'), findsOneWidget, reason: 'the être table');
      expect(find.text('suis'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('grammar-check')))
            .onPressed,
        isNull,
        reason: 'nothing to check until every question is answered',
      );

      await answer(tester, [for (final q in first.questions) q.correct]);
      await tester.tap(find.byKey(const Key('grammar-check')));
      await tester.pumpAndSettle();
      expect(find.text('4 / 4 · leçon acquise.'), findsOneWidget);
      expect(
        find.textContaining('✔ ${first.questions.first.explanation}'),
        findsOneWidget,
      );
      expect((await db.grammarProgress())[first.id]!.acquired, isTrue);

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('1 leçon acquise sur 20'), findsOneWidget);
      expect(
        find.text('Continuer · ${grammarLessons[1].title}'),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    });

    testWidgets('a weak first try explains, lets the learner retry, and '
        'pressures nobody', (tester) async {
      final db = inMemoryDatabase();
      addTearDown(db.close);
      await pump(tester, db);
      final lesson = grammarLessons[11];
      await tester.tap(find.byKey(Key('grammar-lesson-${lesson.id}')));
      await tester.pumpAndSettle();
      expect(find.text('Leçon 12 sur 20 · Raconter le passé'), findsOneWidget);

      final wrong = [
        for (final q in lesson.questions) (q.correct + 1) % q.options.length,
      ];
      await answer(tester, wrong);
      await tester.tap(find.byKey(const Key('grammar-check')));
      await tester.pumpAndSettle();
      expect(find.textContaining('0 / 4'), findsOneWidget);
      expect(find.textContaining('Rien ne presse'), findsOneWidget);
      expect((await db.grammarProgress())[lesson.id]!.acquired, isFalse);

      await tester.tap(find.byKey(const Key('grammar-retry')));
      await tester.pumpAndSettle();
      await answer(tester, [for (final q in lesson.questions) q.correct]);
      await tester.tap(find.byKey(const Key('grammar-check')));
      await tester.pumpAndSettle();
      expect(find.text('4 / 4 · leçon acquise.'), findsOneWidget);
      expect((await db.grammarProgress())[lesson.id]!.bestScore, 4);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    });

    testWidgets('examples and models can be heard', (tester) async {
      final db = inMemoryDatabase();
      addTearDown(db.close);
      tester.view.physicalSize = const Size(800, 9000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final tts = TestTts();
      final lesson = grammarLessons[7];
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            ttsServiceProvider.overrideWithValue(tts),
          ],
          child: MaterialApp(home: GrammarLessonScreen(lesson: lesson)),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Écouter').first);
      await tester.pump();
      expect(tts.spoken.single, lesson.examplePairs.first.$1);

      await tester.tap(find.text(lesson.speakingTasks.first.$1));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Écouter le modèle'));
      await tester.pump();
      expect(tts.spoken.last, lesson.speakingTasks.first.$2);
      expect(find.byKey(const Key('grammar-drills')), findsOneWidget);
      expect(
        find.textContaining('leçon avec audio et exercices'),
        findsWidgets,
      );
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    });
  });
}
