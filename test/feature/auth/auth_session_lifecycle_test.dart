import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:keyva/core/di/injection_container.dart';
import 'package:keyva/core/routes/app_routing.dart';
import 'package:keyva/core/routes/session_guard.dart';
import 'package:keyva/core/session/session_service.dart';
import 'package:keyva/core/session/session_service_impl.dart';
import 'package:keyva/feature/auth/repository/auth_repository.dart';
import 'package:keyva/feature/auth/view_model/auth_login_viewmodel.dart';
import 'package:keyva/feature/home/view/home_view.dart';
import 'package:keyva/feature/home/viewmodel/home_viewmodel.dart';
import 'package:keyva/feature/settings/viewmodel/settings_viewmodel.dart';
import 'package:keyva/feature/vault/model/login_item.dart';
import 'package:keyva/feature/vault/model/vault_data.dart';
import 'package:keyva/feature/vault/service/vault_unlock_service.dart';
import 'package:keyva/feature/vault/viewmodel/vault_home_viewmodel.dart';

import '../vault/support/fake_vault_operation_service.dart';
import 'support/auth_widget_harness.dart';
import 'support/fake_auth_repository.dart';
import 'support/fake_vault_unlock_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SessionServiceImpl session;
  late FakeAuthRepository auth;
  late FakeVaultUnlockService unlock;
  late FakeVaultOperationService operations;
  late VaultHomeViewModel vault;
  late HomeController home;
  late LoginController login;
  late SettingsViewModel settings;

  setUp(() async {
    Get.testMode = true;
    await getIt.reset();
    session = SessionServiceImpl();
    auth = FakeAuthRepository();
    unlock = FakeVaultUnlockService(session: session);
    operations = FakeVaultOperationService();
    operations.vault = VaultData(
      version: VaultData.currentVersion,
      logins: [
        LoginItem(
          id: 'login-1',
          title: 'Mail',
          username: 'keep-this-user',
          password: 'keep-this-password',
          website: 'https://mail.test',
          notes: null,
          categoryId: null,
          createdAt: DateTime.utc(2026, 7, 1),
          updatedAt: DateTime.utc(2026, 7, 2),
        ),
      ],
      bankCards: const [],
      secureNotes: const [],
      categories: const [],
    );
    vault = VaultHomeViewModel(operations: operations);
    home = HomeController(vault: vault, unlock: unlock);
    login = LoginController(unlock: unlock, auth: auth);
    settings = SettingsViewModel(unlock: unlock);
    getIt.registerSingleton<SessionService>(session);
    getIt.registerSingleton<AuthRepository>(auth);
    getIt.registerSingleton<VaultUnlockService>(unlock);
  });

  tearDown(() async {
    Get.reset();
    await getIt.reset();
  });

  void authenticateSession() {
    session.setAuthenticated(
      userId: 'user-1',
      username: 'test',
      vaultKey: Uint8List(32),
    );
  }

  testWidgets('Locked Home redirects to Unlock', (tester) async {
    setupAuthWidgetSurface(tester);
    await tester.pumpWidget(
      authTestApp(initialRoute: AppRoutes.home, login: login),
    );
    await pumpAuthSettle(tester);

    expect(find.byKey(const Key('auth-login-submit')), findsOneWidget);
    expect(find.byKey(const Key('home-page')), findsNothing);
    expect(session.isAuthenticated, isFalse);
  });

  testWidgets('Unlocked Home is accessible', (tester) async {
    authenticateSession();
    setupAuthWidgetSurface(tester);
    await tester.pumpWidget(
      authTestApp(initialRoute: AppRoutes.home, login: login),
    );
    await pumpAuthSettle(tester);

    expect(find.byKey(const Key('home-page')), findsOneWidget);
    expect(find.byKey(const Key('auth-login-submit')), findsNothing);
  });

  testWidgets('lock from Home clears the session and returns to Unlock', (
    tester,
  ) async {
    authenticateSession();
    await vault.loadVault();
    setupAuthWidgetSurface(tester);
    await tester.pumpWidget(
      authTestApp(
        initialRoute: '/locked-home',
        login: login,
        extraPages: [
          GetPage(
            name: '/locked-home',
            page: () => const HomeView(),
            binding: BindingsBuilder(() {
              Get.put(vault);
              Get.put(home);
            }),
            middlewares: [SessionGuard()],
            transition: Transition.noTransition,
          ),
        ],
      ),
    );
    await pumpAuthSettle(tester);

    expect(find.byKey(const Key('home-lock')), findsOneWidget);

    await tester.tap(find.byKey(const Key('home-lock')));
    await pumpAuthSettle(tester);
    await pumpAuthSettle(tester);

    expect(unlock.lockCount, 1);
    expect(session.isAuthenticated, isFalse);
    expect(session.vaultKey, isNull);
    expect(find.byKey(const Key('auth-login-submit')), findsOneWidget);
    expect(find.byKey(const Key('home-lock')), findsNothing);
  });

  testWidgets('logout clears the session without deleting vault data', (
    tester,
  ) async {
    authenticateSession();
    setupAuthWidgetSurface(tester);
    await tester.pumpWidget(
      authTestApp(
        initialRoute: '/settings',
        login: login,
        extraPages: [
          GetPage(
            name: '/settings',
            page: () => Scaffold(
              body: Center(
                child: TextButton(
                  key: const Key('settings-logout'),
                  onPressed: settings.onLogoutConfirmed,
                  child: const Text('خروج از حساب'),
                ),
              ),
            ),
            middlewares: [SessionGuard()],
            transition: Transition.noTransition,
          ),
        ],
      ),
    );
    await pumpAuthSettle(tester);

    await tester.tap(find.byKey(const Key('settings-logout')));
    await pumpAuthSettle(tester);
    await pumpAuthSettle(tester);

    expect(unlock.lockCount, 1);
    expect(session.isAuthenticated, isFalse);
    expect(auth.userRecordDeleted, isFalse);
    expect(auth.vaultRecordDeleted, isFalse);
    expect(find.byKey(const Key('auth-login-submit')), findsOneWidget);
  });

  testWidgets('after lock, opening Home still redirects to Unlock', (
    tester,
  ) async {
    authenticateSession();
    await vault.loadVault();
    setupAuthWidgetSurface(tester);
    await tester.pumpWidget(
      authTestApp(
        initialRoute: '/locked-home',
        login: login,
        extraPages: [
          GetPage(
            name: '/locked-home',
            page: () => const HomeView(),
            binding: BindingsBuilder(() {
              Get.put(vault);
              Get.put(home);
            }),
            middlewares: [SessionGuard()],
            transition: Transition.noTransition,
          ),
        ],
      ),
    );
    await pumpAuthSettle(tester);

    await tester.tap(find.byKey(const Key('home-lock')));
    await pumpAuthSettle(tester);
    await pumpAuthSettle(tester);

    expect(unlock.lockCount, 1);
    expect(session.isAuthenticated, isFalse);
    expect(find.byKey(const Key('auth-login-submit')), findsOneWidget);

    final redirect = SessionGuard().redirect(AppRoutes.home);
    expect(redirect?.name, AppRoutes.authAccounts);
    expect(find.byKey(const Key('home-page')), findsNothing);
  });
}
