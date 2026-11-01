import 'dart:convert';

import 'package:drift/drift.dart';

import '../../domain/weekly/weekly_plan.dart';
import '../../domain/weekly/weekly_report.dart';
import '../../domain/course/course_catalog.dart';
import 'daos.dart';
import 'database.dart';

const _activeWeekSetting = 'weekly:activeWeekId';

/// Evidence kinds a completed assignment may point at.
const weeklyEvidenceKinds = {
  'oralAttempt',
  'speakingSession',
  'writingAttempt',
  'readingAttempt',
  'listeningAttempt',
  'drillAttempt',
  'courseLesson',
};

String _dateKey(DateTime day) =>
    '${day.year.toString().padLeft(4, '0')}-'
    '${day.month.toString().padLeft(2, '0')}-'
    '${day.day.toString().padLeft(2, '0')}';

extension StudyWeekPlan on StudyWeek {
  /// The exact plan the learner was given when the week opened.
  WeeklyPlan get plan =>
      WeeklyPlan.fromJson(jsonDecode(planJson) as Map<String, dynamic>);
}

extension WeeklyAssignmentPayload on WeeklyAssignment {
  Map<String, dynamic> get payload =>
      jsonDecode(payloadJson) as Map<String, dynamic>;
  bool get completed => completedAt != null;
}

extension WeeklyDaos on AppDatabase {
  /// Opens a week from a composed plan. Exactly one week may be active, so the
  /// previous one must be closed (which is what produces its report) first.
  Future<int> createStudyWeek({
    required WeeklyPlan plan,
    required DateTime startDate,
    List<int> weekdays = const [1, 2, 3, 4, 5],
  }) => transaction(() async {
    plan.validate();
    if (await activeStudyWeek() != null) {
      throw StateError('Close the active week before opening another one.');
    }
    final now = DateTime.now();
    final weekId = await into(studyWeeks).insert(
      StudyWeeksCompanion.insert(
        weekNumber: plan.weekNumber,
        trackId: plan.trackId,
        lessonId: plan.lessonId,
        startDate: _dateKey(startDate),
        planJson: jsonEncode(plan.toJson()),
        createdAt: now,
        scheduleJson: Value(
          jsonEncode(
            scheduledStudyDates(
              startDate,
              weekdays,
              count: plan.studyDays,
            ).map(studyDateKey).toList(),
          ),
        ),
      ),
    );
    for (final spec in plan.assignments) {
      await into(weeklyAssignments).insert(
        WeeklyAssignmentsCompanion.insert(
          weekId: weekId,
          specId: spec.id,
          dayIndex: spec.dayIndex,
          skill: spec.skill.name,
          minutes: spec.minutes,
          titleFr: spec.titleFr,
          subtitleFr: spec.subtitleFr,
          payloadJson: jsonEncode(spec.payload),
        ),
      );
    }
    await setSetting(_activeWeekSetting, '$weekId');
    await setSetting('weekly:enabled', 'true');
    return weekId;
  });

  Future<StudyWeek?> studyWeek(int id) =>
      (select(studyWeeks)..where((w) => w.id.equals(id))).getSingleOrNull();

  Future<StudyWeek?> activeStudyWeek() async {
    final row =
        await (select(studyWeeks)
              ..where((w) => w.status.equals('active'))
              ..orderBy([(w) => OrderingTerm.desc(w.id)])
              ..limit(1))
            .getSingleOrNull();
    return row;
  }

  /// Newest first.
  Future<List<StudyWeek>> weeklyHistory() => (select(
    studyWeeks,
  )..orderBy([(w) => OrderingTerm.desc(w.weekNumber)])).get();

  Future<List<WeeklyAssignment>> assignmentsForWeek(int weekId) =>
      (select(weeklyAssignments)
            ..where((a) => a.weekId.equals(weekId))
            ..orderBy([
              (a) => OrderingTerm.asc(a.dayIndex),
              (a) => OrderingTerm.asc(a.id),
            ]))
          .get();

  Future<WeeklyAssignment> weeklyAssignment(int id) =>
      (select(weeklyAssignments)..where((a) => a.id.equals(id))).getSingle();

