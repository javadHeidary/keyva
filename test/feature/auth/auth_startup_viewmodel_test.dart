import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:keyva/core/exceptions/app_failure.dart';
import 'package:keyva/core/exceptions/result.dart';
import 'package:keyva/core/routes/app_routing.dart';
import 'package:keyva/core/session/session_service_impl.dart';
import 'package:keyva/feature/auth/widget/view_model/auth_startup_viewmodel.dart';

import '../../core/session/support/memory_auto_lock_pause_store.dart';
import 'support/fake_auth_repository.dart';
import 'support/fake_vault_unlock_service.dart';

void main() {
  late SessionServiceImpl session;
  late FakeAuthRepository auth;
  late AuthStartupViewModel startup;

  setUp(() {
    session = SessionServiceImpl();
    auth = FakeAuthRepository();
    startup = AuthStartupViewModel(session: session, auth: auth);
  });

  test('unlocked session restores the protected shell', () async {
    session.setAuthenticated(
      userId: 'user-1',
      username: 'test',
      vaultKey: Uint8List(32),
    );

    expect(await startup.resolveInitialRoute(), AppRoutes.shell);
  });

  test(
    'unlocked session with elapsed pause locks and opens Account List',
    () async {
      final now = DateTime.utc(2026, 8, 23, 12);
      session.setAuthenticated(
        userId: 'user-1',
        username: 'test',
        vaultKey: Uint8List(32),
      );
      auth.autoLockTimeout = const Duration(minutes: 1);
      final pauseStore = MemoryAutoLockPauseStore()
        ..pausedAt = now.subtract(const Duration(minutes: 2));
      final unlock = FakeVaultUnlockService(session: session);
      startup = AuthStartupViewModel(
        session: session,
        auth: auth,
        unlock: unlock,
        pauseStore: pauseStore,
        clock: () => now,
      );

      expect(await startup.resolveInitialRoute(), AppRoutes.authAccounts);
      expect(session.isAuthenticated, isFalse);
      expect(auth.accounts.single.id, 'user-1');
      expect(unlock.lockCount, 1);
    },
  );

  test('unlocked session with a fresh pause restores the shell', () async {
    final now = DateTime.utc(2026, 8, 23, 12);
    session.setAuthenticated(
      userId: 'user-1',
      username: 'test',
      vaultKey: Uint8List(32),
    );
    auth.autoLockTimeout = const Duration(minutes: 1);
    final pauseStore = MemoryAutoLockPauseStore()
      ..pausedAt = now.subtract(const Duration(seconds: 10));
    startup = AuthStartupViewModel(
      session: session,
      auth: auth,
      pauseStore: pauseStore,
      clock: () => now,
    );

    expect(await startup.resolveInitialRoute(), AppRoutes.shell);
    expect(session.isAuthenticated, isTrue);
    expect(pauseStore.pausedAt, isNull);
  });

  test(
    'locked device with persisted pause still goes to Account List',
    () async {
      final pauseStore = MemoryAutoLockPauseStore()
        ..pausedAt = DateTime.utc(2026, 8, 23, 12);
      auth.anyAccount = true;
      startup = AuthStartupViewModel(
        session: session,
        auth: auth,
        pauseStore: pauseStore,
      );

      expect(await startup.resolveInitialRoute(), AppRoutes.authAccounts);
      expect(session.isAuthenticated, isFalse);
      expect(auth.accounts, isNotEmpty);
    },
  );

  test('locked device with an account goes to Unlock', () async {
    auth.anyAccount = true;
    expect(await startup.resolveInitialRoute(), AppRoutes.authAccounts);
  });

  test('locked device with no account goes to onboarding', () async {
    auth.anyAccount = false;
    expect(await startup.resolveInitialRoute(), AppRoutes.onBoarding);
  });

  test('account lookup failure fails closed to Unlock', () async {
    auth = FakeHasAccountFailure();
    startup = AuthStartupViewModel(session: session, auth: auth);
    expect(await startup.resolveInitialRoute(), AppRoutes.authAccounts);
  });
}

class FakeHasAccountFailure extends FakeAuthRepository {
  @override
  Future<Result<bool>> hasAnyAccount() async {
    return const FailureResult(DatabaseFailure());
  }
}
