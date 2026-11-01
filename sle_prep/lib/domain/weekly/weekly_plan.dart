/// The weekly study plan: a pure, deterministic allocator that turns a weekly
/// budget into day-by-day assignments across the four language skills.
///
/// Speaking is deliberately dominant; listening, reading and writing stay
/// evenly distributed around it. The published contract is encoded in the
/// constants below and asserted by the tests, so adaptation can shift emphasis
/// without ever reshaping the week into something lopsided.
library;

/// Speaking never drops below this share of the week, and never exceeds the
/// ceiling: beyond it the other skills lose their guaranteed floor.
const kSpeakingMinShare = 0.40;
const kSpeakingMaxShare = 0.50;

/// Listening, reading and writing each hold a band of the remaining time.
const kDistributedMinShare = 0.12;
const kDistributedMaxShare = 0.20;

/// "Well distributed" in the requirement means the three never drift more
/// than this far apart within one week.
const kMaxDistributedSpread = 0.08;

/// Blocks shorter than this are not worth opening the app for.
const kMinimumBlockMinutes = 5;

const distributedSkills = [
  SkillKind.listening,
  SkillKind.reading,
  SkillKind.writing,
];

const _unit = kMinimumBlockMinutes;
const _baseSpeakingShare = 0.42;
const _baseTeachingShare = 0.05;
const _maxTeachingShare = 0.08;
const _baseVocabularyShare = 0.09;
const _minVocabularyShare = 0.05;
const _maxVocabularyShare = 0.12;

enum SkillKind { teaching, speaking, listening, reading, writing, vocabulary }

SkillKind _skillByName(String name) =>
    SkillKind.values.firstWhere((value) => value.name == name);

/// How the previous week's review asks the next week to lean.
class WeeklyEmphasis {
  const WeeklyEmphasis({this.reinforce = const {}, this.speakingBoost = 0});
  const WeeklyEmphasis.balanced() : reinforce = const {}, speakingBoost = 0;

  /// Skills to push toward their ceiling. Only listening, reading and writing
  /// can be reinforced: speaking is already dominant by contract and teaching
  /// is fixed by the class.
  final Set<SkillKind> reinforce;

  /// Added to the base speaking share before clamping to the contract band.
  final double speakingBoost;
}

class WeeklyAssignmentSpec {
  const WeeklyAssignmentSpec({
    required this.id,
    required this.dayIndex,
    required this.skill,
    required this.minutes,
    required this.titleFr,
    required this.subtitleFr,
    required this.payload,
  });

  /// Stable within a week, so completion survives a plan reload.
  final String id;
  final int dayIndex;
  final SkillKind skill;
  final int minutes;
  final String titleFr;
  final String subtitleFr;

  /// What the UI should open, resolved by the feature screens.
  final Map<String, Object?> payload;

  Map<String, Object?> toJson() => {
    'id': id,
    'dayIndex': dayIndex,
    'skill': skill.name,
    'minutes': minutes,
    'titleFr': titleFr,
    'subtitleFr': subtitleFr,
    'payload': payload,
  };

  factory WeeklyAssignmentSpec.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final dayIndex = json['dayIndex'];
    final skillName = json['skill'];
    final minutes = json['minutes'];
    final title = json['titleFr'];
    final subtitle = json['subtitleFr'];
    final payload = json['payload'];
    if (id is! String || id.isEmpty) {
      throw const FormatException('An assignment needs a non-empty id.');
    }
    if (dayIndex is! int || dayIndex < 1 || dayIndex > 7) {
      throw const FormatException('An assignment needs a day between 1 and 7.');
    }
    if (skillName is! String ||
        !SkillKind.values.any((value) => value.name == skillName)) {
      throw FormatException('Unknown assignment skill: $skillName');
    }
    if (minutes is! int ||
        minutes < kMinimumBlockMinutes ||
        minutes > 24 * 60) {
      throw const FormatException('An assignment needs plausible minutes.');
    }
    if (title is! String || title.isEmpty || subtitle is! String) {
      throw const FormatException('An assignment needs display text.');
    }
    if (payload is! Map<String, dynamic>) {
      throw const FormatException('An assignment payload must be an object.');
    }
    return WeeklyAssignmentSpec(
      id: id,
      dayIndex: dayIndex,
      skill: _skillByName(skillName),
      minutes: minutes,
      titleFr: title,
      subtitleFr: subtitle,
      payload: Map.unmodifiable(payload),
    );
  }
}

class WeeklyPlan {
  const WeeklyPlan({
    required this.weekNumber,
    required this.trackId,
    required this.lessonId,
    required this.lessonTitleFr,
    required this.studyDays,
    required this.minutesPerDay,
    required this.assignments,
  });

  static const version = 1;

