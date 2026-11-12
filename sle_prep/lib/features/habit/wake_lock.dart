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

/// Holds the wake lock for as long as a speaking screen is open.
mixin KeepsScreenAwake<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  late final ScreenWakeLock _screenWakeLock;

  @override
  void initState() {
    super.initState();
    _screenWakeLock = ref.read(wakeLockProvider);
    unawaited(_screenWakeLock.enable());
  }

  @override
  void dispose() {
    unawaited(_screenWakeLock.disable());
    super.dispose();
  }
}
