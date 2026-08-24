import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:keyva/core/di/injection_container.dart';
import 'package:keyva/core/routes/app_routing.dart';
import 'package:keyva/core/session/session_service.dart';
import 'package:keyva/core/session/session_service_impl.dart';
import 'package:keyva/feature/auth/model/account_summary.dart';
import 'package:keyva/feature/auth/repository/auth_repository.dart';
import 'package:keyva/feature/auth/view_model/auth_login_viewmodel.dart';
import 'package:keyva/feature/vault/service/vault_unlock_service.dart';
import 'package:keyva/shared/widget/toast_widget.dart';

import 'support/auth_widget_harness.dart';
import 'support/fake_auth_repository.dart';
import 'support/fake_vault_unlock_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SessionServiceImpl session;
  late FakeAuthRepository auth;
  late FakeVaultUnlockService unlock;
  late LoginController login;

  setUp(() async {
    Get.testMode = true;
    await getIt.reset();
    session = SessionServiceImpl();
    auth = FakeAuthRepository();
    unlock = FakeVaultUnlockService(session: session);
    login = LoginController(unlock: unlock, auth: auth);
    getIt.registerSingleton<SessionService>(session);
    getIt.registerSingleton<AuthRepository>(auth);
    getIt.registerSingleton<VaultUnlockService>(unlock);
  });

  tearDown(() async {
    AppToast.dismiss();
    Get.reset();
    await getIt.reset();
  });

  testWidgets('empty accounts show the empty state', (tester) async {
    auth.accounts = const [];
    setupAuthWidgetSurface(tester);
    await tester.pumpWidget(
      authTestApp(initialRoute: AppRoutes.authAccounts, login: login),
    );
    await pumpAuthSettle(tester);

    expect(find.byKey(const Key('auth-accounts-empty')), findsOneWidget);
    expect(find.byKey(const Key('auth-accounts-register')), findsOneWidget);
    expect(find.byKey(const Key('auth-accounts-restore')), findsOneWidget);
    expect(find.byKey(const Key('auth-accounts-list')), findsNothing);
    expect(session.isAuthenticated, isFalse);
  });

  testWidgets('one account skips the list and opens unlock', (tester) async {
    auth.accounts = const [AccountSummary(id: 'user-1', username: 'علی')];
    setupAuthWidgetSurface(tester);
    await tester.pumpWidget(
      authTestApp(initialRoute: AppRoutes.authAccounts, login: login),
    );
    await pumpAuthSettle(tester);

    expect(find.byKey(const Key('auth-accounts-list')), findsNothing);
    expect(find.byKey(const Key('auth-login-submit')), findsOneWidget);
    expect(find.text('علی'), findsWidgets);
    expect(Get.arguments, 'user-1');
  });

  testWidgets('multiple accounts are listed without secrets', (tester) async {
    auth.accounts = const [
      AccountSummary(id: 'user-a', username: 'علی'),
      AccountSummary(id: 'user-b', username: 'رضا'),
    ];
    setupAuthWidgetSurface(tester);
    await tester.pumpWidget(
      authTestApp(initialRoute: AppRoutes.authAccounts, login: login),
    );
    await pumpAuthSettle(tester);

    expect(find.byKey(const Key('auth-accounts-list')), findsOneWidget);
    expect(find.text('علی'), findsOneWidget);
    expect(find.text('رضا'), findsOneWidget);
    expect(find.textContaining('بازیابی'), findsOneWidget);
    expect(find.textContaining('wrappedVaultKey'), findsNothing);
    expect(find.textContaining('kdfSalt'), findsNothing);
    expect(session.isAuthenticated, isFalse);
  });

  testWidgets('selecting an account unlocks only that account', (tester) async {
    auth.accounts = const [
      AccountSummary(id: 'user-a', username: 'علی'),
      AccountSummary(id: 'user-b', username: 'رضا'),
    ];
    setupAuthWidgetSurface(tester);
    await tester.pumpWidget(
      authTestApp(initialRoute: AppRoutes.authAccounts, login: login),
    );
    await pumpAuthSettle(tester);

    await tester.tap(find.byKey(const Key('auth-account-item-user-b')));
    await pumpAuthSettle(tester);

    expect(Get.arguments, 'user-b');
    expect(Get.arguments, isA<String>());
    expect(find.text('رضا'), findsWidgets);
    expect(find.byKey(const Key('auth-unlock-change-account')), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('auth-login-password')),
      'reza-password',
    );
    await tester.tap(find.byKey(const Key('auth-login-submit')));
    await pumpAuthSettle(tester);

    expect(unlock.unlockCount, 1);
    expect(unlock.lastUserId, 'user-b');
    expect(unlock.lastPassword, 'reza-password');
    expect(session.current!.userId, 'user-b');
  });
}