  Future<List<WeeklyAssignment>> assignmentsForDay(int weekId, int dayIndex) =>
      (select(weeklyAssignments)
            ..where(
              (a) => a.weekId.equals(weekId) & a.dayIndex.equals(dayIndex),
            )
            ..orderBy([(a) => OrderingTerm.asc(a.id)]))
          .get();

  /// Marks an assignment done. The first completion wins, so re-opening a
  /// finished activity never rewrites the evidence or the timestamp.
  Future<void> completeAssignment(
    int assignmentId, {
    String? evidenceKind,
    int? evidenceId,
    required DateTime at,
  }) {
    if ((evidenceKind == null) != (evidenceId == null)) {
      throw ArgumentError('Evidence needs both a kind and an id, or neither.');
    }
    if (evidenceKind != null && !weeklyEvidenceKinds.contains(evidenceKind)) {
      throw ArgumentError.value(evidenceKind, 'evidenceKind', 'Unknown kind');
    }
    if (evidenceId != null && evidenceId < 1) {
      throw ArgumentError.value(evidenceId, 'evidenceId', 'Invalid id');
    }
    return transaction(() async {
      final current = await weeklyAssignment(assignmentId);
      final week = await studyWeek(current.weekId);
      if (week?.status != 'active') {
        throw StateError('Cette semaine est close.');
      }
      if (evidenceKind == null || evidenceId == null) {
        throw ArgumentError('Une preuve explicite est requise.');
      }
      final kind = EvidenceKind.values.where((k) => k.name == evidenceKind);
      if (kind.isEmpty) {
        throw ArgumentError('Référence historique non vérifiable.');
      }
      await saveAssignmentEvidence(
        assignmentId,
        AssignmentEvidence(
          kind: kind.single,
          sourceId: evidenceId,
          data: const {},
        ),
        at: at,
      );
      return;
    });
  }

  /// Minutes per [SkillKind] name for a week. Skills with no minutes are
  /// absent rather than zero, so a caller can tell "not planned" from "planned
  /// but not done yet".
  Future<Map<String, int>> weeklyMinutesBySkill(
    int weekId, {
    bool completedOnly = false,
  }) async {
    final rows = await assignmentsForWeek(weekId);
    final totals = <String, int>{};
    for (final row in rows) {
      if (completedOnly &&
          (row.completedAt == null || row.evidenceKind != 'weeklyEvidence')) {
        continue;
      }
      totals[row.skill] = (totals[row.skill] ?? 0) + row.minutes;
    }
    return totals;
  }

  Future<void> closeStudyWeek(
    int weekId, {
    String? reportJson,
    required DateTime at,
  }) => transaction(() async {
    final week = await studyWeek(weekId);
    if (week == null || week.status != 'active') {
      throw StateError('Only an active week can be closed.');
    }
    if (reportJson != null) WeeklyReport.parse(reportJson);
    final snapshot = await weeklySnapshot(weekId);
    await into(weeklyFeedbackJobs).insertOnConflictUpdate(
      WeeklyFeedbackJobsCompanion.insert(
        weekId: Value(weekId),
        snapshotJson: jsonEncode(snapshot),
        status: Value(reportJson == null ? 'notRequested' : 'ready'),
        reportJson: Value(reportJson),
      ),
    );
    await (update(studyWeeks)..where((w) => w.id.equals(weekId))).write(
      StudyWeeksCompanion(
        status: const Value('closed'),
        reportJson: Value(reportJson),
        closedAt: Value(at),
      ),
    );
    await setSetting(_activeWeekSetting, '');
  });