  final int weekNumber;
  final String trackId;
  final String lessonId;
  final String lessonTitleFr;
  final int studyDays;
  final int minutesPerDay;
  final List<WeeklyAssignmentSpec> assignments;

  int get totalMinutes =>
      assignments.fold(0, (sum, block) => sum + block.minutes);

  Map<SkillKind, int> get minutesBySkill {
    final totals = <SkillKind, int>{for (final skill in SkillKind.values) skill: 0};
    for (final block in assignments) {
      totals[block.skill] = totals[block.skill]! + block.minutes;
    }
    return totals;
  }

  int minutesFor(SkillKind skill) => assignments
      .where((block) => block.skill == skill)
      .fold(0, (sum, block) => sum + block.minutes);

  double shareOf(SkillKind skill) =>
      totalMinutes == 0 ? 0 : minutesFor(skill) / totalMinutes;

  List<WeeklyAssignmentSpec> assignmentsForDay(int dayIndex) => assignments
      .where((block) => block.dayIndex == dayIndex)
      .toList(growable: false);

  Map<String, Object?> toJson() => {
    'version': version,
    'weekNumber': weekNumber,
    'trackId': trackId,
    'lessonId': lessonId,
    'lessonTitleFr': lessonTitleFr,
    'studyDays': studyDays,
    'minutesPerDay': minutesPerDay,
    'assignments': [for (final block in assignments) block.toJson()],
  };

  factory WeeklyPlan.fromJson(Map<String, dynamic> json) {
    if (json['version'] != version) {
      throw FormatException('Unsupported weekly plan version: ${json['version']}');
    }
    final weekNumber = json['weekNumber'];
    final trackId = json['trackId'];
    final lessonId = json['lessonId'];
    final lessonTitle = json['lessonTitleFr'];
    final studyDays = json['studyDays'];
    final minutesPerDay = json['minutesPerDay'];
    final rawAssignments = json['assignments'];
    if (weekNumber is! int || weekNumber < 1) {
      throw const FormatException('A weekly plan needs a positive week number.');
    }
    if (trackId is! String ||
        trackId.isEmpty ||
        lessonId is! String ||
        lessonId.isEmpty ||
        lessonTitle is! String) {
      throw const FormatException('A weekly plan needs its lesson binding.');
    }
    if (studyDays is! int || studyDays < 3 || studyDays > 7) {
      throw const FormatException('A weekly plan needs 3 to 7 study days.');
    }
    if (minutesPerDay is! int || minutesPerDay < 30 || minutesPerDay > 120) {
      throw const FormatException('A study day must be 30 to 120 minutes.');
    }
    if (rawAssignments is! List) {
      throw const FormatException('A weekly plan needs a list of assignments.');
    }
    return WeeklyPlan(
      weekNumber: weekNumber,
      trackId: trackId,
      lessonId: lessonId,
      lessonTitleFr: lessonTitle,
      studyDays: studyDays,
      minutesPerDay: minutesPerDay,
      assignments: List.unmodifiable([
        for (final raw in rawAssignments)
          WeeklyAssignmentSpec.fromJson(
            raw is Map<String, dynamic>
                ? raw
                : throw const FormatException('Assignments must be objects.'),
          ),
      ]),
    );
  }
}

/// Builds one week. Pure and deterministic: the same inputs always produce the
/// same plan, so a stored week never silently re-plans under the learner.
WeeklyPlan composeWeeklyPlan({
  required int weekNumber,
  required String trackId,
  required String lessonId,
  required String lessonTitleFr,
  int studyDays = 5,
  int minutesPerDay = 60,
  WeeklyEmphasis emphasis = const WeeklyEmphasis.balanced(),
}) {
  if (weekNumber < 1) {
    throw ArgumentError.value(weekNumber, 'weekNumber', 'Weeks start at 1.');
  }
  if (studyDays < 3 || studyDays > 7) {
    throw ArgumentError.value(studyDays, 'studyDays', 'Use 3 to 7 study days.');
  }
  if (minutesPerDay < 30 || minutesPerDay > 120) {
    throw ArgumentError.value(
      minutesPerDay,
      'minutesPerDay',
      'A study day must be 30 to 120 minutes.',
    );
  }
  if (minutesPerDay % _unit != 0) {
    throw ArgumentError.value(
      minutesPerDay,
      'minutesPerDay',
      'Use a multiple of $_unit minutes so no block is a sliver.',
    );
  }
  if (!emphasis.speakingBoost.isFinite) {
    throw ArgumentError.value(
      emphasis.speakingBoost,
      'speakingBoost',
      'The boost must be a finite number.',
    );
  }
  for (final skill in emphasis.reinforce) {
    if (!distributedSkills.contains(skill)) {
      throw ArgumentError.value(
        skill,
        'reinforce',
        'Only listening, reading and writing can be reinforced.',
      );
    }
  }

  // Work in 5-minute units: every pool and every day capacity is then a whole
  // number of units, so a greedy fill can never leave an unusable sliver.
  final units = (studyDays * minutesPerDay) ~/ _unit;
  final budget = _allocate(units, emphasis);
  return _layout(
    weekNumber: weekNumber,
    trackId: trackId,
    lessonId: lessonId,
    lessonTitleFr: lessonTitleFr,
    studyDays: studyDays,
    minutesPerDay: minutesPerDay,
    budget: budget,
  );
}

