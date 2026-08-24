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
import 'package:keyva/feature/auth/view_model/auth_register_viewmodel.dart';
import 'package:keyva/feature/vault/service/vault_unlock_service.dart';
import 'package:keyva/shared/widget/app_buttom_widget.dart';
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
  late RegisterController register;

  setUp(() async {
    Get.testMode = true;
    await getIt.reset();
    session = SessionServiceImpl();
    auth = FakeAuthRepository();
    unlock = FakeVaultUnlockService(session: session);
    login = LoginController(unlock: unlock, auth: auth);
    register = RegisterController(auth: auth, unlock: unlock);
    getIt.registerSingleton<SessionService>(session);
    getIt.registerSingleton<AuthRepository>(auth);
    getIt.registerSingleton<VaultUnlockService>(unlock);
  });

  tearDown(() async {
    AppToast.dismiss();
    Get.reset();
    await getIt.reset();
  });

  Future<void> pumpRegister(WidgetTester tester) async {
    setupAuthWidgetSurface(tester);
    await tester.pumpWidget(
      authTestApp(
        initialRoute: AppRoutes.authRegister,
        login: login,
        register: register,
        extraPages: [
          GetPage(
            name: AppRoutes.authRestore,
            page: () => const Scaffold(
              key: Key('restore-page'),
              body: SizedBox.shrink(),
            ),
            transition: Transition.noTransition,
          ),
        ],
      ),
    );
    await pumpAuthFrame(tester);
  }

  Future<void> fillValidForm(WidgetTester tester) async {
    await tester.enterText(
      find.byKey(const Key('auth-register-username')),
      'کاربر',
    );
    await tester.enterText(
      find.byKey(const Key('auth-register-password')),
      'correct-password',
    );
    await tester.enterText(
      find.byKey(const Key('auth-register-confirm')),
      'correct-password',
    );
  }

  testWidgets('renders registration fields and submit', (tester) async {
    await pumpRegister(tester);

    expect(find.text('ایجاد حساب جدید'), findsOneWidget);
    expect(find.byKey(const Key('auth-register-username')), findsOneWidget);
    expect(find.byKey(const Key('auth-register-password')), findsOneWidget);
    expect(find.byKey(const Key('auth-register-confirm')), findsOneWidget);
    expect(find.byKey(const Key('auth-register-submit')), findsOneWidget);
    expect(find.text('رمز اصلی'), findsWidgets);
    expect(session.isAuthenticated, isFalse);
  });

  testWidgets('empty fields show validation errors', (tester) async {
    await pumpRegister(tester);

    await tester.ensureVisible(find.byKey(const Key('auth-register-submit')));
    await tester.tap(find.byKey(const Key('auth-register-submit')));
    await pumpAuthFrame(tester);

    expect(find.text('نام کاربری الزامی است'), findsOneWidget);
    expect(find.text('رمز عبور الزامی است'), findsWidgets);
    expect(auth.createCount, 0);
  });

  testWidgets('mismatched confirm password stays on the field', (tester) async {
    await pumpRegister(tester);

    await tester.enterText(
      find.byKey(const Key('auth-register-username')),
      'کاربر',
    );
    await tester.enterText(
      find.byKey(const Key('auth-register-password')),
      'correct-password',
    );
    await tester.enterText(
      find.byKey(const Key('auth-register-confirm')),
      'other-password',
    );
    await tester.ensureVisible(find.byKey(const Key('auth-register-submit')));
    await tester.tap(find.byKey(const Key('auth-register-submit')));
    await pumpAuthFrame(tester);

    expect(find.text('تکرار رمز عبور یکسان نیست'), findsOneWidget);
    expect(find.byKey(const Key('auth-register-warning-confirm')), findsNothing);
    expect(auth.createCount, 0);
  });

  testWidgets('warning dialog countdown enables confirm', (tester) async {
    await pumpRegister(tester);
    await fillValidForm(tester);
    await tester.ensureVisible(find.byKey(const Key('auth-register-submit')));
    await tester.tap(find.byKey(const Key('auth-register-submit')));
    await pumpAuthFrame(tester);

    expect(find.text('هشدار مهم امنیتی'), findsOneWidget);
    final confirm = find.byKey(const Key('auth-register-warning-confirm'));
    expect(confirm, findsOneWidget);
    expect(tester.widget<AppButtonWidget>(confirm).enabled, isFalse);

    await tester.pump(const Duration(seconds: 3));
    await pumpAuthFrame(tester);

    expect(tester.widget<AppButtonWidget>(confirm).enabled, isTrue);
  });

  testWidgets('loading prevents duplicate create and then opens shell', (
    tester,
  ) async {
    unlock.unlockGate = Completer<void>();
    await pumpRegister(tester);
    await fillValidForm(tester);
    await tester.ensureVisible(find.byKey(const Key('auth-register-submit')));
    await tester.tap(find.byKey(const Key('auth-register-submit')));
    await tester.pump(const Duration(seconds: 3));
    await pumpAuthFrame(tester);

    await tester.tap(find.byKey(const Key('auth-register-warning-confirm')));
    await tester.pump();

    expect(register.isLoading.value, isTrue);
    expect(find.byKey(const ValueKey('loading')), findsOneWidget);

    await tester.tap(find.byKey(const Key('auth-register-submit')));
    await tester.pump();
    expect(auth.createCount, 1);

    unlock.unlockGate!.complete();
    await pumpAuthSettle(tester);

    expect(session.isAuthenticated, isTrue);
    expect(find.byKey(const Key('shell-page')), findsOneWidget);
  });

  testWidgets('create failure shows a Persian toast and stays on register', (
    tester,
  ) async {
    auth.createFailure = const CryptoFailure();
    await pumpRegister(tester);
    await fillValidForm(tester);
    await tester.ensureVisible(find.byKey(const Key('auth-register-submit')));
    await tester.tap(find.byKey(const Key('auth-register-submit')));
    await tester.pump(const Duration(seconds: 3));
    await pumpAuthFrame(tester);
    await tester.tap(find.byKey(const Key('auth-register-warning-confirm')));
    await pumpAuthSettle(tester);

    expect(session.isAuthenticated, isFalse);
    expect(find.text('عملیات امنیتی انجام نشد.'), findsOneWidget);
    expect(find.byKey(const Key('shell-page')), findsNothing);
    expect(register.isLoading.value, isFalse);
    AppToast.dismiss();
  });

  testWidgets('ورود navigates toward accounts', (tester) async {
    auth.accounts = const [];
    await pumpRegister(tester);
    await tester.ensureVisible(
      find.byKey(const Key('auth-register-to-accounts')),
    );
    await tester.tap(find.byKey(const Key('auth-register-to-accounts')));
    await pumpAuthSettle(tester);

    expect(find.byKey(const Key('auth-accounts-empty')), findsOneWidget);
    expect(session.isAuthenticated, isFalse);
  });

  testWidgets('بازیابی opens restore', (tester) async {
    await pumpRegister(tester);
    await tester.ensureVisible(
      find.byKey(const Key('auth-register-to-restore')),
    );
    await tester.tap(find.byKey(const Key('auth-register-to-restore')));
    await pumpAuthSettle(tester);

    expect(find.byKey(const Key('restore-page')), findsOneWidget);
  });
}
