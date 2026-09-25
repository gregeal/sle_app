import 'dart:convert';
import 'package:drift/drift.dart';
import '../../domain/course/course_catalog.dart';
import 'database.dart';
import 'daos.dart';
import 'speaking_daos.dart';

String _courseKey(String id) => 'course:${courseTrackForLesson(id).id}:$id';

class CourseProgress {
  const CourseProgress({
    this.read = false,
    this.quizPassed = false,
    this.practice = const [],
    this.notes = '',
    this.completedAt,
    this.reviewAt,
    this.reviewCount = 0,
    this.speakingSessionId,
    this.skills = const [false, false, false],
    this.writing = '',
  });
  final bool read, quizPassed;
  final List<bool> practice;

  /// Reading comprehension, listening comprehension, and revised writing.
  final List<bool> skills;
  final String notes;
  final String writing;
  final DateTime? completedAt, reviewAt;
  final int reviewCount;
  final int? speakingSessionId;
  bool get completed => completedAt != null;
  bool get fullCourseCompleted =>
      completed && skills.length == 3 && skills.every((v) => v);
  bool get practised => practice.length == 3 && practice.every((v) => v);
  bool due(DateTime now) =>
      completed && reviewAt != null && !reviewAt!.isAfter(now);

  Map<String, dynamic> toJson() => {
    'version': 1,
    'read': read,
    'quizPassed': quizPassed,
    'practice': practice,
    'notes': notes,
    'completedAt': completedAt?.toIso8601String(),
    'reviewAt': reviewAt?.toIso8601String(),
    'reviewCount': reviewCount,
    'speakingSessionId': speakingSessionId,
    'skills': skills,
    'writing': writing,
  };

  factory CourseProgress.parse(String raw) {
    final value = jsonDecode(raw);
    if (value is! Map<String, dynamic> ||
        value['version'] != 1 ||
        value['read'] is! bool ||
        value['quizPassed'] is! bool ||
        value['notes'] is! String ||
        (value['notes'] as String).length > 3000 ||
        (value['writing'] != null &&
            (value['writing'] is! String ||
                (value['writing'] as String).length > 6000)) ||
        value['practice'] is! List ||
        (value['practice'] as List).any((v) => v is! bool) ||
        !{0, 3}.contains((value['practice'] as List).length) ||
        value['reviewCount'] is! int ||
        (value['reviewCount'] as int) < 0 ||
        (value['skills'] != null &&
            (value['skills'] is! List ||
                (value['skills'] as List).length != 3 ||
                (value['skills'] as List).any((v) => v is! bool))) ||
        (value['speakingSessionId'] != null &&
            (value['speakingSessionId'] is! int ||
                (value['speakingSessionId'] as int) < 1))) {
      throw const FormatException('Invalid course progress');
    }
    DateTime? date(String key) =>
        value[key] == null ? null : DateTime.parse(value[key] as String);
    return CourseProgress(
      read: value['read'],
      quizPassed: value['quizPassed'],
      notes: value['notes'],
      practice: List<bool>.from(value['practice']),
      completedAt: date('completedAt'),
      reviewAt: date('reviewAt'),
      reviewCount: value['reviewCount'],
      speakingSessionId: value['speakingSessionId'],
      skills: value['skills'] == null
          ? const [false, false, false]
          : List<bool>.from(value['skills']),
      writing: value['writing'] ?? '',
    );
  }
}

int courseQuizScore(CourseLesson lesson, List<int> answers) {
  if (answers.length != lesson.questions.length) {
    throw ArgumentError('Incomplete quiz');
  }
  var score = 0;
  for (var i = 0; i < answers.length; i++) {
    if (answers[i] < 0 || answers[i] >= lesson.questions[i].options.length) {
      throw ArgumentError('Invalid answer');
    }
    if (answers[i] == lesson.questions[i].correct) score++;
  }
  return score;
}

extension CourseDaos on AppDatabase {
  Future<CourseProgress> courseProgress(String id) async {
    final raw = await getSetting(_courseKey(id));
    return raw == null ? const CourseProgress() : CourseProgress.parse(raw);
  }

  Future<Map<String, CourseProgress>> courseOverview({
    CourseTrack track = bToCCourse,
  }) async {
    final known = courseTracks.firstWhere((c) => c.id == track.id);
    final prefix = 'course:${known.id}:';
    final rows = await (select(
      appSettings,
    )..where((s) => s.key.like('$prefix%'))).get();
    final validIds = known.lessons.map((l) => l.id).toSet();
    return {
      for (final row in rows)
        if (validIds.contains(row.key.substring(prefix.length)))
          row.key.substring(prefix.length): CourseProgress.parse(row.value),
    };
  }

