import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/database.dart';
import '../../data/db/habit_daos.dart';
import '../../domain/habit/activity_meter.dart';
import '../../providers.dart';
import 'habit_providers.dart';

/// Tracks which study screen is in front and how long it is really used.
///
/// Only the top-most activity accumulates time, so a screen that opens
/// another tracked screen is not counted twice. Any touch anywhere marks the
/// learner as present; the app going to the background stops the clock.
class ActivityTracker with WidgetsBindingObserver {
  ActivityTracker({DateTime Function()? now}) : _now = now ?? DateTime.now {
    WidgetsBinding.instance.addObserver(this);
    GestureBinding.instance.pointerRouter.addGlobalRoute(_onPointer);
  }

  final DateTime Function() _now;
  final _stack = <ActivityMeter>[];
  var _backgrounded = false;

  ActivityMeter begin() {
    if (_stack.isNotEmpty) _stack.last.pause();
    final meter = ActivityMeter(now: _now);
    if (!_backgrounded) meter.resume();
    _stack.add(meter);
    return meter;
  }

  void end(ActivityMeter meter) {
    meter.pause();
    final wasTop = _stack.isNotEmpty && identical(_stack.last, meter);
    _stack.remove(meter);
    if (wasTop && !_backgrounded && _stack.isNotEmpty) _stack.last.resume();
  }

  void _onPointer(PointerEvent event) {
    if (event is PointerDownEvent && _stack.isNotEmpty) _stack.last.touch();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _backgrounded = false;
      if (_stack.isNotEmpty) _stack.last.resume();
    } else {
      _backgrounded = true;
      if (_stack.isNotEmpty) _stack.last.pause();
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    GestureBinding.instance.pointerRouter.removeGlobalRoute(_onPointer);
  }
}

final activityTrackerProvider = Provider<ActivityTracker>((ref) {
  final tracker = ActivityTracker();
  ref.onDispose(tracker.dispose);
  return tracker;
});

/// Makes a study screen report the time spent on it. Every activity is
/// logged, whether or not it was part of the day's plan, so the streak and
/// the totals reflect what the learner actually did.
mixin ActivityTracking<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  /// Where the time was spent, e.g. `vocab` or `realtime`.
  String get activityKind;

  /// The [SkillKind] name this screen trains, if it trains exactly one.
  String? get activitySkill;

  late final ActivityTracker _activityTracker;
  late final AppDatabase _activityDatabase;
  late final ProviderContainer _activityContainer;
  late final ActivityMeter _activityMeter;

  @override
  void initState() {
    super.initState();
    _activityTracker = ref.read(activityTrackerProvider);
    _activityDatabase = ref.read(appDatabaseProvider);
    _activityContainer = ProviderScope.containerOf(context, listen: false);
    _activityMeter = _activityTracker.begin();
  }

  @override
  void dispose() {
    _activityTracker.end(_activityMeter);
    // Read before the element goes away: the getters may depend on `widget`.
    unawaited(
      _recordActivity(
        startedAt: _activityMeter.startedAt,
        seconds: _activityMeter.seconds,
        kind: activityKind,
        skill: activitySkill,
      ),
    );
    super.dispose();
  }

  Future<void> _recordActivity({
    required DateTime startedAt,
    required int seconds,
    required String kind,
    required String? skill,
  }) async {
    if (seconds < kMinimumLoggedSeconds) return;
    try {
      await _activityDatabase.logActivity(
        startedAt: startedAt,
        seconds: seconds,
        kind: kind,
        skill: skill,
      );
      refreshHabit(_activityContainer);
      await _activityContainer.read(reminderSyncProvider)();
    } on Object {
      // Measuring time must never break leaving a screen, including when
      // the database is already closing.
    }
  }
}
