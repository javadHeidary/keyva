import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:keyva/core/security/auto_lock_policy.dart';
import 'package:keyva/core/session/app_lock_controller.dart';
import 'package:keyva/core/session/session_service_impl.dart';

import '../../feature/auth/support/fake_auth_repository.dart';
import '../../feature/auth/support/fake_vault_unlock_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SessionServiceImpl session;
  late FakeVaultUnlockService unlock;
  late FakeAuthRepository auth;
  late AppLockController lock;
  late DateTime now;
  var navigated = false;
  void Function()? fireTimer;

  setUp(() {
    Get.testMode = true;
    session = SessionServiceImpl();
    session.setAuthenticated(
      userId: 'user-1',
      username: 'test',
      vaultKey: Uint8List(32),
    );
    unlock = FakeVaultUnlockService(session: session);
    auth = FakeAuthRepository();
    now = DateTime.utc(2026, 8, 19, 12);
    navigated = false;
    fireTimer = null;
    lock = AppLockController(
      session: session,
      unlock: unlock,
      auth: auth,
      clock: () => now,
      startTimer: (duration, callback) {
        fireTimer = callback;
        return _FakeTimer();
      },
      onLocked: () => navigated = true,
      observeBinding: false,
    );
  });

  tearDown(() {
    lock.onClose();
    Get.reset();
  });

  test('starts with the overlay hidden and the session intact', () {
    expect(lock.overlayVisible.value, isFalse);
    expect(session.isAuthenticated, isTrue);
    expect(unlock.lockCount, 0);
  });

  test('inactive shows the overlay without locking', () async {
    lock.handleLifecycle(AppLifecycleState.inactive);
    await Future<void>.delayed(Duration.zero);

    expect(lock.overlayVisible.value, isTrue);
    expect(unlock.lockCount, 0);
    expect(session.isAuthenticated, isTrue);
    expect(navigated, isFalse);
  });

  test('immediate timeout locks while backgrounded', () async {
    auth.autoLockTimeout = AutoLockPolicy.immediate;

    lock.handleLifecycle(AppLifecycleState.hidden);
    await Future<void>.delayed(Duration.zero);

    expect(lock.overlayVisible.value, isTrue);
    expect(unlock.lockCount, 1);
    expect(session.isAuthenticated, isFalse);
    expect(navigated, isTrue);
  });

  test('paused shows the overlay and keeps auto-lock', () async {
    auth.autoLockTimeout = AutoLockPolicy.oneMinute;

    lock.handleLifecycle(AppLifecycleState.paused);
    await Future<void>.delayed(Duration.zero);

    expect(lock.overlayVisible.value, isTrue);
    expect(unlock.lockCount, 0);
    expect(session.isAuthenticated, isTrue);
  });

  test('overlay stays on through inactive after pause until resumed', () async {
    auth.autoLockTimeout = AutoLockPolicy.oneMinute;

    lock.handleLifecycle(AppLifecycleState.inactive);
    lock.handleLifecycle(AppLifecycleState.paused);
    await Future<void>.delayed(Duration.zero);
    lock.handleLifecycle(AppLifecycleState.inactive);
    await Future<void>.delayed(Duration.zero);

    expect(lock.overlayVisible.value, isTrue);
    expect(session.isAuthenticated, isTrue);

    now = now.add(const Duration(seconds: 10));
    lock.handleLifecycle(AppLifecycleState.resumed);
    await Future<void>.delayed(Duration.zero);

    expect(lock.overlayVisible.value, isFalse);
    expect(unlock.lockCount, 0);
    expect(session.isAuthenticated, isTrue);
  });

  test('resuming before the timeout keeps the session', () async {
    auth.autoLockTimeout = AutoLockPolicy.oneMinute;

    lock.handleLifecycle(AppLifecycleState.paused);
    await Future<void>.delayed(Duration.zero);
    now = now.add(const Duration(seconds: 10));
    lock.handleLifecycle(AppLifecycleState.resumed);
    await Future<void>.delayed(Duration.zero);

    expect(lock.overlayVisible.value, isFalse);
    expect(unlock.lockCount, 0);
    expect(session.isAuthenticated, isTrue);
    expect(navigated, isFalse);
  });

  test('resuming after the timeout locks', () async {
    auth.autoLockTimeout = AutoLockPolicy.thirtySeconds;

    lock.handleLifecycle(AppLifecycleState.paused);
    await Future<void>.delayed(Duration.zero);
    now = now.add(const Duration(seconds: 31));
    lock.handleLifecycle(AppLifecycleState.resumed);
    await Future<void>.delayed(Duration.zero);

    expect(lock.overlayVisible.value, isFalse);
    expect(unlock.lockCount, 1);
    expect(session.isAuthenticated, isFalse);
    expect(navigated, isTrue);
  });

  test('timer expiry while backgrounded locks', () async {
    auth.autoLockTimeout = AutoLockPolicy.oneMinute;

    lock.handleLifecycle(AppLifecycleState.paused);
    await Future<void>.delayed(Duration.zero);
    fireTimer?.call();
    await Future<void>.delayed(Duration.zero);

    expect(lock.overlayVisible.value, isTrue);
    expect(unlock.lockCount, 1);
    expect(navigated, isTrue);
  });

  test('hiding overlay after a background lock does not unlock', () async {
    auth.autoLockTimeout = AutoLockPolicy.immediate;

    lock.handleLifecycle(AppLifecycleState.paused);
    await Future<void>.delayed(Duration.zero);

    expect(session.isAuthenticated, isFalse);
    expect(navigated, isTrue);

    lock.handleLifecycle(AppLifecycleState.resumed);
    await Future<void>.delayed(Duration.zero);

    expect(lock.overlayVisible.value, isFalse);
    expect(session.isAuthenticated, isFalse);
    expect(unlock.lockCount, 1);
    expect(navigated, isTrue);
  });

  test('does not lock when the session is already locked', () async {
    session.clear();
    auth.autoLockTimeout = AutoLockPolicy.immediate;

    lock.handleLifecycle(AppLifecycleState.paused);
    await Future<void>.delayed(Duration.zero);

    expect(lock.overlayVisible.value, isTrue);
    expect(unlock.lockCount, 0);
    expect(navigated, isFalse);
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
