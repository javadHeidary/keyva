import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:keyva/core/routes/app_routing.dart';
import 'package:keyva/core/session/session_service_impl.dart';
import 'package:keyva/feature/auth/widget/view_model/auth_startup_viewmodel.dart';

import '../../core/session/support/memory_auto_lock_pause_store.dart';
import '../settings/support/fake_settings_repository.dart';
import 'support/fake_auth_repository.dart';
import 'support/fake_vault_unlock_service.dart';

void main() {
  late SessionServiceImpl session;
  late FakeAuthRepository auth;
  late FakeSettingsRepository settings;
  late AuthStartupViewModel startup;

  setUp(() {
    session = SessionServiceImpl();
    auth = FakeAuthRepository();
    settings = FakeSettingsRepository();
    startup = AuthStartupViewModel(
      session: session,
      auth: auth,
      settings: settings,
    );
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
        settings: settings,
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
      settings: settings,
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
      settings.onboardingCompleted = true;
      startup = AuthStartupViewModel(
        session: session,
        auth: auth,
        settings: settings,
        pauseStore: pauseStore,
      );

      expect(await startup.resolveInitialRoute(), AppRoutes.authAccounts);
      expect(session.isAuthenticated, isFalse);
    },
  );

  test('incomplete onboarding goes to Onboarding', () async {
    auth.anyAccount = false;
    settings.onboardingCompleted = false;
    expect(await startup.resolveInitialRoute(), AppRoutes.onBoarding);
  });

  test('completed onboarding with no account goes to Account List', () async {
    auth.anyAccount = false;
    settings.onboardingCompleted = true;
    expect(await startup.resolveInitialRoute(), AppRoutes.authAccounts);
  });

  test('completed onboarding with an account goes to Account List', () async {
    auth.anyAccount = true;
    settings.onboardingCompleted = true;
    expect(await startup.resolveInitialRoute(), AppRoutes.authAccounts);
  });

  test('incomplete onboarding is shown even when an account exists', () async {
    auth.anyAccount = true;
    settings.onboardingCompleted = false;
    expect(await startup.resolveInitialRoute(), AppRoutes.onBoarding);
  });
}
