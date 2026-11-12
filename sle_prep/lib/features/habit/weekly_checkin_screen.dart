import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/daos.dart';
import '../../data/db/habit_daos.dart';
import '../../domain/habit/habit_settings.dart';
import '../../domain/habit/journey.dart';
import '../../domain/weekly/weekly_report.dart';
import '../../providers.dart';
import 'habit_providers.dart';
import 'rhythm_screen.dart';

enum _Adjustment { keep, lighter, time }

/// A three-minute look back at last week: did the rhythm hold, where did the
/// time go, and is one small change worth making.
class WeeklyCheckinScreen extends ConsumerStatefulWidget {
  const WeeklyCheckinScreen({super.key});

  @override
  ConsumerState<WeeklyCheckinScreen> createState() => _CheckinState();
}

class _CheckinState extends ConsumerState<WeeklyCheckinScreen> {
  HabitSettings? _settings;
  var _days = 0;
  var _keptWeeks = 0;
  var _bySkill = const <String, int>{};
  var _adjustment = _Adjustment.keep;
  var _ready = false;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final db = ref.read(appDatabaseProvider);
    final today = ref.read(studyDayProvider);
    final thisMonday = mondayOf(today);
    final lastMonday = DateTime(
      thisMonday.year,
      thisMonday.month,
      thisMonday.day - 7,
    );
    try {
      final settings = await db.habitSettings();
      final days = await db.activeDaysInWeekOf(lastMonday);
      final bySkill = await db.secondsBySkill(lastMonday, thisMonday);
      final keptWeeks = await db.keptWeeks(today, settings);
      if (!mounted) return;
      setState(() {
        _settings = settings;
        _days = days;
        _bySkill = bySkill;
        _keptWeeks = keptWeeks;
        _ready = true;
      });
    } on Object {
      if (mounted) setState(() => _ready = true);
    }
  }

  Future<void> _finish() async {
    if (_saving) return;
    setState(() => _saving = true);
    final navigator = Navigator.of(context);
    final container = ProviderScope.containerOf(context, listen: false);
    try {
      await ref
          .read(appDatabaseProvider)
          .setSetting(
            'habit:lastCheckin',
            studyDateKey(ref.read(studyDayProvider)),
          );
      refreshHabit(container);
    } on Object {
      // The check-in can simply be offered again.
    }
    if (!mounted) return;
    if (_adjustment == _Adjustment.keep) {
      navigator.pop(true);
    } else {
      await navigator.pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const RhythmScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = _settings ?? const HabitSettings();
    final planned = settings.activeWeekdays.length;
    final kept = _days >= keptDaysNeeded(planned);
    final total = _bySkill.values.fold<int>(0, (sum, s) => sum + s);
    final longest = _bySkill.values.fold<int>(1, (a, b) => a > b ? a : b);
    final journey = journeyFor(keptWeeks: _keptWeeks);
    return Scaffold(
      appBar: AppBar(title: const Text('Bilan de la semaine')),
      body: !_ready
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                Text(
                  kept ? 'Semaine tenue.' : 'Une semaine plus légère.',
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 6),
                Text(
                  kept
                      ? 'Vous êtes venu $_days jour${_days > 1 ? 's' : ''} sur '
                            '$planned prévus. C’est exactement ce qui fait '
                            'progresser : revenir, pas en faire beaucoup.'
                      : 'Vous êtes venu $_days jour${_days > 1 ? 's' : ''} sur '
                            '$planned prévus. Ce n’est pas un échec : c’est '
                            'une information. Voyons ce qui rendrait la '
                            'prochaine semaine plus facile.',
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(journey.title, style: theme.textTheme.titleMedium),
                        const SizedBox(height: 4),
                        Text(journey.detail),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'TEMPS RÉEL · ${total ~/ 60} min',
                  style: theme.textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                if (total == 0)
                  const Text('Aucun temps mesuré la semaine dernière.')
                else
                  for (final entry
                      in _bySkill.entries.toList()
                        ..sort((a, b) => b.value.compareTo(a.value)))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                entry.key == 'other'
                                    ? 'Autre'
                                    : weeklySkillLabel(entry.key),
                              ),
                              Text('${(entry.value / 60).ceil()} min'),
                            ],
                          ),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(value: entry.value / longest),
                        ],
                      ),
                    ),
                const SizedBox(height: 12),
                Text('POUR LA SUITE', style: theme.textTheme.labelLarge),
                RadioGroup<_Adjustment>(
                  groupValue: _adjustment,
                  onChanged: (value) {
                    if (value != null) setState(() => _adjustment = value);
                  },
                  child: const Column(
                    children: [
                      RadioListTile<_Adjustment>(
                        value: _Adjustment.keep,
                        contentPadding: EdgeInsets.zero,
                        title: Text('Je garde ce rythme'),
                      ),
                      RadioListTile<_Adjustment>(
                        value: _Adjustment.lighter,
                        contentPadding: EdgeInsets.zero,
                        title: Text('J’allège : moins de jours ou de minutes'),
                      ),
                      RadioListTile<_Adjustment>(
                        value: _Adjustment.time,
                        contentPadding: EdgeInsets.zero,
                        title: Text('Je change l’heure de mon rappel'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                FilledButton(
                  key: const Key('checkin-done'),
                  onPressed: _saving ? null : _finish,
                  child: Text(
                    _adjustment == _Adjustment.keep
                        ? 'Terminer'
                        : 'Ajuster mon rythme',
                  ),
                ),
              ],
            ),
    );
  }
}
