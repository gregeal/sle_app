import 'dart:convert';
import 'package:drift/drift.dart';
import '../../data/db/database.dart';
import '../../data/db/weekly_daos.dart';
import '../llm/llm_client.dart';
import '../course/course_catalog.dart';
import 'weekly_report.dart';

extension WeeklyTeachingService on AppDatabase {
  Future<bool> supportsBTransition() async {
    final weeks = (await weeklyHistory())
        .where((w) => w.trackId == 'a-to-b-v1' && w.status == 'closed')
        .take(2)
        .toList();
    if (weeks.length < 2) return false;
    for (final week in weeks) {
      final job = await weeklyFeedback(week.id);
      if (job?.status != 'ready') return false;
      final report = WeeklyReport.parse(job!.reportJson!);
      if (report.skills.values.any(
        (s) =>
            s['confidence'] == 'unknown' ||
            _rank(s['level']) < 2 ||
            (s['evidenceIds'] as List).isEmpty,
      )) {
        return false;
      }
    }
    return true;
  }

  Future<WeeklyReport> generateWeeklyFeedback(int id, LlmClient client) async {
    final job = await weeklyFeedback(id);
    if (job == null) {
      throw StateError('Fermez la semaine pour figer les preuves du bilan.');
    }
    if (job.status == 'ready') return WeeklyReport.parse(job.reportJson!);
    final claimed =
        await (update(weeklyFeedbackJobs)..where(
              (j) => j.weekId.equals(id) & j.status.isNotValue('pending'),
            ))
            .write(
              const WeeklyFeedbackJobsCompanion(
                status: Value('pending'),
                error: Value(null),
              ),
            );
    if (claimed == 0) throw StateError('Un bilan est déjà en cours.');
    try {
      final snapshot = jsonDecode(job.snapshotJson) as Map<String, dynamic>;
      final evidence = List<Map<String, dynamic>>.from(snapshot['evidence']);
      // Keep summaries bounded; the original production stays in local evidence.
      final input = {
        ...snapshot,
        'evidence': [
          for (final e in evidence) {...e, 'data': _boundedData(e['data'])},
        ],
      };
      final report = await requestWeeklyReport(client, input);
      for (final entry in report.skills.entries) {
        final ids = List<int>.from(entry.value['evidenceIds']);
        final relevant = evidence
            .where(
              (e) =>
                  e['skill'] == entry.key &&
                  e['selfReported'] != true &&
                  e['assisted'] != true,
            )
            .toList();
        if (ids.any((id) => !relevant.any((e) => e['id'] == id))) {
          throw const FormatException('Référence de preuve invalide.');
        }
        if (relevant.isEmpty || ids.isEmpty) {
          entry.value['level'] = null;
          entry.value['confidence'] = 'unknown';
        }
      }
      await (update(
        weeklyFeedbackJobs,
      )..where((j) => j.weekId.equals(id))).write(
        WeeklyFeedbackJobsCompanion(
          status: const Value('ready'),
          reportJson: Value(jsonEncode(report.toJson())),
          error: const Value(null),
        ),
      );
      return report;
    } catch (e) {
      await (update(
        weeklyFeedbackJobs,
      )..where((j) => j.weekId.equals(id))).write(
        const WeeklyFeedbackJobsCompanion(
          status: Value('failed'),
          error: Value(
            'Le bilan a échoué. Vos preuves restent enregistrées. Réessayez explicitement.',
          ),
        ),
      );
      rethrow;
    }
  }

  Future<ProgressionRecommendation> recommendNextLesson(String trackId) async {
    final track = courseTracks.firstWhere((t) => t.id == trackId);
    final history = (await weeklyHistory())
        .where((w) => w.trackId == trackId && w.status == 'closed')
        .toList();
    if (history.isEmpty) {
      return ProgressionRecommendation(
        track.lessons.first.id,
        'Début du parcours.',
        false,
      );
    }
    final last = history.first;
    final job = await weeklyFeedback(last.id);
    final evidence = List<Map<String, dynamic>>.from(
      (job == null
          ? await weeklySnapshot(last.id)
          : jsonDecode(job.snapshotJson))['evidence'],
    );
    final skills = evidence
        .where((e) => e['selfReported'] != true && e['assisted'] != true)
        .map((e) => e['skill'])
        .toSet();
    var ready = const [
      'teaching',
      'speaking',
      'reading',
      'listening',
      'writing',
    ].every(skills.contains);
    for (final e in evidence) {
      final d = e['data'];
      if (d is Map &&
          d['correct'] is int &&
          d['total'] is int &&
          d['total'] > 0 &&
          d['correct'] / d['total'] < .75) {
        ready = false;
      }
    }
    if (job?.status == 'ready') {
      final report = WeeklyReport.parse(job!.reportJson!);
      final target = trackId == 'a-to-b-v1' ? 'B' : 'C';
      for (final s in report.skills.values) {
        if (s['level'] == null || _rank(s['level']) < _rank(target)) {
          ready = false;
        }
      }
    } else {
      ready = false;
    }
    final index = track.lessons.indexWhere((l) => l.id == last.lessonId);
    final next = index + 1;
    return ProgressionRecommendation(
      ready && next < track.lessons.length
          ? track.lessons[next].id
          : last.lessonId,
      ready
          ? 'Les preuves soutiennent la suite; vous pouvez confirmer ou choisir une révision.'
          : 'Certaines preuves sont limitées ou le bilan reste à faire. Une révision est recommandée; vous pouvez avancer explicitement.',
      !ready,
    );
  }
}

int _rank(Object? level) => switch (level) {
  'A' => 0,
  'A+' => 1,
  'B' => 2,
  'B+' => 3,
  'C' => 4,
  _ => -1,
};
Object? _boundedData(Object? data) {
  if (data is String) {
    return data.length > 1200 ? data.substring(0, 1200) : data;
  }
  if (data is List) return data.take(4).map(_boundedData).toList();
  if (data is Map) {
    return {
      for (final e in data.entries) e.key.toString(): _boundedData(e.value),
    };
  }
  return data;
}
