import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Keeps the display on while the learner is speaking. Without it the screen
/// times out mid-answer, the app is paused, and the microphone is muted.
abstract class ScreenWakeLock {
  Future<void> enable();
  Future<void> disable();
}

class DeviceWakeLock implements ScreenWakeLock {
  const DeviceWakeLock();

  // Staying awake is an enhancement: a platform that cannot do it must not
  // prevent the session from starting or ending.
  @override
  Future<void> enable() async {
    try {
      await WakelockPlus.enable();
    } on Object {
      return;
    }
  }

  @override
  Future<void> disable() async {
    try {
      await WakelockPlus.disable();
    } on Object {
      return;
    }
  }
}

final wakeLockProvider = Provider<ScreenWakeLock>(
  (ref) => const DeviceWakeLock(),
);

/// Shares the single device wake lock between everything that needs it. A
/// dictation box inside a speaking screen must not switch the screen back to
/// sleeping when it stops while the screen around it still wants it awake.
class WakeLockCounter {
  WakeLockCounter(this._device);

  final ScreenWakeLock _device;
  var _holders = 0;

  void _acquire() {
    if (_holders++ == 0) unawaited(_device.enable());
  }

  void _release() {
    if (_holders == 0) return;
    if (--_holders == 0) unawaited(_device.disable());
  }
}

final wakeLockCounterProvider = Provider<WakeLockCounter>(
  (ref) => WakeLockCounter(ref.watch(wakeLockProvider)),
);

/// One holder's claim on the wake lock. Acquiring or releasing twice is
/// harmless, so callers can release from every exit path.
class WakeLockHold {
  WakeLockHold(this._counter);

  final WakeLockCounter _counter;
  var _held = false;

  bool get isHeld => _held;

  void acquire() {
    if (_held) return;
    _held = true;
    _counter._acquire();
  }

  void release() {
    if (!_held) return;
    _held = false;
    _counter._release();
  }
}

/// Holds the wake lock for as long as a speaking screen is open.
mixin KeepsScreenAwake<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  late final WakeLockHold _screenWakeHold;

  @override
  void initState() {
    super.initState();
    _screenWakeHold = WakeLockHold(ref.read(wakeLockCounterProvider))
      ..acquire();
  }

  @override
  void dispose() {
    _screenWakeHold.release();
    super.dispose();
  }
}
