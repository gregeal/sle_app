import 'dart:convert';

import 'package:drift/drift.dart';

import '../../domain/grammar/grammar_course.dart';
import 'daos.dart';
import 'database.dart';

const _prefix = 'grammar:';

/// Where the learner stands on one grammar lesson.
class GrammarProgress {
  const GrammarProgress({this.opened = false, this.bestScore, this.total});

  final bool opened;

  /// Best quiz result so far; a later, weaker attempt never lowers it.
  final int? bestScore;
  final int? total;

  bool get attempted => bestScore != null && total != null;

  bool get acquired =>
      attempted && bestScore! >= (total! * kGrammarPassShare).ceil();

  Map<String, Object?> toJson() => {
    'opened': opened,
    'best': bestScore,
    'total': total,
  };

  static GrammarProgress fromJson(Object? json) {
    if (json is! Map) return const GrammarProgress();
    final best = json['best'];
    final total = json['total'];
    final valid =
        best is int && total is int && total > 0 && best >= 0 && best <= total;
    return GrammarProgress(
      opened: json['opened'] == true,
      bestScore: valid ? best : null,
      total: valid ? total : null,
    );
  }
}

extension GrammarDaos on AppDatabase {
  /// Progress for every lesson the learner has touched, keyed by lesson id.
  Future<Map<String, GrammarProgress>> grammarProgress() async {
    final rows = await (select(
      appSettings,
    )..where((s) => s.key.like('$_prefix%'))).get();
    final progress = <String, GrammarProgress>{};
    for (final row in rows) {
      try {
        progress[row.key.substring(_prefix.length)] = GrammarProgress.fromJson(
          jsonDecode(row.value),
        );
      } on FormatException {
        // An unreadable entry reads as "not started", never as a crash.
        continue;
      }
    }
    return progress;
  }

  Future<GrammarProgress> _grammarProgressFor(String lessonId) async {
    final raw = await getSetting('$_prefix$lessonId');
    if (raw == null) return const GrammarProgress();
    try {
      return GrammarProgress.fromJson(jsonDecode(raw));
    } on FormatException {
      return const GrammarProgress();
    }
  }

  Future<void> markGrammarOpened(String lessonId) async {
    if (findGrammarLesson(lessonId) == null) {
      throw ArgumentError.value(lessonId, 'lessonId', 'Unknown lesson');
    }
    final current = await _grammarProgressFor(lessonId);
    if (current.opened) return;
    await setSetting(
      '$_prefix$lessonId',
      jsonEncode(
        GrammarProgress(
          opened: true,
          bestScore: current.bestScore,
          total: current.total,
        ).toJson(),
      ),
    );
  }

  /// Records a quiz result, keeping the best one.
  Future<GrammarProgress> saveGrammarQuiz(
    String lessonId, {
    required int score,
  }) async {
    final lesson = findGrammarLesson(lessonId);
    if (lesson == null) {
      throw ArgumentError.value(lessonId, 'lessonId', 'Unknown lesson');
    }
    final total = lesson.questions.length;
    if (score < 0 || score > total) {
      throw ArgumentError.value(score, 'score', 'Out of range');
    }
    return transaction(() async {
      final current = await _grammarProgressFor(lessonId);
      final best = current.attempted && current.bestScore! > score
          ? current.bestScore!
          : score;
      final updated = GrammarProgress(
        opened: true,
        bestScore: best,
        total: total,
      );
      await setSetting('$_prefix$lessonId', jsonEncode(updated.toJson()));
      return updated;
    });
  }
}