  Future<int> saveAssignmentEvidence(
    int assignmentId,
    AssignmentEvidence evidence, {
    required DateTime at,
  }) => transaction(() async {
    final assignment = await weeklyAssignment(assignmentId);
    final week = await studyWeek(assignment.weekId);
    if (week == null || week.status != 'active') {
      throw StateError('Semaine close : utilisez une nouvelle activité.');
    }
    final data = Map<String, dynamic>.from(evidence.data);
    if (jsonEncode(data).length > 100000 ||
        (evidence.observedSeconds != null &&
            (evidence.observedSeconds! < 0 ||
                evidence.observedSeconds! > 14400))) {
      throw ArgumentError('Preuve trop volumineuse.');
    }
    final lesson = findCourseLesson(week.lessonId);
    final skill = assignment.skill;
    final source = evidence.sourceId;
    switch (evidence.kind) {
      case EvidenceKind.quiz:
        if (skill != 'teaching' || data['answers'] is! List) {
          throw ArgumentError('Quiz requis.');
        }
        final answers = List<int>.from(data['answers']);
        if (answers.length != lesson.questions.length) {
          throw ArgumentError('Quiz incomplet.');
        }
        for (var i = 0; i < answers.length; i++) {
          if (answers[i] < 0 ||
              answers[i] >= lesson.questions[i].options.length) {
            throw ArgumentError('Réponse invalide.');
          }
        }
        data['correct'] = List.generate(
          answers.length,
          (i) => answers[i] == lesson.questions[i].correct,
        ).where((v) => v).length;
        data['total'] = answers.length;
      case EvidenceKind.spokenPractice:
        if (skill != 'speaking' ||
            data['exchanges'] is! List ||
            (data['exchanges'] as List).isEmpty ||
            (data['exchanges'] as List).length > 100 ||
            (data['exchanges'] as List).any(
              (e) =>
                  e is! Map ||
                  e['answer'] is! String ||
                  (e['answer'] as String).trim().isEmpty,
            )) {
          throw ArgumentError('Production orale requise.');
        }
      case EvidenceKind.solo:
        if (!evidence.selfReported ||
            data['reflection'] is! String ||
            (data['reflection'] as String).trim().length < 10) {
          throw ArgumentError(
            'Confirmez votre pratique et ajoutez une réflexion.',
          );
        }
      case EvidenceKind.readingAttempt:
      case EvidenceKind.listeningAttempt:
        final expected = evidence.kind == EvidenceKind.readingAttempt
            ? 'reading'
            : 'listening';
        if (skill != expected || data['answer'] is! int) {
          throw ArgumentError('Compréhension requise.');
        }
        final workshop = workshopForLesson(week.lessonId);
        final question = skill == 'reading'
            ? workshop.readingQuestion
            : workshop.listeningQuestion;
        final answer = data['answer'] as int;
        if (answer < 0 || answer >= question.options.length) {
          throw ArgumentError('Réponse invalide.');
        }
        data['correct'] = answer == question.correct ? 1 : 0;
        data['total'] = 1;
        data['passage'] = skill == 'reading'
            ? workshop.reading
            : workshop.listening;
        data['question'] = question.prompt;
      case EvidenceKind.writingAttempt:
        if (skill != 'writing' ||
            data['draft'] is! String ||
            (data['draft'] as String).trim().length < 30 ||
            (data['draft'] as String).length > 6000 ||
            data['revised'] != true) {
          throw ArgumentError('Rédigez et relisez votre texte.');
        }
        data['task'] = workshopForLesson(week.lessonId).writingTask;
      case EvidenceKind.vocabulary:
        if (skill != 'vocabulary' ||
            data['reviewed'] is! int ||
            (data['reviewed'] as int) < 1 ||
            data['cardIds'] is! List) {
          throw ArgumentError('Révisez au moins une carte.');
        }
        final ids = List<int>.from(data['cardIds']);
        if (ids.toSet().length != ids.length ||
            ids.length != data['reviewed']) {
          throw ArgumentError('Cartes invalides.');
        }
        final cards = await (select(
          vocabCards,
        )..where((c) => c.id.isIn(ids))).get();
        if (cards.length != ids.length) {
          throw ArgumentError('Carte introuvable.');
        }
      case EvidenceKind.oralAttempt:
        if (skill != 'speaking' || source == null) {
          throw ArgumentError('Entretien requis.');
        }
        final row = await (select(
          oralAttempts,
        )..where((a) => a.id.equals(source))).getSingleOrNull();
        if (row == null ||
            row.mode != 'class' ||
            row.answeredAt.isBefore(week.createdAt) ||
            await getSetting('weekly:oralAttempt:$assignmentId') != '$source') {
          throw ArgumentError('Entretien sans lien avec cette semaine.');
        }
        data['exchanges'] = jsonDecode(row.exchanges);
        data['feedback'] = jsonDecode(row.feedback);
      case EvidenceKind.speakingSession:
        if (skill != 'speaking' || source == null) {
          throw ArgumentError('Conversation requise.');
        }
        final row = await (select(
          speakingSessions,
        )..where((a) => a.id.equals(source))).getSingleOrNull();
        if (row == null ||
            !row.finished ||
            row.createdAt.isBefore(week.createdAt) ||
            await getSetting('weekly:manualSession:$assignmentId') !=
                '$source') {
          throw ArgumentError('Conversation incomplète.');
        }
        final turns =
            await (select(speakingTurns)
                  ..where((t) => t.sessionId.equals(source))
                  ..orderBy([(t) => OrderingTerm.asc(t.turnNumber)]))
                .get();
        if (turns.isEmpty) throw ArgumentError('Conversation sans production.');
        data['sourceRecordCount'] = turns.length;
        data['exchanges'] = [
          for (final t in turns.reversed.take(6).toList().reversed)
            {
              'question': t.promptFr,
              'answer': t.answer.length > 2000
                  ? t.answer.substring(0, 2000)
                  : t.answer,
            },
        ];
    }
    data['lessonId'] = week.lessonId;
    final previous =
        await (select(weeklyEvidence)
              ..where((e) => e.assignmentId.equals(assignmentId))
              ..orderBy([(e) => OrderingTerm.desc(e.id)])
              ..limit(1))
            .getSingleOrNull();
    if (previous != null &&
        previous.kind == evidence.kind.name &&
        previous.dataJson == jsonEncode(data) &&
        previous.assisted == evidence.assisted &&
        previous.selfReported == evidence.selfReported) {
      return previous.id;
    }
    final id = await into(weeklyEvidence).insert(
      WeeklyEvidenceCompanion.insert(
        assignmentId: assignmentId,
        kind: evidence.kind.name,
        dataJson: jsonEncode(data),
        sourceId: Value(source),
        assisted: Value(evidence.assisted),
        selfReported: Value(evidence.selfReported),
        observedSeconds: Value(evidence.observedSeconds),
        createdAt: at,
      ),
    );
    await (update(
      weeklyAssignments,
    )..where((a) => a.id.equals(assignmentId))).write(
      WeeklyAssignmentsCompanion(
        completedAt: Value(assignment.completedAt ?? at),
        evidenceKind: Value('weeklyEvidence'),
        evidenceId: Value(id),
      ),
    );
    return id;
  });