  /// Merge individual fields in a transaction, so a late notes save cannot
  /// erase a quiz result, practice evidence or a linked partner conversation.
  Future<void> _courseUpdate(
    String id,
    Map<String, dynamic> changes,
    DateTime now,
  ) => transaction(() async {
    final old = await courseProgress(id);
    final updated = CourseProgress.parse(
      jsonEncode({...old.toJson(), ...changes}),
    );
    final value = updated.toJson();
    if (!old.completed &&
        updated.read &&
        updated.quizPassed &&
        updated.practised &&
        updated.skills.every((v) => v)) {
      value['completedAt'] = now.toIso8601String();
      value['reviewAt'] = now.add(const Duration(days: 2)).toIso8601String();
    }
    await setSetting(_courseKey(id), jsonEncode(value));
  });

  Future<void> markCourseRead(String id) =>
      _courseUpdate(id, {'read': true}, DateTime.now());

  Future<void> saveCourseNotes(String id, String notes, {String? writing}) {
    if (notes.length > 3000) throw ArgumentError('Notes too long');
    if (writing != null && writing.length > 6000) {
      throw ArgumentError('Writing too long');
    }
    return _courseUpdate(id, {
      'notes': notes,
      'writing': ?writing,
    }, DateTime.now());
  }

  Future<int> submitCourseQuiz(String id, List<int> answers) =>
      transaction(() async {
        final lesson = findCourseLesson(id);
        final score = courseQuizScore(lesson, answers);
        if (score == lesson.questions.length) {
          await _courseUpdate(id, {'quizPassed': true}, DateTime.now());
        }
        return score;
      });

  Future<void> saveCoursePractice(String id, List<bool> criteria) {
    if (criteria.length != findCourseLesson(id).criteria.length) {
      throw ArgumentError('Invalid rubric');
    }
    return _courseUpdate(id, {
      'practice': List<bool>.from(criteria),
    }, DateTime.now());
  }

  Future<void> completeCourseRecall(
    String id, {
    required List<int> answers,
    required List<bool> criteria,
    required int expectedCount,
    required DateTime now,
    required List<int> comprehensionAnswers,
    required bool writingRevised,
  }) => transaction(() async {
    final lesson = findCourseLesson(id);
    final current = await courseProgress(id);
    if (!current.due(now) ||
        current.reviewCount != expectedCount ||
        courseQuizScore(lesson, answers) != lesson.questions.length ||
        criteria.length != lesson.criteria.length ||
        !criteria.every((v) => v) ||
        !workshopForLesson(id).answersCorrect(comprehensionAnswers) ||
        !writingRevised ||
        current.writing.trim().length < 30) {
      throw StateError('Recall not complete or stale');
    }
    final count = current.reviewCount + 1;
    final days = count == 1
        ? 7
        : count == 2
        ? 21
        : 60;
    await _courseUpdate(id, {
      'reviewCount': count,
      'skills': [true, true, true],
      'reviewAt': now.add(Duration(days: days)).toIso8601String(),
    }, now);
  });

  Future<int> courseSpeakingSession(String id) => transaction(() async {
    final lesson = findCourseLesson(id);
    final progress = await courseProgress(id);
    final existing = progress.speakingSessionId;
    if (existing != null) {
      final session = await (select(
        speakingSessions,
      )..where((s) => s.id.equals(existing))).getSingleOrNull();
      if (session != null && !session.finished && session.turnCount < 30) {
        return existing;
      }
    }
    final created = await createSpeakingSession(
      topic: 'Cours ${courseTrackForLesson(id).label} · ${lesson.title}',
      prompt: lesson.partnerPrompt,
      now: DateTime.now(),
    );
    await _courseUpdate(id, {'speakingSessionId': created}, DateTime.now());
    return created;
  });

  Future<void> saveCourseWorkshop(
    String id, {
    required List<int> answers,
    required bool writingRevised,
  }) => transaction(() async {
    final workshop = workshopForLesson(id);
    final correct = workshop.answerResults(answers);
    final old = await courseProgress(id);
    if (writingRevised && old.writing.trim().length < 30) {
      throw ArgumentError('Write your own draft before validating revision');
    }
    await _courseUpdate(id, {
      'skills': [
        old.skills[0] || correct[0],
        old.skills[1] || correct[1],
        old.skills[2] || writingRevised,
      ],
    }, DateTime.now());
  });

  Future<bool> isFoundationCourseSession(int sessionId) async {
    final progress = await courseOverview(track: aToBCourse);
    return progress.values.any((p) => p.speakingSessionId == sessionId);
  }
}
