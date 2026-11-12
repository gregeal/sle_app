import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/habit_daos.dart';
import '../../domain/habit/habit_settings.dart';
import '../../domain/habit/slot_analysis.dart';
import '../../providers.dart';
import 'habit_providers.dart';

enum DayRole { study, groupClass, rest }

const weekdayNames = [
  'Lundi',
  'Mardi',
  'Mercredi',
  'Jeudi',
  'Vendredi',
  'Samedi',
  'Dimanche',
];

/// Where the learner decides which days to study, for how long, and when to
/// be reminded. The next week opened is composed from this rhythm.
class RhythmScreen extends ConsumerStatefulWidget {
  const RhythmScreen({super.key});

  @override
  ConsumerState<RhythmScreen> createState() => _RhythmState();
}

class _RhythmState extends ConsumerState<RhythmScreen> {
  final _roles = <int, DayRole>{};
  var _dailyMinutes = kDefaultDailyMinutes;
  var _reminders = true;
  var _reminderMinutes = const HabitSettings().reminderMinutes;
  int? _workStart;
  int? _workEnd;
  var _stats = const <SlotStat>[];
  var _ready = false;
  var _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final db = ref.read(appDatabaseProvider);
      final settings = await db.habitSettings();
      final stats = await db.slotStats(ref.read(studyDayProvider), settings);
      if (!mounted) return;
      setState(() {
        for (var day = 1; day <= 7; day++) {
          _roles[day] = settings.classDays.contains(day)
              ? DayRole.groupClass
              : settings.studyDays.contains(day)
              ? DayRole.study
              : DayRole.rest;
        }
        _dailyMinutes = settings.dailyMinutes;
        // Being reminded is the point of this screen, so it is on by default
        // the first time and then follows the saved choice.
        _reminders = settings.configured ? settings.remindersEnabled : true;
        _reminderMinutes = settings.reminderMinutes;
        _workStart = settings.workStartMinutes;
        _workEnd = settings.workEndMinutes;
        _stats = stats;
        _ready = true;
      });
    } on Object {
      if (mounted) {
        setState(() {
          _error = 'Impossible de charger votre rythme. Réessayez.';
          _ready = true;
        });
      }
    }
  }

  List<int> _daysWith(DayRole role) => [
    for (var day = 1; day <= 7; day++)
      if (_roles[day] == role) day,
  ];

  HabitSettings _draft({required bool reminders}) => HabitSettings(
    configured: true,
    remindersEnabled: reminders,
    reminderMinutes: _reminderMinutes,
    studyDays: _daysWith(DayRole.study),
    classDays: _daysWith(DayRole.groupClass),
    dailyMinutes: _dailyMinutes,
    workStartMinutes: _workStart,
    workEndMinutes: _workEnd,
  );

  Future<int?> _pickTime(int? current, int fallback) async {
    final value = current ?? fallback;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: value ~/ 60, minute: value % 60),
    );
    return picked == null ? null : picked.hour * 60 + picked.minute;
  }

  Future<void> _save() async {
    if (_saving) return;
    final problem = _draft(reminders: _reminders).problem;
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      var reminders = _reminders;
      String? notice;
      if (reminders) {
        final service = ref.read(reminderServiceProvider);
        if (!service.supported) {
          reminders = false;
          notice =
              'Rythme enregistré. Les rappels ne sont pas offerts sur cette '
              'plateforme : utilisez une alarme de votre appareil.';
        } else if (!await service.requestPermission()) {
          reminders = false;
          notice =
              'Rythme enregistré, mais les notifications sont refusées. '
              'Autorisez-les dans les réglages Android, puis réactivez le '
              'rappel ici.';
        }
      }
      await ref
          .read(appDatabaseProvider)
          .saveHabitSettings(_draft(reminders: reminders));
      await ref.read(reminderSyncProvider)();
      if (!mounted) return;
      refreshHabit(ProviderScope.containerOf(context, listen: false));
      if (notice == null) {
        Navigator.pop(context, true);
      } else {
        setState(() {
          _reminders = false;
          _error = notice;
        });
      }
    } on ArgumentError catch (error) {
      if (mounted) setState(() => _error = '${error.message}');
    } on Object {
      if (mounted) {
        setState(() => _error = 'Enregistrement impossible. Réessayez.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final study = _daysWith(DayRole.study).length;
    final classes = _daysWith(DayRole.groupClass).length;
    final suggestions = _workStart != null && _workEnd != null
        ? suggestSlots(workStartMinutes: _workStart!, workEndMinutes: _workEnd!)
        : const <SlotSuggestion>[];
    final best = bestSlot(_stats);
    return Scaffold(
      appBar: AppBar(title: const Text('Mon rythme')),
      body: !_ready
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                const Text(
                  'Un rythme que vous tenez vaut mieux qu’un rythme '
                  'ambitieux. Vous pourrez l’ajuster chaque semaine.',
                ),
                const SizedBox(height: 20),
                Text('MES JOURS', style: theme.textTheme.labelLarge),
                const SizedBox(height: 4),
                for (var day = 1; day <= 7; day++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        SizedBox(width: 84, child: Text(weekdayNames[day - 1])),
                        Expanded(
                          child: SegmentedButton<DayRole>(
                            key: Key('rhythm-day-$day'),
                            showSelectedIcon: false,
                            style: const ButtonStyle(
                              visualDensity: VisualDensity.compact,
                            ),
                            segments: const [
                              ButtonSegment(
                                value: DayRole.study,
                                label: Text('Étude'),
                              ),
                              ButtonSegment(
                                value: DayRole.groupClass,
                                label: Text('Cours'),
                              ),
                              ButtonSegment(
                                value: DayRole.rest,
                                label: Text('Repos'),
                              ),
                            ],
                            selected: {_roles[day] ?? DayRole.rest},
                            onSelectionChanged: (value) =>
                                setState(() => _roles[day] = value.single),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 6),
                Text(
                  '« Cours » : votre cours en groupe. Ces jours-là, '
                  'l’application ne demande qu’un échauffement de 10 minutes '
                  'et une note de 5 minutes. Au moins un jour de repos '
                  'complet est obligatoire.',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 20),
                Text('DURÉE D’UNE SÉANCE', style: theme.textTheme.labelLarge),
                const SizedBox(height: 6),
                SegmentedButton<int>(
                  key: const Key('rhythm-minutes'),
                  showSelectedIcon: false,
                  segments: [
                    for (final minutes in kDailyMinuteChoices)
                      ButtonSegment(
                        value: minutes,
                        label: Text('$minutes min'),
                      ),
                  ],
                  selected: {_dailyMinutes},
                  onSelectionChanged: (value) =>
                      setState(() => _dailyMinutes = value.single),
                ),
                const SizedBox(height: 6),
                Text(
                  'Par semaine : ${study * _dailyMinutes + classes * 15} '
                  'minutes dans l’application'
                  '${classes > 0 ? ', en plus de vos cours' : ''}. '
                  'Cinq minutes suffisent toujours pour que la journée compte.',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 20),
                Text(
                  'MA JOURNÉE DE TRAVAIL · facultatif',
                  style: theme.textTheme.labelLarge,
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Je commence à'),
                  trailing: Text(
                    _workStart == null ? 'Choisir' : formatClock(_workStart!),
                  ),
                  onTap: () async {
                    final picked = await _pickTime(_workStart, 8 * 60 + 30);
                    if (picked != null) setState(() => _workStart = picked);
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Je termine à'),
                  trailing: Text(
                    _workEnd == null ? 'Choisir' : formatClock(_workEnd!),
                  ),
                  onTap: () async {
                    final picked = await _pickTime(_workEnd, 16 * 60 + 30);
                    if (picked != null) setState(() => _workEnd = picked);
                  },
                ),
                if (suggestions.isNotEmpty) ...[
                  Text(
                    'Créneaux possibles autour du travail. Parler demande un '
                    'endroit tranquille; écouter peut se faire en déplacement.',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final suggestion in suggestions)
                        ActionChip(
                          label: Text(
                            '${suggestion.label} · '
                            '${formatClock(suggestion.minutes)}',
                          ),
                          onPressed: () => setState(
                            () => _reminderMinutes = suggestion.minutes,
                          ),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 20),
                Text('MON RAPPEL', style: theme.textTheme.labelLarge),
                SwitchListTile(
                  key: const Key('rhythm-reminders'),
                  contentPadding: EdgeInsets.zero,
                  value: _reminders,
                  title: const Text('Me rappeler les jours prévus'),
                  onChanged: (value) => setState(() => _reminders = value),
                ),
                ListTile(
                  key: const Key('rhythm-reminder-time'),
                  contentPadding: EdgeInsets.zero,
                  enabled: _reminders,
                  title: const Text('Heure du rappel'),
                  trailing: Text(formatClock(_reminderMinutes)),
                  onTap: () async {
                    final picked = await _pickTime(
                      _reminderMinutes,
                      _reminderMinutes,
                    );
                    if (picked != null) {
                      setState(() => _reminderMinutes = picked);
                    }
                  },
                ),
                Text(
                  'Jamais les jours de repos. Un seul second rappel, trois '
                  'heures plus tard, et jamais après 21 h. Aucun rappel une '
                  'fois vos cinq minutes faites.',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 20),
                Text('MON MEILLEUR CRÉNEAU', style: theme.textTheme.labelLarge),
                const SizedBox(height: 6),
                if (_stats.isEmpty)
                  const Text(
                    'Après quelques séances, vous verrez ici à quelle heure '
                    'vous terminez le plus souvent ce que vous commencez.',
                  )
                else ...[
                  for (final stat in _stats)
                    Text(
                      '${stat.slot.label} : ${stat.keptDays} séance'
                      '${stat.keptDays > 1 ? 's' : ''} terminée'
                      '${stat.keptDays > 1 ? 's' : ''} sur ${stat.days}',
                    ),
                  if (best != null) ...[
                    const SizedBox(height: 8),
                    FilledButton.tonal(
                      onPressed: () => setState(
                        () => _reminderMinutes = best.medianStartMinutes,
                      ),
                      child: Text(
                        'Placer mon rappel à '
                        '${formatClock(best.medianStartMinutes)}',
                      ),
                    ),
                  ],
                ],
                const SizedBox(height: 20),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      _error!,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ),
                FilledButton(
                  key: const Key('rhythm-save'),
                  onPressed: _saving ? null : _save,
                  child: Text(_saving ? 'Enregistrement…' : 'Enregistrer'),
                ),
                const SizedBox(height: 8),
                Text(
                  'Les jours et la durée s’appliquent à la prochaine semaine '
                  'ouverte; la semaine en cours garde son plan.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
    );
  }
}
