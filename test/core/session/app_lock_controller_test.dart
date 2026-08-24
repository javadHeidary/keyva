import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:keyva/core/exceptions/app_failure.dart';
import 'package:keyva/core/routes/app_routing.dart';
import 'package:keyva/core/security/auto_lock_policy.dart';
import 'package:keyva/core/session/app_lock_controller.dart';
import 'package:keyva/core/session/session_service_impl.dart';

import '../../feature/auth/support/fake_auth_repository.dart';
import '../../feature/auth/support/fake_vault_unlock_service.dart';
import 'support/memory_auto_lock_pause_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SessionServiceImpl session;
  late FakeVaultUnlockService unlock;
  late FakeAuthRepository auth;
  late MemoryAutoLockPauseStore pauseStore;
  late AppLockController lock;
  late DateTime now;
  var navigated = 0;
  void Function()? fireTimer;
  Duration? lastTimerDuration;
  late Uint8List vaultKey;

  setUp(() {
    Get.testMode = true;
    session = SessionServiceImpl();
    vaultKey = Uint8List.fromList(List<int>.filled(32, 7));
    session.setAuthenticated(
      userId: 'user-1',
      username: 'test',
      vaultKey: vaultKey,
    );
    unlock = FakeVaultUnlockService(session: session);
    auth = FakeAuthRepository();
    pauseStore = MemoryAutoLockPauseStore();
    now = DateTime.utc(2026, 8, 19, 12);
    navigated = 0;
    fireTimer = null;
    lastTimerDuration = null;
    lock = AppLockController(
      session: session,
      unlock: unlock,
      auth: auth,
      pauseStore: pauseStore,
      clock: () => now,
      startTimer: (duration, callback) {
        lastTimerDuration = duration;
        fireTimer = callback;
        return _FakeTimer();
      },
      onLocked: () => navigated++,
      observeBinding: false,
    );
  });

  tearDown(() {
    lock.onClose();
    Get.reset();
  });

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  test('starts with the overlay hidden and the session intact', () {
    expect(lock.overlayVisible.value, isFalse);
    expect(session.isAuthenticated, isTrue);
    expect(unlock.lockCount, 0);
  });

  test('inactive shows the overlay without locking', () async {
    lock.handleLifecycle(AppLifecycleState.inactive);
    await settle();

    expect(lock.overlayVisible.value, isTrue);
    expect(unlock.lockCount, 0);
    expect(session.isAuthenticated, isTrue);
    expect(navigated, 0);
  });

  test('immediate timeout locks while backgrounded', () async {
    auth.autoLockTimeout = AutoLockPolicy.immediate;

    lock.handleLifecycle(AppLifecycleState.hidden);
    await settle();

    expect(lock.overlayVisible.value, isTrue);
    expect(unlock.lockCount, 1);
    expect(session.isAuthenticated, isFalse);
    expect(session.vaultKey, isNull);
    expect(navigated, 1);
  });

  test('paused shows the overlay and keeps auto-lock', () async {
    auth.autoLockTimeout = AutoLockPolicy.oneMinute;

    lock.handleLifecycle(AppLifecycleState.paused);
    await settle();

    expect(lock.overlayVisible.value, isTrue);
    expect(unlock.lockCount, 0);
    expect(session.isAuthenticated, isTrue);
    expect(lastTimerDuration, AutoLockPolicy.oneMinute);
    expect(pauseStore.pausedAt, now);
  });

  test('detached behaves like paused for a one-minute timeout', () async {
    auth.autoLockTimeout = AutoLockPolicy.oneMinute;

    lock.handleLifecycle(AppLifecycleState.detached);
    await settle();

    expect(lock.overlayVisible.value, isTrue);
    expect(unlock.lockCount, 0);
    expect(session.isAuthenticated, isTrue);
    expect(lastTimerDuration, AutoLockPolicy.oneMinute);

    now = now.add(const Duration(seconds: 10));
    lock.handleLifecycle(AppLifecycleState.resumed);
    await settle();

    expect(unlock.lockCount, 0);
    expect(session.isAuthenticated, isTrue);
    expect(pauseStore.pausedAt, isNull);
  });

  test('overlay stays on through inactive after pause until resumed', () async {
    auth.autoLockTimeout = AutoLockPolicy.oneMinute;

    lock.handleLifecycle(AppLifecycleState.inactive);
    lock.handleLifecycle(AppLifecycleState.paused);
    await settle();
    lock.handleLifecycle(AppLifecycleState.inactive);
    await settle();

    expect(lock.overlayVisible.value, isTrue);
    expect(session.isAuthenticated, isTrue);

    now = now.add(const Duration(seconds: 10));
    lock.handleLifecycle(AppLifecycleState.resumed);
    await settle();

    expect(lock.overlayVisible.value, isFalse);
    expect(unlock.lockCount, 0);
    expect(session.isAuthenticated, isTrue);
  });

  test('resuming before the timeout keeps the session', () async {
    auth.autoLockTimeout = AutoLockPolicy.oneMinute;

    lock.handleLifecycle(AppLifecycleState.paused);
    await settle();
    now = now.add(const Duration(seconds: 10));
    lock.handleLifecycle(AppLifecycleState.resumed);
    await settle();

    expect(lock.overlayVisible.value, isFalse);
    expect(unlock.lockCount, 0);
    expect(session.isAuthenticated, isTrue);
    expect(navigated, 0);
    expect(pauseStore.pausedAt, isNull);
  });

  test('resuming after thirty seconds locks', () async {
    auth.autoLockTimeout = AutoLockPolicy.thirtySeconds;

    lock.handleLifecycle(AppLifecycleState.paused);
    await settle();
    now = now.add(const Duration(seconds: 31));
    lock.handleLifecycle(AppLifecycleState.resumed);
    await settle();

    expect(lock.overlayVisible.value, isFalse);
    expect(unlock.lockCount, 1);
    expect(session.isAuthenticated, isFalse);
    expect(session.vaultKey, isNull);
    expect(auth.userRecordDeleted, isFalse);
    expect(auth.vaultRecordDeleted, isFalse);
    expect(auth.accounts, isNotEmpty);
    expect(navigated, 1);
  });

  test('five minutes keeps the session until the timeout elapses', () async {
    auth.autoLockTimeout = AutoLockPolicy.fiveMinutes;

    lock.handleLifecycle(AppLifecycleState.paused);
    await settle();
    now = now.add(const Duration(minutes: 4, seconds: 59));
    lock.handleLifecycle(AppLifecycleState.resumed);
    await settle();

    expect(unlock.lockCount, 0);
    expect(session.isAuthenticated, isTrue);

    lock.handleLifecycle(AppLifecycleState.paused);
    await settle();
    now = now.add(const Duration(minutes: 5));
    lock.handleLifecycle(AppLifecycleState.resumed);
    await settle();

    expect(unlock.lockCount, 1);
    expect(session.isAuthenticated, isFalse);
  });

  test('timer expiry while backgrounded locks', () async {
    auth.autoLockTimeout = AutoLockPolicy.oneMinute;

    lock.handleLifecycle(AppLifecycleState.paused);
    await settle();
    fireTimer?.call();
    await settle();

    expect(lock.overlayVisible.value, isTrue);
    expect(unlock.lockCount, 1);
    expect(navigated, 1);
    expect(pauseStore.pausedAt, isNull);
  });

  test('hiding overlay after a background lock does not unlock', () async {
    auth.autoLockTimeout = AutoLockPolicy.immediate;

    lock.handleLifecycle(AppLifecycleState.paused);
    await settle();

    expect(session.isAuthenticated, isFalse);
    expect(navigated, 1);

    lock.handleLifecycle(AppLifecycleState.resumed);
    await settle();

    expect(lock.overlayVisible.value, isFalse);
    expect(session.isAuthenticated, isFalse);
    expect(unlock.lockCount, 1);
    expect(navigated, 1);
  });

  test('does not lock when the session is already locked', () async {
    session.clear();
    auth.autoLockTimeout = AutoLockPolicy.immediate;

    lock.handleLifecycle(AppLifecycleState.paused);
    await settle();

    expect(lock.overlayVisible.value, isTrue);
    expect(unlock.lockCount, 0);
    expect(navigated, 0);
  });

  test(
    'settings load failure uses the cached timeout instead of Immediate',
    () async {
      auth.autoLockTimeout = AutoLockPolicy.oneMinute;
      lock.handleLifecycle(AppLifecycleState.paused);
      await settle();
      now = now.add(const Duration(seconds: 1));
      lock.handleLifecycle(AppLifecycleState.resumed);
      await settle();

      auth.currentSecuritySettingsFailure = const DatabaseFailure();
      lock.handleLifecycle(AppLifecycleState.paused);
      await settle();

      expect(unlock.lockCount, 0);
      expect(session.isAuthenticated, isTrue);
      expect(lastTimerDuration, AutoLockPolicy.oneMinute);
    },
  );

  test(
    'timeout change applies to the next background without restart',
    () async {
      auth.autoLockTimeout = AutoLockPolicy.oneMinute;
      lock.onTimeoutChanged(AutoLockPolicy.thirtySeconds);
      auth.autoLockTimeout = AutoLockPolicy.thirtySeconds;

      lock.handleLifecycle(AppLifecycleState.paused);
      await settle();

      expect(lastTimerDuration, AutoLockPolicy.thirtySeconds);
      expect(unlock.lockCount, 0);
    },
  );

  test(
    'timeout change while backgrounded reschedules remaining time',
    () async {
      auth.autoLockTimeout = AutoLockPolicy.oneMinute;

      lock.handleLifecycle(AppLifecycleState.paused);
      await settle();
      expect(lastTimerDuration, AutoLockPolicy.oneMinute);

      now = now.add(const Duration(seconds: 20));
      lock.onTimeoutChanged(AutoLockPolicy.thirtySeconds);
      await settle();

      expect(lastTimerDuration, const Duration(seconds: 10));
      expect(unlock.lockCount, 0);

      now = now.add(const Duration(seconds: 10));
      fireTimer?.call();
      await settle();

      expect(unlock.lockCount, 1);
      expect(session.isAuthenticated, isFalse);
    },
  );

  test(
    'shortening below elapsed time locks while still backgrounded',
    () async {
      auth.autoLockTimeout = AutoLockPolicy.oneMinute;

      lock.handleLifecycle(AppLifecycleState.paused);
      await settle();
      now = now.add(const Duration(seconds: 40));
      lock.onTimeoutChanged(AutoLockPolicy.thirtySeconds);
      await settle();

      expect(unlock.lockCount, 1);
      expect(session.isAuthenticated, isFalse);
    },
  );

  test(
    'persisted pause longer than the timeout locks on applyPersistedPause',
    () async {
      pauseStore.pausedAt = now.subtract(const Duration(minutes: 2));
      auth.autoLockTimeout = AutoLockPolicy.oneMinute;

      await lock.applyPersistedPause();

      expect(unlock.lockCount, 1);
      expect(session.isAuthenticated, isFalse);
      expect(navigated, 1);
      expect(pauseStore.pausedAt, isNull);
    },
  );

  test('persisted pause shorter than the timeout keeps the session', () async {
    pauseStore.pausedAt = now.subtract(const Duration(seconds: 10));
    auth.autoLockTimeout = AutoLockPolicy.oneMinute;

    await lock.applyPersistedPause();

    expect(unlock.lockCount, 0);
    expect(session.isAuthenticated, isTrue);
    expect(pauseStore.pausedAt, isNull);
  });

  test(
    'cold start with no session stays locked even with a fresh pause stamp',
    () async {
      session.clear();
      pauseStore.pausedAt = now.subtract(const Duration(seconds: 5));
      auth.autoLockTimeout = AutoLockPolicy.oneMinute;

      await lock.applyPersistedPause();

      expect(unlock.lockCount, 0);
      expect(session.isAuthenticated, isFalse);
      expect(auth.accounts.single.id, 'user-1');
    },
  );

  test('does not navigate when already on an auth route', () async {
    lock.onClose();
    final guarded = AppLockController(
      session: session,
      unlock: unlock,
      auth: auth,
      pauseStore: pauseStore,
      clock: () => now,
      startTimer: (duration, callback) {
        lastTimerDuration = duration;
        fireTimer = callback;
        return _FakeTimer();
      },
      currentRoute: () => AppRoutes.authAccounts,
      observeBinding: false,
    );

    auth.autoLockTimeout = AutoLockPolicy.immediate;
    guarded.handleLifecycle(AppLifecycleState.paused);
    await settle();

    expect(unlock.lockCount, 1);
    expect(session.isAuthenticated, isFalse);
    expect(auth.accounts.single.id, 'user-1');

    guarded.onClose();
  });
}

class _FakeTimer implements Timer {
  bool _isActive = true;

  @override
  void cancel() {
    _isActive = false;
  }

  @override
  bool get isActive => _isActive;

  @override
  int get tick => 0;
}
