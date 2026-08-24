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
import 'package:keyva/feature/auth/widget/auth_brand_header.dart';
import 'package:keyva/feature/vault/service/vault_unlock_service.dart';
import 'package:keyva/shared/icons/app_icons.dart';
import 'package:keyva/shared/widget/app_page_loading_overlay.dart';
import 'package:keyva/shared/widget/toast_widget.dart';

import 'support/auth_widget_harness.dart';
import 'support/fake_auth_repository.dart';
import 'support/fake_biometric_service.dart';
import 'support/fake_pin_service.dart';
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
    AppToast.dismiss();
    Get.reset();
    await getIt.reset();
  });

  testWidgets('starts locked with a password field', (tester) async {
    setupAuthWidgetSurface(tester);
    await tester.pumpWidget(
      authTestApp(initialRoute: AppRoutes.authUnlock, login: login),
    );
    await pumpAuthFrame(tester);

    expect(session.isAuthenticated, isFalse);
    expect(find.byKey(const Key('auth-login-password')), findsOneWidget);
    expect(find.byKey(const Key('auth-login-submit')), findsOneWidget);
    expect(find.byKey(const Key('shell-page')), findsNothing);
    expect(find.byType(AuthBrandHeader), findsNothing);
    expect(find.text('کی وا'), findsNothing);
    expect(find.text('Keyva'), findsNothing);
    expect(find.text('کیوا'), findsNothing);
    expect(find.text('تغییر حساب'), findsNothing);
    expect(find.byKey(const Key('auth-unlock-back')), findsNothing);
    expect(find.byIcon(AppIcon.arrowBack), findsNothing);
  });

  testWidgets('empty password shows validation error', (tester) async {
    setupAuthWidgetSurface(tester);
    await tester.pumpWidget(
      authTestApp(initialRoute: AppRoutes.authUnlock, login: login),
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
      authTestApp(initialRoute: AppRoutes.authUnlock, login: login),
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
      authTestApp(initialRoute: AppRoutes.authUnlock, login: login),
    );
    await pumpAuthFrame(tester);

    await tester.enterText(
      find.byKey(const Key('auth-login-password')),
      'correct-password',
    );
    await tester.tap(find.byKey(const Key('auth-login-submit')));
    await tester.pump();

    expect(login.isLoading.value, isTrue);
    expect(find.byKey(AppPageLoadingOverlay.overlayKey), findsOneWidget);
    expect(find.byKey(AppPageLoadingOverlay.barrierKey), findsOneWidget);
    expect(find.text(LoginController.loadingMessage), findsOneWidget);
    expect(find.byKey(const ValueKey('loading')), findsNothing);

    await tester.tap(find.byKey(AppPageLoadingOverlay.barrierKey));
    await tester.pump();
    expect(login.isLoading.value, isTrue);
    expect(find.byKey(AppPageLoadingOverlay.overlayKey), findsOneWidget);
    expect(unlock.unlockCount, 1);

    await login.login();
    expect(unlock.unlockCount, 1);

    unlock.unlockGate!.complete();
    await pumpAuthSettle(tester);

    expect(session.isAuthenticated, isTrue);
    expect(find.byKey(const Key('shell-page')), findsOneWidget);
    expect(find.text(LoginController.successTitle), findsOneWidget);
    expect(find.text(LoginController.successBody), findsOneWidget);
    AppToast.dismiss();
  });

  testWidgets('successful unlock navigates to Home and establishes session', (
    tester,
  ) async {
    setupAuthWidgetSurface(tester);
    await tester.pumpWidget(
      authTestApp(initialRoute: AppRoutes.authUnlock, login: login),
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
    expect(find.text(LoginController.successTitle), findsOneWidget);
    expect(find.text(LoginController.successBody), findsOneWidget);
    AppToast.dismiss();
  });

  testWidgets('failed unlock shows a Persian error and stays on Unlock', (
    tester,
  ) async {
    unlock.unlockFailure = const AuthenticationFailure();
    setupAuthWidgetSurface(tester);
    await tester.pumpWidget(
      authTestApp(initialRoute: AppRoutes.authUnlock, login: login),
    );
    await pumpAuthFrame(tester);

    await tester.enterText(
      find.byKey(const Key('auth-login-password')),
      'wrong-password',
    );
    await tester.tap(find.byKey(const Key('auth-login-submit')));
    await pumpAuthSettle(tester);

    expect(session.isAuthenticated, isFalse);
    expect(find.text(LoginController.errorTitle), findsWidgets);
    expect(find.text('باز کردن گاوصندوق ممکن نشد.'), findsOneWidget);
    expect(find.byKey(const Key('shell-page')), findsNothing);
    expect(find.textContaining('AuthenticationFailure'), findsNothing);
    expect(find.textContaining('Hive'), findsNothing);
    expect(login.passwordController.text, isEmpty);
    expect(login.isLoading.value, isFalse);
    AppToast.dismiss();
  });

  testWidgets('PIN field is shown when PIN is enabled', (tester) async {
    final pin = FakePinService()..enabled = true;
    login = LoginController(unlock: unlock, auth: auth, pin: pin);
    setupAuthWidgetSurface(tester);
    await tester.pumpWidget(
      authTestApp(initialRoute: AppRoutes.authUnlock, login: login),
    );
    await pumpAuthSettle(tester);

    expect(find.byKey(const Key('auth-unlock-method-pin')), findsOneWidget);
    await tester.tap(find.byKey(const Key('auth-unlock-method-pin')));
    await pumpAuthFrame(tester);

    expect(find.byKey(const Key('auth-login-pin')), findsOneWidget);
    expect(find.byKey(const Key('auth-login-password')), findsNothing);
    expect(
      find.byKey(const Key('auth-login-use-master-password')),
      findsOneWidget,
    );
  });

  testWidgets('wrong PIN shows remaining attempts', (tester) async {
    final pin = FakePinService()
      ..enabled = true
      ..remaining = 2;
    unlock.unlockFailure = const AuthenticationFailure();
    login = LoginController(unlock: unlock, auth: auth, pin: pin);
    setupAuthWidgetSurface(tester);
    await tester.pumpWidget(
      authTestApp(initialRoute: AppRoutes.authUnlock, login: login),
    );
    await pumpAuthSettle(tester);

    await tester.tap(find.byKey(const Key('auth-unlock-method-pin')));
    await pumpAuthFrame(tester);
    await tester.enterText(find.byKey(const Key('auth-login-pin')), '123456');
    await tester.tap(find.byKey(const Key('auth-login-pin-submit')));
    await pumpAuthSettle(tester);

    expect(unlock.pinUnlockCount, 1);
    expect(session.isAuthenticated, isFalse);
    expect(
      find.text('کد PIN نادرست است. ۲ تلاش باقی مانده است.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('shell-page')), findsNothing);
    expect(login.pinController.text, isEmpty);
    AppToast.dismiss();
  });

  testWidgets('Master Password fallback is available from PIN unlock', (
    tester,
  ) async {
    final pin = FakePinService()..enabled = true;
    login = LoginController(unlock: unlock, auth: auth, pin: pin);
    setupAuthWidgetSurface(tester);
    await tester.pumpWidget(
      authTestApp(initialRoute: AppRoutes.authUnlock, login: login),
    );
    await pumpAuthSettle(tester);

    await tester.tap(find.byKey(const Key('auth-unlock-method-pin')));
    await pumpAuthFrame(tester);
    await tester.tap(find.byKey(const Key('auth-login-use-master-password')));
    await pumpAuthFrame(tester);

    expect(find.byKey(const Key('auth-login-password')), findsOneWidget);
    expect(find.byKey(const Key('auth-login-pin')), findsNothing);
  });

  testWidgets('PIN lockout shows Master Password instead of PIN', (
    tester,
  ) async {
    final pin = FakePinService()
      ..enabled = true
      ..lockedOut = true;
    login = LoginController(unlock: unlock, auth: auth, pin: pin);
    setupAuthWidgetSurface(tester);
    await tester.pumpWidget(
      authTestApp(initialRoute: AppRoutes.authUnlock, login: login),
    );
    await pumpAuthSettle(tester);

    expect(find.byKey(const Key('auth-login-password')), findsOneWidget);
    expect(find.byKey(const Key('auth-login-pin')), findsNothing);
    expect(find.byKey(const Key('auth-unlock-method-pin')), findsNothing);
    expect(find.byKey(const Key('auth-login-use-pin')), findsNothing);
  });

  testWidgets('third PIN failure shows lockout dialog and Master Password', (
    tester,
  ) async {
    final pin = FakePinService()..enabled = true;
    unlock.unlockFailure = const AuthenticationFailure();
    login = LoginController(unlock: unlock, auth: auth, pin: pin);
    setupAuthWidgetSurface(tester);
    await tester.pumpWidget(
      authTestApp(initialRoute: AppRoutes.authUnlock, login: login),
    );
    await pumpAuthSettle(tester);

    await tester.tap(find.byKey(const Key('auth-unlock-method-pin')));
    await pumpAuthFrame(tester);
    pin.lockedOut = true;
    pin.remaining = 0;
    await tester.enterText(find.byKey(const Key('auth-login-pin')), '123456');
    await tester.tap(find.byKey(const Key('auth-login-pin-submit')));
    await pumpAuthSettle(tester);

    expect(find.text(LoginController.pinLockoutMessage), findsOneWidget);
    expect(find.byKey(const Key('auth-login-password')), findsOneWidget);
    expect(find.byKey(const Key('auth-login-pin')), findsNothing);
    expect(find.byKey(const Key('auth-unlock-method-pin')), findsNothing);
  });

  testWidgets('biometric option appears only when enabled and available', (
    tester,
  ) async {
    final biometric = FakeBiometricService()
      ..available = true
      ..enabled = true;
    login = LoginController(unlock: unlock, auth: auth, biometric: biometric);
    setupAuthWidgetSurface(tester);
    await tester.pumpWidget(
      authTestApp(initialRoute: AppRoutes.authUnlock, login: login),
    );
    await pumpAuthSettle(tester);

    expect(
      find.byKey(const Key('auth-unlock-method-biometric')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('auth-unlock-method-master')), findsOneWidget);
  });

  testWidgets('successful biometric unlock uses the selected account', (
    tester,
  ) async {
    final biometric = FakeBiometricService()
      ..available = true
      ..enabled = true;
    login = LoginController(unlock: unlock, auth: auth, biometric: biometric);
    setupAuthWidgetSurface(tester);
    await tester.pumpWidget(
      authTestApp(initialRoute: AppRoutes.authUnlock, login: login),
    );
    await pumpAuthSettle(tester);

    await tester.tap(find.byKey(const Key('auth-unlock-method-biometric')));
    await pumpAuthSettle(tester);

    expect(unlock.biometricUnlockCount, 1);
    expect(unlock.lastUserId, 'user-1');
    expect(session.isAuthenticated, isTrue);
    expect(session.current!.userId, 'user-1');
    expect(find.byKey(const Key('shell-page')), findsOneWidget);
    expect(find.text(LoginController.successTitle), findsOneWidget);
    expect(find.text(LoginController.successBody), findsOneWidget);
    AppToast.dismiss();
  });

  testWidgets('cancelled biometric does not unlock', (tester) async {
    final biometric = FakeBiometricService()
      ..available = true
      ..enabled = true;
    unlock.unlockFailure = const BiometricCancelledFailure();
    login = LoginController(unlock: unlock, auth: auth, biometric: biometric);
    setupAuthWidgetSurface(tester);
    await tester.pumpWidget(
      authTestApp(initialRoute: AppRoutes.authUnlock, login: login),
    );
    await pumpAuthSettle(tester);

    await tester.tap(find.byKey(const Key('auth-unlock-method-biometric')));
    await pumpAuthSettle(tester);

    expect(session.isAuthenticated, isFalse);
    expect(find.byKey(const Key('shell-page')), findsNothing);
    expect(find.byKey(const Key('auth-login-error')), findsNothing);
  });

  testWidgets('failed biometric shows remaining attempts', (tester) async {
    final biometric = FakeBiometricService()
      ..available = true
      ..enabled = true
      ..remaining = 2;
    unlock.unlockFailure = const BiometricAuthFailedFailure();
    login = LoginController(unlock: unlock, auth: auth, biometric: biometric);
    setupAuthWidgetSurface(tester);
    await tester.pumpWidget(
      authTestApp(initialRoute: AppRoutes.authUnlock, login: login),
    );
    await pumpAuthSettle(tester);

    await tester.tap(find.byKey(const Key('auth-unlock-method-biometric')));
    await pumpAuthSettle(tester);

    expect(session.isAuthenticated, isFalse);
    expect(find.byKey(const Key('shell-page')), findsNothing);
    expect(
      find.text('ورود با اثرانگشت ناموفق بود. ۲ تلاش باقی مانده است.'),
      findsOneWidget,
    );
    AppToast.dismiss();
  });

  testWidgets('third biometric failure shows lockout dialog', (tester) async {
    final biometric = FakeBiometricService()
      ..available = true
      ..enabled = true;
    unlock.unlockFailure = const BiometricAuthFailedFailure();
    login = LoginController(unlock: unlock, auth: auth, biometric: biometric);
    setupAuthWidgetSurface(tester);
    await tester.pumpWidget(
      authTestApp(initialRoute: AppRoutes.authUnlock, login: login),
    );
    await pumpAuthSettle(tester);

    biometric.lockedOut = true;
    biometric.remaining = 0;
    await tester.tap(find.byKey(const Key('auth-unlock-method-biometric')));
    await pumpAuthSettle(tester);

    expect(find.text(LoginController.biometricLockoutMessage), findsOneWidget);
    expect(find.byKey(const Key('auth-login-password')), findsOneWidget);
    expect(find.byKey(const Key('auth-unlock-method-biometric')), findsNothing);
  });

  testWidgets('unavailable biometric shows a Persian message', (tester) async {
    final biometric = FakeBiometricService()
      ..available = true
      ..enabled = true;
    unlock.unlockFailure = const BiometricUnavailableFailure();
    login = LoginController(unlock: unlock, auth: auth, biometric: biometric);
    setupAuthWidgetSurface(tester);
    await tester.pumpWidget(
      authTestApp(initialRoute: AppRoutes.authUnlock, login: login),
    );
    await pumpAuthSettle(tester);

    await tester.tap(find.byKey(const Key('auth-unlock-method-biometric')));
    await pumpAuthSettle(tester);

    expect(session.isAuthenticated, isFalse);
    expect(find.byKey(const Key('shell-page')), findsNothing);
    expect(
      find.text('ورود با اثرانگشت روی این دستگاه در دسترس نیست.'),
      findsOneWidget,
    );
    AppToast.dismiss();
  });

  testWidgets('not configured biometric shows a Persian message', (
    tester,
  ) async {
    final biometric = FakeBiometricService()
      ..available = true
      ..enabled = true;
    unlock.unlockFailure = const BiometricNotConfiguredFailure();
    login = LoginController(unlock: unlock, auth: auth, biometric: biometric);
    setupAuthWidgetSurface(tester);
    await tester.pumpWidget(
      authTestApp(initialRoute: AppRoutes.authUnlock, login: login),
    );
    await pumpAuthSettle(tester);

    await tester.tap(find.byKey(const Key('auth-unlock-method-biometric')));
    await pumpAuthSettle(tester);

    expect(session.isAuthenticated, isFalse);
    expect(find.byKey(const Key('shell-page')), findsNothing);
    expect(
      find.text('ورود با اثرانگشت برای این حساب تنظیم نشده است.'),
      findsOneWidget,
    );
    AppToast.dismiss();
  });

  testWidgets('vault unlock failure after biometric stays generic', (
    tester,
  ) async {
    final biometric = FakeBiometricService()
      ..available = true
      ..enabled = true;
    unlock.unlockFailure = const AuthenticationFailure();
    login = LoginController(unlock: unlock, auth: auth, biometric: biometric);
    setupAuthWidgetSurface(tester);
    await tester.pumpWidget(
      authTestApp(initialRoute: AppRoutes.authUnlock, login: login),
    );
    await pumpAuthSettle(tester);

    await tester.tap(find.byKey(const Key('auth-unlock-method-biometric')));
    await pumpAuthSettle(tester);

    expect(session.isAuthenticated, isFalse);
    expect(find.text(LoginController.errorTitle), findsWidgets);
    expect(find.text('باز کردن گاوصندوق ممکن نشد.'), findsOneWidget);
    AppToast.dismiss();
  });

  testWidgets('biometric lockout hides the biometric option', (tester) async {
    final biometric = FakeBiometricService()
      ..available = true
      ..enabled = true
      ..lockedOut = true;
    login = LoginController(unlock: unlock, auth: auth, biometric: biometric);
    setupAuthWidgetSurface(tester);
    await tester.pumpWidget(
      authTestApp(initialRoute: AppRoutes.authUnlock, login: login),
    );
    await pumpAuthSettle(tester);

    expect(find.byKey(const Key('auth-login-password')), findsOneWidget);
    expect(find.byKey(const Key('auth-unlock-method-biometric')), findsNothing);
  });

  testWidgets('PIN shorter than 6 digits is rejected before unlock', (
    tester,
  ) async {
    final pin = FakePinService()..enabled = true;
    login = LoginController(unlock: unlock, auth: auth, pin: pin);
    setupAuthWidgetSurface(tester);
    await tester.pumpWidget(
      authTestApp(initialRoute: AppRoutes.authUnlock, login: login),
    );
    await pumpAuthSettle(tester);

    await tester.tap(find.byKey(const Key('auth-unlock-method-pin')));
    await pumpAuthFrame(tester);
    await tester.enterText(find.byKey(const Key('auth-login-pin')), '12345');
    await tester.tap(find.byKey(const Key('auth-login-pin-submit')));
    await pumpAuthFrame(tester);

    expect(unlock.pinUnlockCount, 0);
    expect(find.text('پین کد باید ۶ رقم باشد.'), findsWidgets);
  });
}
