import 'package:keyva/core/constants/database_constants.dart';
import 'package:keyva/core/constants/security_constants.dart';
import 'package:keyva/core/database/hive_database.dart';

enum UnlockAttemptMethod { pin, biometric, masterPassword }

class UnlockAttemptLimiter {
  UnlockAttemptLimiter({
    required HiveDatabase database,
    DateTime Function()? clock,
  }) : _database = database,
       _clock = clock ?? DateTime.now;

  final HiveDatabase _database;
  final DateTime Function() _clock;

  Future<bool> isLockedOut(UnlockAttemptMethod method, String userId) async {
    final attempts = _failedAttempts(method, userId);
    if (attempts < _maxAttempts(method)) {
      return false;
    }
    final startedAt = _lockoutStartedAt(method, userId);
    if (startedAt == null) {
      return true;
    }
    if (_clock().difference(startedAt) >= _lockoutDuration(method)) {
      await reset(method, userId);
      return false;
    }
    return true;
  }

  Future<int> remainingAttempts(
    UnlockAttemptMethod method,
    String userId,
  ) async {
    if (await isLockedOut(method, userId)) {
      return 0;
    }
    final remaining = _maxAttempts(method) - _failedAttempts(method, userId);
    return remaining < 0 ? 0 : remaining;
  }

  Future<bool> recordFailure(UnlockAttemptMethod method, String userId) async {
    if (await isLockedOut(method, userId)) {
      return true;
    }
    final next = _failedAttempts(method, userId) + 1;
    await _putInt(_attemptsKey(method, userId), next);
    if (next >= _maxAttempts(method)) {
      await _putInt(
        _lockoutKey(method, userId),
        _clock().millisecondsSinceEpoch,
      );
      return true;
    }
    return false;
  }

  Future<Duration> remainingLockout(
    UnlockAttemptMethod method,
    String userId,
  ) async {
    if (!await isLockedOut(method, userId)) {
      return Duration.zero;
    }
    final startedAt = _lockoutStartedAt(method, userId);
    if (startedAt == null) {
      return _lockoutDuration(method);
    }
    final remaining =
        _lockoutDuration(method) - _clock().difference(startedAt);
    if (remaining.isNegative) {
      return Duration.zero;
    }
    return remaining;
  }

  Future<void> reset(UnlockAttemptMethod method, String userId) async {
    try {
      await _database.appSettings.delete(_attemptsKey(method, userId));
      await _database.appSettings.delete(_lockoutKey(method, userId));
    } catch (_) {}
  }

  int _failedAttempts(UnlockAttemptMethod method, String userId) {
    return _readInt(_attemptsKey(method, userId));
  }

  DateTime? _lockoutStartedAt(UnlockAttemptMethod method, String userId) {
    final millis = _readInt(_lockoutKey(method, userId));
    if (millis <= 0) {
      return null;
    }
    return DateTime.fromMillisecondsSinceEpoch(millis);
  }

  int _readInt(String key) {
    try {
      final value = _database.appSettings.get(key);
      if (value is int && value > 0) {
        return value;
      }
    } catch (_) {}
    return 0;
  }

  Future<void> _putInt(String key, int value) async {
    try {
      await _database.appSettings.put(key, value);
    } catch (_) {}
  }

  static Duration _lockoutDuration(UnlockAttemptMethod method) {
    switch (method) {
      case UnlockAttemptMethod.pin:
      case UnlockAttemptMethod.biometric:
        return SecurityConstants.unlockAttemptLockout;
      case UnlockAttemptMethod.masterPassword:
        return SecurityConstants.masterPasswordLockout;
    }
  }

  static int _maxAttempts(UnlockAttemptMethod method) {
    switch (method) {
      case UnlockAttemptMethod.pin:
        return SecurityConstants.pinMaxFailedAttempts;
      case UnlockAttemptMethod.biometric:
        return SecurityConstants.biometricMaxFailedAttempts;
      case UnlockAttemptMethod.masterPassword:
        return SecurityConstants.masterPasswordMaxFailedAttempts;
    }
  }

  static String _attemptsKey(UnlockAttemptMethod method, String userId) {
    switch (method) {
      case UnlockAttemptMethod.pin:
        return HiveSettingsKeys.pinFailedAttempts(userId);
      case UnlockAttemptMethod.biometric:
        return HiveSettingsKeys.biometricFailedAttempts(userId);
      case UnlockAttemptMethod.masterPassword:
        return HiveSettingsKeys.masterPasswordFailedAttempts(userId);
    }
  }

  static String _lockoutKey(UnlockAttemptMethod method, String userId) {
    switch (method) {
      case UnlockAttemptMethod.pin:
        return HiveSettingsKeys.pinLockoutStartedAt(userId);
      case UnlockAttemptMethod.biometric:
        return HiveSettingsKeys.biometricLockoutStartedAt(userId);
      case UnlockAttemptMethod.masterPassword:
        return HiveSettingsKeys.masterPasswordLockoutStartedAt(userId);
    }
  }
}