class _Budget {
  const _Budget(this.teaching, this.speaking, this.vocabulary, this.distributed);
  final int teaching;
  final int speaking;
  final int vocabulary;

  /// Keyed by [distributedSkills], in that order.
  final Map<SkillKind, int> distributed;
}

_Budget _allocate(int units, WeeklyEmphasis emphasis) {
  final minDistributedEach = (kDistributedMinShare * units).ceil();
  final maxDistributedEach = (kDistributedMaxShare * units).floor();
  final minPool = minDistributedEach * distributedSkills.length;

  final teaching = ((_baseTeachingShare * units).round()).clamp(
    1,
    (_maxTeachingShare * units).floor().clamp(1, units),
  );

  var speaking = ((_baseSpeakingShare + emphasis.speakingBoost) * units)
      .round()
      .clamp(
        (kSpeakingMinShare * units).ceil(),
        (kSpeakingMaxShare * units).floor(),
      );
  var vocabulary = ((_baseVocabularyShare * units).round()).clamp(
    (_minVocabularyShare * units).ceil(),
    (_maxVocabularyShare * units).floor(),
  );

  // The three distributed skills own a guaranteed floor. If the dominant
  // shares squeezed it, give vocabulary back first and only then speaking --
  // never the floor itself.
  var pool = units - teaching - speaking - vocabulary;
  if (pool < minPool) {
    // Vocabulary supports the four skills rather than being one of them, so
    // at a tight budget it yields entirely before any skill loses its floor.
    final give = (minPool - pool).clamp(0, vocabulary);
    vocabulary -= give;
    pool += give;
  }
  if (pool < minPool) {
    final speakingFloor = (kSpeakingMinShare * units).ceil();
    final give = (minPool - pool).clamp(0, speaking - speakingFloor);
    speaking -= give;
    pool += give;
  }

  // Even split, with any remainder handed out in a fixed order.
  final distributed = <SkillKind, int>{
    for (final skill in distributedSkills) skill: pool ~/ distributedSkills.length,
  };
  for (var i = 0; i < pool % distributedSkills.length; i++) {
    final skill = distributedSkills[i];
    distributed[skill] = distributed[skill]! + 1;
  }

  final reinforced = distributedSkills
      .where(emphasis.reinforce.contains)
      .toList(growable: false);
  final donors = distributedSkills
      .where((skill) => !emphasis.reinforce.contains(skill))
      .toList(growable: false);
  if (reinforced.isNotEmpty && donors.isNotEmpty) {
    final spreadRoom = (kMaxDistributedSpread * units).floor();
    final perDonor = [
      // Keep every donor above the floor...
      for (final skill in donors) distributed[skill]! - minDistributedEach,
    ].reduce((a, b) => a < b ? a : b);
    final perReceiver = [
      // ...every receiver below the ceiling...
      for (final skill in reinforced) maxDistributedEach - distributed[skill]!,
    ].reduce((a, b) => a < b ? a : b);
    // ...and the whole trio inside the spread bound.
    final moved = [
      perDonor,
      (perReceiver * reinforced.length) ~/ donors.length,
      spreadRoom ~/ 2,
      1 + units ~/ 40,
    ].reduce((a, b) => a < b ? a : b).clamp(0, units);
    final total = moved * donors.length;
    final share = total ~/ reinforced.length;
    if (share > 0) {
      for (final skill in donors) {
        distributed[skill] = distributed[skill]! - moved;
      }
      for (final skill in reinforced) {
        distributed[skill] = distributed[skill]! + share;
      }
      // Any unit lost to integer division goes back to the first donor so the
      // budget still adds up exactly.
      final returned = total - share * reinforced.length;
      distributed[donors.first] = distributed[donors.first]! + returned;
    }
  }

  return _Budget(teaching, speaking, vocabulary, distributed);
}

