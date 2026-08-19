import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:keyva/core/di/injection_container.dart';
import 'package:keyva/core/exceptions/app_failure.dart';
import 'package:keyva/core/routes/app_routing.dart';
import 'package:keyva/core/session/session_service.dart';
import 'package:keyva/core/session/session_service_impl.dart';
import 'package:keyva/feature/auth/repository/auth_repository.dart';
import 'package:keyva/feature/auth/view_model/auth_login_viewmodel.dart';
import 'package:keyva/feature/vault/service/vault_unlock_service.dart';

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
    getIt.registerSingleton<SessionService>(session);
    getIt.registerSingleton<AuthRepository>(auth);
    getIt.registerSingleton<VaultUnlockService>(unlock);
    login = LoginController(unlock: unlock, auth: auth);
  });

  tearDown(() async {
    Get.reset();
    await getIt.reset();
  });

  testWidgets('starts locked with a password field', (tester) async {
    setupAuthWidgetSurface(tester);
    await tester.pumpWidget(
      authTestApp(initialRoute: AppRoutes.authLogin, login: login),
    );
    await pumpAuthFrame(tester);

    expect(session.isAuthenticated, isFalse);
    expect(find.byKey(const Key('auth-login-password')), findsOneWidget);
    expect(find.byKey(const Key('auth-login-submit')), findsOneWidget);
    expect(find.byKey(const Key('shell-page')), findsNothing);
  });

  testWidgets('empty password shows validation error', (tester) async {
    setupAuthWidgetSurface(tester);
    await tester.pumpWidget(
      authTestApp(initialRoute: AppRoutes.authLogin, login: login),
    );
    await pumpAuthFrame(tester);

    await tester.tap(find.byKey(const Key('auth-login-submit')));
    await pumpAuthFrame(tester);

    expect(find.text('رمز عبور الزامی است'), findsOneWidget);
    expect(unlock.unlockCount, 0);
    expect(session.isAuthenticated, isFalse);
  });

  testWidgets('short password shows validation error', (tester) async {
    setupAuthWidgetSurface(tester);
    await tester.pumpWidget(
      authTestApp(initialRoute: AppRoutes.authLogin, login: login),
    );
    await pumpAuthFrame(tester);

    await tester.enterText(
      find.byKey(const Key('auth-login-password')),
      'short',
    );
    await tester.tap(find.byKey(const Key('auth-login-submit')));
    await pumpAuthFrame(tester);

    expect(find.text('رمز عبور باید حداقل ۸ کاراکتر باشد'), findsOneWidget);
    expect(unlock.unlockCount, 0);
  });

  testWidgets('submitting state is shown and duplicate submit is ignored', (
    tester,
  ) async {
    unlock.unlockGate = Completer<void>();
    setupAuthWidgetSurface(tester);
    await tester.pumpWidget(
      authTestApp(initialRoute: AppRoutes.authLogin, login: login),
    );
    await pumpAuthFrame(tester);

    await tester.enterText(
      find.byKey(const Key('auth-login-password')),
      'correct-password',
    );
    await tester.tap(find.byKey(const Key('auth-login-submit')));
    await tester.pump();

    expect(login.isLoading.value, isTrue);
    expect(find.byKey(const ValueKey('loading')), findsOneWidget);

    await tester.tap(find.byKey(const Key('auth-login-submit')));
    await tester.pump();
    expect(unlock.unlockCount, 1);

    unlock.unlockGate!.complete();
    await pumpAuthSettle(tester);

    expect(session.isAuthenticated, isTrue);
    expect(find.byKey(const Key('shell-page')), findsOneWidget);
  });

  testWidgets('successful unlock navigates to Home and establishes session', (
    tester,
  ) async {
    setupAuthWidgetSurface(tester);
    await tester.pumpWidget(
      authTestApp(initialRoute: AppRoutes.authLogin, login: login),
    );
    await pumpAuthFrame(tester);

    await tester.enterText(
      find.byKey(const Key('auth-login-password')),
      'correct-password',
    );
    await tester.tap(find.byKey(const Key('auth-login-submit')));
    await pumpAuthSettle(tester);

    expect(unlock.unlockCount, 1);
    expect(unlock.lastUserId, 'user-1');
    expect(unlock.lastPassword, 'correct-password');
    expect(session.isAuthenticated, isTrue);
    expect(session.vaultKey, isNotNull);
    expect(find.byKey(const Key('shell-page')), findsOneWidget);
  });

  testWidgets('failed unlock shows a Persian error and stays on Unlock', (
    tester,
  ) async {
    unlock.unlockFailure = const AuthenticationFailure();
    setupAuthWidgetSurface(tester);
    await tester.pumpWidget(
      authTestApp(initialRoute: AppRoutes.authLogin, login: login),
    );
    await pumpAuthFrame(tester);

    await tester.enterText(
      find.byKey(const Key('auth-login-password')),
      'wrong-password',
    );
    await tester.tap(find.byKey(const Key('auth-login-submit')));
    await pumpAuthSettle(tester);

    expect(session.isAuthenticated, isFalse);
    expect(find.byKey(const Key('auth-login-error')), findsOneWidget);
    expect(find.text('باز کردن گاوصندوق ممکن نشد.'), findsOneWidget);
    expect(find.byKey(const Key('shell-page')), findsNothing);
    expect(find.textContaining('AuthenticationFailure'), findsNothing);
    expect(find.textContaining('Hive'), findsNothing);
    expect(login.passwordController.text, isEmpty);
    expect(login.isLoading.value, isFalse);
  });
}