  Future<ClassProgress> classProgress(int weekId) async {
    final row = await (select(
      weeklyClassStates,
    )..where((s) => s.weekId.equals(weekId))).getSingleOrNull();
    return row == null
        ? const ClassProgress()
        : ClassProgress.fromJson(
            jsonDecode(row.stateJson) as Map<String, dynamic>,
          );
  }

  Future<void> saveClassProgress(int weekId, ClassProgress state) async {
    if ((await studyWeek(weekId))?.status != 'active') {
      throw StateError('Semaine close.');
    }
    ClassProgress.fromJson(state.toJson());
    await into(weeklyClassStates).insertOnConflictUpdate(
      WeeklyClassStatesCompanion.insert(
        weekId: Value(weekId),
        stateJson: jsonEncode(state.toJson()),
      ),
    );
  }

  Future<List<String>> studyDates(StudyWeek week) async {
    final raw = jsonDecode(week.scheduleJson);
    if (raw is List &&
        raw.length == week.plan.studyDays &&
        raw.every((d) => d is String && DateTime.tryParse(d) != null)) {
      return List<String>.from(raw);
    }
    final dates = scheduledStudyDates(
      DateTime.parse(week.startDate),
      await studyWeekdays(),
      count: week.plan.studyDays,
    ).map(studyDateKey).toList();
    await (update(studyWeeks)..where((w) => w.id.equals(week.id))).write(
      StudyWeeksCompanion(scheduleJson: Value(jsonEncode(dates))),
    );
    return dates;
  }

