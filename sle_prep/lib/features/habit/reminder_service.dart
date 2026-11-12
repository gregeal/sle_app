import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../domain/habit/reminder_plan.dart';

/// Schedules the study reminders decided by [planReminders].
abstract class ReminderService {
  /// Whether this platform can remind the learner at all.
  bool get supported;

  /// Asks for permission to show notifications. False when refused.
  Future<bool> requestPermission();

  /// Replaces every scheduled reminder with [specs].
  Future<void> apply(List<ReminderSpec> specs, {required int dailyMinutes});
}

class NoopReminderService implements ReminderService {
  const NoopReminderService();

  @override
  bool get supported => false;

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<void> apply(
    List<ReminderSpec> specs, {
    required int dailyMinutes,
  }) async {}
}

/// Android local notifications. Reminders are inexact on purpose: a study
/// nudge a few minutes late is fine and needs no exact-alarm permission.
class LocalNotificationReminderService implements ReminderService {
  final _plugin = FlutterLocalNotificationsPlugin();
  Future<bool>? _ready;

  @override
  bool get supported => true;

  Future<bool> _initialize() => _ready ??= () async {
    try {
      return await _plugin.initialize(
            settings: const InitializationSettings(
              android: AndroidInitializationSettings('ic_stat_sle'),
            ),
          ) ??
          false;
    } on Object {
      return false;
    }
  }();

  @override
  Future<bool> requestPermission() async {
    if (!await _initialize()) return false;
    try {
      return await _plugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >()
              ?.requestNotificationsPermission() ??
          false;
    } on Object {
      return false;
    }
  }

  @override
  Future<void> apply(
    List<ReminderSpec> specs, {
    required int dailyMinutes,
  }) async {
    if (!await _initialize()) return;
    // Each call is guarded on its own: one reminder that cannot be scheduled
    // must not cost the learner all the others. The next start tries again.
    for (final id in allReminderIds) {
      try {
        await _plugin.cancel(id: id);
      } on Object {
        continue;
      }
    }
    for (final spec in specs) {
      try {
        await _plugin.zonedSchedule(
          id: spec.id,
          title: reminderTitle(spec),
          body: reminderBody(spec, dailyMinutes),
          // The instant is absolute, so no time-zone database is needed. It
          // is recomputed from local wall-clock time on every app start,
          // which also absorbs daylight-saving changes.
          scheduledDate: tz.TZDateTime.from(spec.firstFire, tz.UTC),
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              'study_reminders',
              'Rappels d’étude',
              channelDescription:
                  'Un rappel les jours prévus, jamais les jours de repos.',
              importance: Importance.defaultImportance,
              priority: Priority.defaultPriority,
            ),
          ),
        );
      } on Object {
        continue;
      }
    }
  }
}

ReminderService defaultReminderService() =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.android
    ? LocalNotificationReminderService()
    : const NoopReminderService();
