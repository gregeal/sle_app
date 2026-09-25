import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Prevent a dictionary route from hiding an active microphone or paid voice
/// connection. Guards are evaluated at menu creation AND immediately on action.
class WordHelpGuard {
  final _checks = <bool Function()>{};
  bool get blocked => _checks.any((check) => check());
  VoidCallback register(bool Function() check) {
    _checks.add(check);
    return () => _checks.remove(check);
  }
}

final wordHelpGuardProvider = Provider((ref) => WordHelpGuard());
