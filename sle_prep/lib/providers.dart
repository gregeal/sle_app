import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/db/daos.dart';
import 'data/db/database.dart';
import 'data/seed/seed_loader.dart';
import 'domain/mock/mock_scoring.dart';
import 'domain/session/session_composer.dart';
import 'domain/llm/llm_client.dart';
import 'domain/llm/llm_config.dart';
import 'domain/speech/speech_services.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase(driftDatabase(name: 'sle_prep'));
  ref.onDispose(database.close);
  return database;
});

final secureStorageProvider = Provider<FlutterSecureStorage>(
  (ref) => const FlutterSecureStorage(),
);

final llmConfigProvider = FutureProvider<LlmConfig>((ref) async {
  final database = ref.watch(appDatabaseProvider);
  final provider = providerFromStorage(
    await database.getSetting('llmProvider'),
  );
  final baseUrl =
      await database.getSetting('llmBaseUrl') ?? defaultBaseUrl(provider);
  final model = await database.getSetting('llmModel') ?? '';
  final realtimeModel =
      await database.getSetting('realtimeModel') ?? 'gpt-realtime';
  final realtimeVoice = await database.getSetting('realtimeVoice') ?? 'marin';
  final hasApiKey =
      (await ref.watch(secureStorageProvider).read(key: 'llmApiKey'))
          ?.isNotEmpty ??
      false;
  return LlmConfig(
    provider: provider,
    baseUrl: baseUrl,
    model: model,
    hasApiKey: hasApiKey,
    realtimeModel: realtimeModel,
    realtimeVoice: realtimeVoice,
  );
});

/// Ready-to-use client for the stored provider/key. Throws [LlmException]
/// (surfaced as an AsyncError) when a required API key is missing.
final llmClientProvider = FutureProvider<LlmClient>((ref) async {
  final config = await ref.watch(llmConfigProvider.future);
  final apiKey = await ref.watch(secureStorageProvider).read(key: 'llmApiKey');
  return clientFor(config, apiKey: apiKey);
});

final speechServiceProvider = Provider<SpeechService>(
  (ref) => DeviceSpeechService(),
);

final ttsServiceProvider = Provider<TtsService>((ref) => DeviceTtsService());

final seedImportProvider = FutureProvider<void>((ref) async {
  await importSeedFromAssets(ref.watch(appDatabaseProvider));
});

final dueCardsProvider = FutureProvider.autoDispose<List<DueCard>>((ref) async {
  return ref.watch(appDatabaseProvider).dueCards(DateTime.now(), limit: 20);
});

/// Overridable clock for tests and for composing a stable plan throughout a day.
final studyDayProvider = Provider<DateTime>((ref) => DateTime.now());

class ActiveWeek {
  const ActiveWeek({required this.number, required this.week});

  final int number;
  final CurriculumWeek week;
}

class TodayPlan {
  const TodayPlan({
    required this.day,
    required this.activeWeek,
    required this.blocks,
  });

  final DateTime day;
  final ActiveWeek activeWeek;
  final List<SessionBlock> blocks;
}

class ProgressSnapshot {
  const ProgressSnapshot({
    required this.streak,
    required this.dueCards,
    required this.studiedCards,
    required this.topicAccuracy,
    required this.totalMinutes,
    required this.latestMocks,
    required this.nextCheckpoint,
  });

  final int streak;
  final int dueCards;
  final int studiedCards;
  final Map<String, double> topicAccuracy;
  final int totalMinutes;
  final Map<String, MockResult> latestMocks;
  final DateTime nextCheckpoint;
}

final activeWeekProvider = FutureProvider<ActiveWeek>((ref) async {
  final database = ref.watch(appDatabaseProvider);
  final day = _dateOnly(ref.watch(studyDayProvider));
  final savedStart = await database.getSetting('planStartDate');
  final start = savedStart == null ? day : DateTime.tryParse(savedStart) ?? day;
  if (savedStart == null) {
    await database.setSetting('planStartDate', _dateKey(day));
  }

  final elapsedDays = day.difference(_dateOnly(start)).inDays;
  final weekNumber = (elapsedDays ~/ 7 + 1).clamp(1, 26).toInt();
  final week = await database.weekByNumber(weekNumber);
  if (week == null) {
    throw StateError('Le programme de la semaine $weekNumber est introuvable.');
  }
  return ActiveWeek(number: weekNumber, week: week);
});

final todayPlanProvider = FutureProvider<TodayPlan>((ref) async {
  final database = ref.watch(appDatabaseProvider);
  final day = _dateOnly(ref.watch(studyDayProvider));
  final activeWeek = await ref.watch(activeWeekProvider.future);
  final dueCards = await database.dueCardCount(day);
  final accuracy = await database.topicAccuracy();
  final resources = activeWeek.week.resourceSlotsList
      .map(
        (slot) => SessionResource(
          label: slot['label'] as String,
          url: slot['url'] as String,
        ),
      )
      .toList(growable: false);

  return TodayPlan(
    day: day,
    activeWeek: activeWeek,
    blocks: composeSession(
      dueCardCount: dueCards,
      grammarTopics: activeWeek.week.grammarTopicsList,
      topicAccuracy: accuracy,
      resources: resources,
      targetMinutes: 75,
    ),
  );
});

final todaySessionLogProvider = FutureProvider<SessionLog?>((ref) {
  final database = ref.watch(appDatabaseProvider);
  return database.sessionLogFor(ref.watch(studyDayProvider));
});

final progressSnapshotProvider = FutureProvider<ProgressSnapshot>((ref) async {
  final database = ref.watch(appDatabaseProvider);
  final day = ref.watch(studyDayProvider);
  final values = await Future.wait<Object>([
    database.currentStreak(day),
    database.dueCardCount(day),
    database.studiedCardCount(),
    database.topicAccuracy(),
    database.totalActiveMinutes(),
    database.latestMockPerSkill(),
  ]);
  final savedStart = await database.getSetting('planStartDate');
  final planStart = savedStart == null
      ? day
      : DateTime.tryParse(savedStart) ?? day;
  return ProgressSnapshot(
    streak: values[0] as int,
    dueCards: values[1] as int,
    studiedCards: values[2] as int,
    topicAccuracy: values[3] as Map<String, double>,
    totalMinutes: values[4] as int,
    latestMocks: values[5] as Map<String, MockResult>,
    nextCheckpoint: nextCheckpoint(planStart, day),
  );
});

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

String _dateKey(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-'
    '${value.month.toString().padLeft(2, '0')}-'
    '${value.day.toString().padLeft(2, '0')}';