  Future<List<int>> studyWeekdays() async {
    final raw = await getSetting('weekly:weekdays');
    if (raw == null) return [1, 2, 3, 4, 5];
    final days = List<int>.from(jsonDecode(raw));
    scheduledStudyDates(DateTime(2026), days);
    return days;
  }

  Future<void> setStudyWeekdays(List<int> days) async {
    scheduledStudyDates(DateTime(2026), days);
    await setSetting('weekly:weekdays', jsonEncode(days));
  }

  Future<void> reconcileStudyCalendar(DateTime now) async {
    final week = await activeStudyWeek();
    if (week == null || week.paused) return;
    final dates = await studyDates(week);
    if (studyDateKey(now).compareTo(dates.last) > 0) {
      await closeStudyWeek(week.id, at: now);
    }
  }

  Future<void> pauseStudyWeek(int id, bool pause, DateTime now) =>
      transaction(() async {
        final week = await studyWeek(id);
        if (week == null || week.status != 'active') {
          throw StateError('Semaine inactive.');
        }
        final dates = await studyDates(week);
        if (!pause && week.paused) {
          final state = await getSetting('weekly:pause:$id');
          final first = int.tryParse(state ?? '') ?? 0;
          if (first < dates.length) {
            final remaining = scheduledStudyDates(
              now,
              await studyWeekdays(),
              count: dates.length - first,
            ).map(studyDateKey).toList();
            dates.replaceRange(first, dates.length, remaining);
          }
        } else if (pause) {
          final rows = await assignmentsForWeek(id);
          final index =
              dates.indexed
                  .where(
                    (entry) =>
                        entry.$2.compareTo(studyDateKey(now)) >= 0 &&
                        rows.any(
                          (a) => a.dayIndex == entry.$1 + 1 && !a.completed,
                        ),
                  )
                  .map((entry) => entry.$1)
                  .firstOrNull ??
              -1;
          await setSetting(
            'weekly:pause:$id',
            '${index < 0 ? dates.length : index}',
          );
        }
        await (update(studyWeeks)..where((w) => w.id.equals(id))).write(
          StudyWeeksCompanion(
            paused: Value(pause),
            scheduleJson: Value(jsonEncode(dates)),
          ),
        );
      });
  Future<Map<String, dynamic>> weeklySnapshot(int weekId) async {
    final week = await studyWeek(weekId);
    if (week == null) throw StateError('Semaine absente.');
    final assignments = await assignmentsForWeek(weekId);
    final evidence = await (select(
      weeklyEvidence,
    )..where((e) => e.assignmentId.isIn(assignments.map((a) => a.id)))).get();
    return {
      'version': 1,
      'weekId': weekId,
      'trackId': week.trackId,
      'lessonId': week.lessonId,
      'objective': findCourseLesson(week.lessonId).objective,
      'assignments': [
        for (final a in assignments)
          {
            'id': a.id,
            'skill': a.skill,
            'minutes': a.minutes,
            'completed': a.completed,
            'verified': evidence.any((e) => e.assignmentId == a.id),
          },
      ],
      'evidence': [
        for (final e in evidence)
          {
            'id': e.id,
            'assignmentId': e.assignmentId,
            'skill': assignments
                .firstWhere((a) => a.id == e.assignmentId)
                .skill,
            'kind': e.kind,
            'assisted': e.assisted,
            'selfReported': e.selfReported,
            'observedSeconds': e.observedSeconds,
            'data': jsonDecode(e.dataJson),
          },
      ],
    };
  }

