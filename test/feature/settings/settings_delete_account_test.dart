import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:keyva/core/di/injection_container.dart';
import 'package:keyva/core/exceptions/app_failure.dart';
import 'package:keyva/core/routes/app_routing.dart';
import 'package:keyva/core/session/session_service.dart';
import 'package:keyva/core/session/session_service_impl.dart';
import 'package:keyva/core/theme/app_responsive.dart';
import 'package:keyva/core/theme/app_theme.dart';
import 'package:keyva/feature/settings/view/settings_view.dart';
import 'package:keyva/feature/settings/viewmodel/settings_viewmodel.dart';
import 'package:keyva/feature/vault/service/vault_unlock_service.dart';
import 'package:keyva/shared/widget/toast_widget.dart';

import '../auth/support/auth_widget_harness.dart';
import '../auth/support/fake_auth_repository.dart';
import '../auth/support/fake_vault_unlock_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SessionServiceImpl session;
  late FakeVaultUnlockService unlock;
  late FakeAuthRepository auth;
  late SettingsViewModel settings;

  setUp(() async {
    Get.testMode = true;
    await getIt.reset();
    session = SessionServiceImpl();
    session.setAuthenticated(
      userId: 'user-1',
      username: 'علی',
      vaultKey: Uint8List(32),
    );
    unlock = FakeVaultUnlockService(session: session);
    auth = FakeAuthRepository();
    settings = SettingsViewModel(unlock: unlock, auth: auth, session: session);
    getIt.registerSingleton<SessionService>(session);
    getIt.registerSingleton<VaultUnlockService>(unlock);
  });

  tearDown(() async {
    AppToast.dismiss();
    Get.reset();
    await getIt.reset();
  });

  Future<void> pumpSettings(WidgetTester tester) async {
    setupAuthWidgetSurface(tester);
    tester.view.physicalSize = const Size(1080, 5000);
    Get.put(settings);
    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.light,
        locale: const Locale('fa', 'IR'),
        initialRoute: '/settings-home',
        getPages: [
          GetPage(name: '/settings-home', page: () => const SettingsView()),
          GetPage(
            name: AppRoutes.onBoarding,
            page: () => const Scaffold(
              key: Key('onboarding-page'),
              body: SizedBox.shrink(),
            ),
          ),
          GetPage(
            name: AppRoutes.authAccounts,
            page: () => const Scaffold(
              key: Key('accounts-page'),
              body: SizedBox.shrink(),
            ),
          ),
        ],
        builder: (context, child) {
          AppResponsive.init(context);
          return Directionality(
            textDirection: TextDirection.rtl,
            child: child!,
          );
        },
      ),
    );
    await pumpAuthSettle(tester);
  }

  Future<void> openDeleteDialog(WidgetTester tester) async {
    final deleteButton = find.byKey(const Key('settings-delete-account'));
    await tester.ensureVisible(deleteButton);
    await tester.pumpAndSettle();
    await tester.tap(deleteButton);
    await pumpAuthSettle(tester);
  }

  testWidgets('settings shows a delete account action below logout', (
    tester,
  ) async {
    await pumpSettings(tester);
    final deleteButton = find.byKey(const Key('settings-delete-account'));
    await tester.ensureVisible(deleteButton);
    await tester.pumpAndSettle();
    expect(deleteButton, findsOneWidget);
    expect(find.text('حذف حساب'), findsOneWidget);
  });

  testWidgets('delete dialog warns, requires password, and can be cancelled', (
    tester,
  ) async {
    await pumpSettings(tester);
    await openDeleteDialog(tester);

    expect(find.text('حذف حساب'), findsWidgets);
    expect(find.textContaining('قابل بازگشت نیست'), findsOneWidget);
    expect(
      find.byKey(const Key('settings-delete-account-password')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('settings-delete-account-cancel')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('settings-delete-account-cancel')));
    await pumpAuthSettle(tester);

    expect(
      find.byKey(const Key('settings-delete-account-password')),
      findsNothing,
    );
    expect(auth.deleteAccountCount, 0);
    expect(unlock.lockCount, 0);
    expect(session.isAuthenticated, isTrue);
  });

  testWidgets('system back does not close the dialog unless cancel is tapped', (
    tester,
  ) async {
    await pumpSettings(tester);
    await openDeleteDialog(tester);

    await tester.binding.handlePopRoute();
    await pumpAuthSettle(tester);

    expect(
      find.byKey(const Key('settings-delete-account-password')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('settings-delete-account')), findsOneWidget);
  });

  testWidgets('back and cancel are blocked while deletion is in progress', (
    tester,
  ) async {
    auth.deleteAccountGate = Completer<void>();
    await pumpSettings(tester);
    await openDeleteDialog(tester);

    await tester.enterText(
      find.byKey(const Key('settings-delete-account-password')),
      'correct-master-password',
    );
    await tester.tap(find.byKey(const Key('settings-delete-account-confirm')));
    await tester.pump();
    await tester.pump();

    expect(settings.isSecurityBusy.value, isTrue);
    expect(
      find.byKey(const Key('settings-delete-account-stay-open')),
      findsOneWidget,
    );

    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(
      find.byKey(const Key('settings-delete-account-password')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('settings-delete-account-cancel')));
    await tester.pump();
    expect(
      find.byKey(const Key('settings-delete-account-password')),
      findsOneWidget,
    );

    auth.deleteAccountGate!.complete();
    await pumpAuthSettle(tester);
    AppToast.dismiss();
  });

  testWidgets('empty password does not delete the account', (tester) async {
    await pumpSettings(tester);
    await openDeleteDialog(tester);

    await tester.tap(find.byKey(const Key('settings-delete-account-confirm')));
    await pumpAuthSettle(tester);

    expect(auth.deleteAccountCount, 0);
    expect(find.textContaining('رمز اصلی را وارد کنید'), findsOneWidget);
    expect(
      find.byKey(const Key('settings-delete-account-password')),
      findsOneWidget,
    );
    AppToast.dismiss();
  });

  testWidgets('wrong password keeps the session and stays on the dialog', (
    tester,
  ) async {
    auth.deleteAccountFailure = const AuthenticationFailure();
    await pumpSettings(tester);
    await openDeleteDialog(tester);

    await tester.enterText(
      find.byKey(const Key('settings-delete-account-password')),
      'wrong-password-1',
    );
    await tester.tap(find.byKey(const Key('settings-delete-account-confirm')));
    await pumpAuthSettle(tester);

    expect(auth.deleteAccountCount, 1);
    expect(auth.lastDeletePassword, 'wrong-password-1');
    expect(unlock.lockCount, 0);
    expect(session.isAuthenticated, isTrue);
    expect(find.textContaining('رمز اصلی صحیح نیست'), findsOneWidget);
    expect(
      find.byKey(const Key('settings-delete-account-password')),
      findsOneWidget,
    );
    AppToast.dismiss();
  });

  testWidgets('deleting the last account navigates to account selection', (
    tester,
  ) async {
    auth.deleteHasRemainingAccounts = false;
    await pumpSettings(tester);
    await openDeleteDialog(tester);

    await tester.enterText(
      find.byKey(const Key('settings-delete-account-password')),
      'correct-master-password',
    );
    await tester.tap(find.byKey(const Key('settings-delete-account-confirm')));
    await pumpAuthSettle(tester);

    expect(auth.deleteAccountCount, 1);
    expect(unlock.lockCount, 1);
    expect(session.isAuthenticated, isFalse);
    expect(find.byKey(const Key('accounts-page')), findsOneWidget);
    expect(find.byKey(const Key('onboarding-page')), findsNothing);
    expect(find.textContaining('حساب حذف شد'), findsOneWidget);
    AppToast.dismiss();
  });

  testWidgets(
    'deleting one of several accounts navigates to account selection',
    (tester) async {
      auth.deleteHasRemainingAccounts = true;
      await pumpSettings(tester);
      await openDeleteDialog(tester);

      await tester.enterText(
        find.byKey(const Key('settings-delete-account-password')),
        'correct-master-password',
      );
      await tester.tap(
        find.byKey(const Key('settings-delete-account-confirm')),
      );
      await pumpAuthSettle(tester);

      expect(unlock.lockCount, 1);
      expect(find.byKey(const Key('accounts-page')), findsOneWidget);
      expect(find.byKey(const Key('onboarding-page')), findsNothing);
      AppToast.dismiss();
    },
  );

  testWidgets('incomplete deletion stays in settings', (tester) async {
    auth.deleteAccountFailure = const DatabaseFailure();
    await pumpSettings(tester);
    await openDeleteDialog(tester);

    await tester.enterText(
      find.byKey(const Key('settings-delete-account-password')),
      'correct-master-password',
    );
    await tester.tap(find.byKey(const Key('settings-delete-account-confirm')));
    await pumpAuthSettle(tester);

    expect(unlock.lockCount, 0);
    expect(session.isAuthenticated, isTrue);
    expect(
      find.byKey(const Key('settings-delete-account-password')),
      findsOneWidget,
    );
    expect(find.textContaining('حذف حساب کامل نشد'), findsOneWidget);
    AppToast.dismiss();
  });
}
