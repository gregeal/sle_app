/// Measures how long an activity really lasted. Pure Dart.
library;

/// Accumulates foreground time between interactions.
///
/// Time only counts while the meter is running, and a gap between two
/// interactions counts for at most [idleCap]: a screen left open on a desk
/// does not become an hour of study.
class ActivityMeter {
  ActivityMeter({
    DateTime Function()? now,
    this.idleCap = const Duration(minutes: 5),
    this.maximum = const Duration(minutes: 90),
  }) : _now = now ?? DateTime.now {
    startedAt = _now();
  }

  final DateTime Function() _now;
  final Duration idleCap;
  final Duration maximum;
  late final DateTime startedAt;

  DateTime? _mark;
  var _total = Duration.zero;

  bool get isRunning => _mark != null;

  void resume() => _mark ??= _now();

  /// Records an interaction: everything since the previous one counts, up to
  /// [idleCap].
  void touch() {
    if (_mark == null) return;
    _total += _sinceMark();
    _mark = _now();
  }

  void pause() {
    if (_mark == null) return;
    _total += _sinceMark();
    _mark = null;
  }

  int get seconds {
    final total = _total + (_mark == null ? Duration.zero : _sinceMark());
    return (total > maximum ? maximum : total).inSeconds;
  }

  Duration _sinceMark() {
    final gap = _now().difference(_mark!);
    if (gap.isNegative) return Duration.zero;
    return gap > idleCap ? idleCap : gap;
  }
}