WeeklyPlan _layout({
  required int weekNumber,
  required String trackId,
  required String lessonId,
  required String lessonTitleFr,
  required int studyDays,
  required int minutesPerDay,
  required _Budget budget,
}) {
  final dayUnits = minutesPerDay ~/ _unit;
  final speakingChunks = List<int>.generate(
    studyDays,
    (index) =>
        budget.speaking ~/ studyDays + (index < budget.speaking % studyDays ? 1 : 0),
  );

  final remaining = <SkillKind, int>{
    ...budget.distributed,
    SkillKind.vocabulary: budget.vocabulary,
  };
  final fillOrder = [...distributedSkills, SkillKind.vocabulary];
  final assignments = <WeeklyAssignmentSpec>[];
  final seen = <SkillKind, int>{};

  String nextId(int day, SkillKind skill) {
    final count = (seen[skill] ?? 0) + 1;
    seen[skill] = count;
    return 'w$weekNumber-d$day-${skill.name}-$count';
  }

  for (var day = 1; day <= studyDays; day++) {
    var capacity = dayUnits;

    if (day == 1) {
      capacity -= budget.teaching;
      assignments.add(
        WeeklyAssignmentSpec(
          id: nextId(day, SkillKind.teaching),
          dayIndex: day,
          skill: SkillKind.teaching,
          minutes: budget.teaching * _unit,
          titleFr: 'Classe de la semaine',
          subtitleFr: lessonTitleFr,
          payload: {
            'mode': 'classTeaching',
            'trackId': trackId,
            'lessonId': lessonId,
          },
        ),
      );
    }

    final speaking = speakingChunks[day - 1];
    if (speaking > 0) {
      capacity -= speaking;
      final live = day == 1;
      assignments.add(
        WeeklyAssignmentSpec(
          id: nextId(day, SkillKind.speaking),
          dayIndex: day,
          skill: SkillKind.speaking,
          minutes: speaking * _unit,
          titleFr: live ? 'Pratique guidée en direct' : 'Prise de parole',
          subtitleFr: live
              ? 'Conversation avec votre enseignante'
              : lessonTitleFr,
          payload: {
            'mode': live ? 'liveClassPractice' : 'speakingTask',
            'trackId': trackId,
            'lessonId': lessonId,
          },
        ),
      );
    }

    // Fill what is left from the remaining pools, rotating the starting skill
    // so the week does not always run in the same order.
    var guard = 0;
    while (capacity > 0 && guard++ < fillOrder.length * 4) {
      SkillKind? chosen;
      for (var offset = 0; offset < fillOrder.length; offset++) {
        final skill =
            fillOrder[(weekNumber + day + offset) % fillOrder.length];
        if ((remaining[skill] ?? 0) > 0) {
          chosen = skill;
          break;
        }
      }
      if (chosen == null) break;
      final take = capacity < remaining[chosen]! ? capacity : remaining[chosen]!;
      remaining[chosen] = remaining[chosen]! - take;
      capacity -= take;
      assignments.add(
        _otherBlock(
          id: nextId(day, chosen),
          day: day,
          skill: chosen,
          minutes: take * _unit,
          trackId: trackId,
          lessonId: lessonId,
          lessonTitleFr: lessonTitleFr,
          occurrence: seen[chosen]!,
        ),
      );
    }
  }

  return WeeklyPlan(
    weekNumber: weekNumber,
    trackId: trackId,
    lessonId: lessonId,
    lessonTitleFr: lessonTitleFr,
    studyDays: studyDays,
    minutesPerDay: minutesPerDay,
    assignments: List.unmodifiable(assignments),
  );
}

WeeklyAssignmentSpec _otherBlock({
  required String id,
  required int day,
  required SkillKind skill,
  required int minutes,
  required String trackId,
  required String lessonId,
  required String lessonTitleFr,
  required int occurrence,
}) {
  final (title, subtitle, mode) = switch (skill) {
    SkillKind.listening => (
      'Écoute',
      'Compréhension orale · $lessonTitleFr',
      'listeningWorkshop',
    ),
    SkillKind.reading => (
      'Lecture',
      'Compréhension de l’écrit · $lessonTitleFr',
      'readingWorkshop',
    ),
    SkillKind.writing => occurrence <= 1
        ? ('Rédaction', 'Premier jet · $lessonTitleFr', 'writingDraft')
        : (
            'Révision écrite',
            'Reprendre la rétroaction · $lessonTitleFr',
            'writingRevision',
          ),
    SkillKind.vocabulary => (
      'Vocabulaire',
      'Révision espacée',
      'vocabularyReview',
    ),
    SkillKind.speaking || SkillKind.teaching => throw StateError(
      'Speaking and teaching are placed before the fill pass.',
    ),
  };
  return WeeklyAssignmentSpec(
    id: id,
    dayIndex: day,
    skill: skill,
    minutes: minutes,
    titleFr: title,
    subtitleFr: subtitle,
    payload: {'mode': mode, 'trackId': trackId, 'lessonId': lessonId},
  );
}