  Future<WeeklyFeedbackJob?> weeklyFeedback(int id) => (select(
    weeklyFeedbackJobs,
  )..where((j) => j.weekId.equals(id))).getSingleOrNull();
  Future<WeeklyFeedbackJob> ensureWeeklyFeedback(int id) =>
      transaction(() async {
        final existing = await weeklyFeedback(id);
        if (existing != null) return existing;
        if ((await studyWeek(id))?.status != 'closed') {
          throw StateError('La semaine doit être close.');
        }
        await into(weeklyFeedbackJobs).insert(
          WeeklyFeedbackJobsCompanion.insert(
            weekId: Value(id),
            snapshotJson: jsonEncode(await weeklySnapshot(id)),
          ),
        );
        return (await weeklyFeedback(id))!;
      });
  Future<int> reserveWeeklyVoice(int id) => transaction(() async {
    if ((await studyWeek(id))?.status != 'active') {
      throw StateError('Semaine inactive.');
    }
    final leases = await (select(
      weeklyVoiceLeases,
    )..where((l) => l.weekId.equals(id))).get();
    final used = leases.fold<int>(
      0,
      (n, l) => n + (l.usedSeconds ?? l.reservedSeconds),
    );
    final remaining = 1200 - used;
    if (remaining <= 0) {
      throw StateError(
        'Les 20 minutes en direct ont été utilisées. Choisissez la pratique autonome.',
      );
    }
    return into(weeklyVoiceLeases).insert(
      WeeklyVoiceLeasesCompanion.insert(
        weekId: id,
        reservedSeconds: remaining,
        createdAt: DateTime.now(),
      ),
    );
  });
  Future<int> voiceLeaseSeconds(int id) async => (await (select(
    weeklyVoiceLeases,
  )..where((l) => l.id.equals(id))).getSingle()).reservedSeconds;
  Future<void> settleWeeklyVoice(int id, int used) => transaction(() async {
    final lease = await (select(
      weeklyVoiceLeases,
    )..where((l) => l.id.equals(id))).getSingle();
    if (lease.usedSeconds != null) return;
    await (update(weeklyVoiceLeases)..where((l) => l.id.equals(id))).write(
      WeeklyVoiceLeasesCompanion(
        usedSeconds: Value(used.clamp(0, lease.reservedSeconds)),
      ),
    );
  });
  Future<void> recoverWeeklyFeedback(int id) async {
    await (update(
      weeklyFeedbackJobs,
    )..where((j) => j.weekId.equals(id) & j.status.equals('pending'))).write(
      const WeeklyFeedbackJobsCompanion(
        status: Value('failed'),
        error: Value('Demande interrompue récupérée.'),
      ),
    );
  }

  Future<void> archiveInvalidWeek(int id) async {
    final week = await studyWeek(id);
    if (week == null) return;
    try {
      week.plan.validate();
      throw StateError('Cette semaine est valide; utilisez la clôture.');
    } on FormatException {
      await (update(studyWeeks)..where((w) => w.id.equals(id))).write(
        StudyWeeksCompanion(
          status: const Value('archived'),
          closedAt: Value(DateTime.now()),
        ),
      );
      await setSetting(_activeWeekSetting, '');
    }
  }

  Future<void> swapCatchup(
    int weekId,
    int previousId,
    int todayId,
    String date,
  ) => transaction(() async {
    final week = await studyWeek(weekId);
    if (week == null || week.status != 'active' || week.paused) {
      throw StateError('Semaine inactive.');
    }
    if (await getSetting('weekly:catchup:$weekId:$date') != null) {
      throw StateError('Un seul rattrapage par jour.');
    }
    final dates = await studyDates(week);
    final day = dates.indexOf(date) + 1;
    final previous = await weeklyAssignment(previousId),
        today = await weeklyAssignment(todayId);
    if (day < 2 ||
        previous.weekId != weekId ||
        today.weekId != weekId ||
        previous.dayIndex != day - 1 ||
        today.dayIndex != day ||
        previous.completed ||
        today.completed ||
        previous.skill == 'teaching' ||
        previous.skill != today.skill ||
        previous.minutes != today.minutes) {
      throw ArgumentError('Rattrapage incompatible avec le budget.');
    }
    await (update(weeklyAssignments)..where((a) => a.id.equals(previousId)))
        .write(WeeklyAssignmentsCompanion(dayIndex: Value(day)));
    await (update(weeklyAssignments)..where((a) => a.id.equals(todayId))).write(
      WeeklyAssignmentsCompanion(dayIndex: Value(day - 1)),
    );
    await setSetting(
      'weekly:catchup:$weekId:$date',
      jsonEncode({'from': previousId, 'replaced': todayId}),
    );
  });
}
