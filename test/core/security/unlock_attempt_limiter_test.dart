import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:keyva/core/constants/database_constants.dart';
import 'package:keyva/core/constants/security_constants.dart';
import 'package:keyva/core/database/hive_database.dart';
import 'package:keyva/core/security/unlock_attempt_limiter.dart';

void main() {
  late Directory tempDir;
  HiveDatabase? database;
  late DateTime now;
  late UnlockAttemptLimiter limiter;

  const userA = 'user-a';
  const userB = 'user-b';

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('keyva_attempts_');
    database = await HiveDatabase.initialize(testDatabasePath: tempDir.path);
    now = DateTime.utc(2026, 8, 23, 12);
    limiter = UnlockAttemptLimiter(database: database!, clock: () => now);
  });

  tearDown(() async {
    await database?.close();
    database = null;
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('first and second PIN failures reduce remaining attempts', () async {
    expect(
      await limiter.remainingAttempts(UnlockAttemptMethod.pin, userA),
      SecurityConstants.pinMaxFailedAttempts,
    );

    expect(await limiter.recordFailure(UnlockAttemptMethod.pin, userA), isFalse);
    expect(await limiter.isLockedOut(UnlockAttemptMethod.pin, userA), isFalse);
    expect(await limiter.remainingAttempts(UnlockAttemptMethod.pin, userA), 2);

    expect(await limiter.recordFailure(UnlockAttemptMethod.pin, userA), isFalse);
    expect(await limiter.remainingAttempts(UnlockAttemptMethod.pin, userA), 1);
  });

  test('third PIN failure locks and blocks further attempts', () async {
    await limiter.recordFailure(UnlockAttemptMethod.pin, userA);
    await limiter.recordFailure(UnlockAttemptMethod.pin, userA);
    expect(await limiter.recordFailure(UnlockAttemptMethod.pin, userA), isTrue);

    expect(await limiter.isLockedOut(UnlockAttemptMethod.pin, userA), isTrue);
    expect(await limiter.remainingAttempts(UnlockAttemptMethod.pin, userA), 0);
    expect(await limiter.recordFailure(UnlockAttemptMethod.pin, userA), isTrue);
    expect(
      database!.appSettings.get(HiveSettingsKeys.pinFailedAttempts(userA)),
      SecurityConstants.pinMaxFailedAttempts,
    );
  });

  test('PIN lockout expires after 15 minutes', () async {
    await limiter.recordFailure(UnlockAttemptMethod.pin, userA);
    await limiter.recordFailure(UnlockAttemptMethod.pin, userA);
    await limiter.recordFailure(UnlockAttemptMethod.pin, userA);
    expect(await limiter.isLockedOut(UnlockAttemptMethod.pin, userA), isTrue);

    now = now.add(const Duration(minutes: 14, seconds: 59));
    expect(await limiter.isLockedOut(UnlockAttemptMethod.pin, userA), isTrue);

    now = now.add(const Duration(seconds: 1));
    expect(await limiter.isLockedOut(UnlockAttemptMethod.pin, userA), isFalse);
    expect(
      await limiter.remainingAttempts(UnlockAttemptMethod.pin, userA),
      SecurityConstants.pinMaxFailedAttempts,
    );
  });

  test('reset clears PIN lockout immediately', () async {
    await limiter.recordFailure(UnlockAttemptMethod.pin, userA);
    await limiter.recordFailure(UnlockAttemptMethod.pin, userA);
    await limiter.recordFailure(UnlockAttemptMethod.pin, userA);
    await limiter.reset(UnlockAttemptMethod.pin, userA);

    expect(await limiter.isLockedOut(UnlockAttemptMethod.pin, userA), isFalse);
    expect(
      await limiter.remainingAttempts(UnlockAttemptMethod.pin, userA),
      SecurityConstants.pinMaxFailedAttempts,
    );
  });

  test('PIN lockout without a timestamp stays locked until reset', () async {
    await database!.appSettings.put(
      HiveSettingsKeys.pinFailedAttempts(userA),
      SecurityConstants.pinMaxFailedAttempts,
    );

    expect(await limiter.isLockedOut(UnlockAttemptMethod.pin, userA), isTrue);
    now = now.add(SecurityConstants.unlockAttemptLockout);
    expect(await limiter.isLockedOut(UnlockAttemptMethod.pin, userA), isTrue);

    await limiter.reset(UnlockAttemptMethod.pin, userA);
    expect(await limiter.isLockedOut(UnlockAttemptMethod.pin, userA), isFalse);
  });

  test('PIN state is persisted across limiter instances', () async {
    await limiter.recordFailure(UnlockAttemptMethod.pin, userA);
    await limiter.recordFailure(UnlockAttemptMethod.pin, userA);
    await limiter.recordFailure(UnlockAttemptMethod.pin, userA);

    final restored = UnlockAttemptLimiter(
      database: database!,
      clock: () => now,
    );
    expect(await restored.isLockedOut(UnlockAttemptMethod.pin, userA), isTrue);
  });

  test('PIN lockout is scoped per user', () async {
    await limiter.recordFailure(UnlockAttemptMethod.pin, userA);
    await limiter.recordFailure(UnlockAttemptMethod.pin, userA);
    await limiter.recordFailure(UnlockAttemptMethod.pin, userA);

    expect(await limiter.isLockedOut(UnlockAttemptMethod.pin, userA), isTrue);
    expect(await limiter.isLockedOut(UnlockAttemptMethod.pin, userB), isFalse);
    expect(
      await limiter.remainingAttempts(UnlockAttemptMethod.pin, userB),
      SecurityConstants.pinMaxFailedAttempts,
    );
  });

  test('biometric failures lock independently of PIN', () async {
    await limiter.recordFailure(UnlockAttemptMethod.biometric, userA);
    await limiter.recordFailure(UnlockAttemptMethod.biometric, userA);
    expect(
      await limiter.recordFailure(UnlockAttemptMethod.biometric, userA),
      isTrue,
    );

    expect(
      await limiter.isLockedOut(UnlockAttemptMethod.biometric, userA),
      isTrue,
    );
    expect(await limiter.isLockedOut(UnlockAttemptMethod.pin, userA), isFalse);

    now = now.add(SecurityConstants.unlockAttemptLockout);
    expect(
      await limiter.isLockedOut(UnlockAttemptMethod.biometric, userA),
      isFalse,
    );
  });
}
