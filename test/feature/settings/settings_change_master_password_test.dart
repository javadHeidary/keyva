import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:keyva/core/di/injection_container.dart';
import 'package:keyva/core/exceptions/app_failure.dart';
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
    Get.put(settings);
    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.light,
        locale: const Locale('fa', 'IR'),
        home: const SettingsView(),
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

  Future<void> openChangeDialog(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('settings-change-master-password')));
    await pumpAuthSettle(tester);
  }

  Future<void> fillChangeForm(
    WidgetTester tester, {
    String current = '',
    String next = '',
    String confirm = '',
  }) async {
    await tester.enterText(
      find.byKey(const Key('settings-change-mp-current')),
      current,
    );
    await tester.enterText(find.byKey(const Key('settings-change-mp-new')), next);
    await tester.enterText(
      find.byKey(const Key('settings-change-mp-confirm')),
      confirm,
    );
  }

  Future<void> submitChange(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('settings-change-mp-submit')));
    await pumpAuthSettle(tester);
  }

  testWidgets('dialog explains the change and can be cancelled', (tester) async {
    await pumpSettings(tester);
    await openChangeDialog(tester);

    expect(find.text('تغییر رمز اصلی'), findsWidgets);
    expect(find.textContaining('رمز اصلی ذخیره نمی‌شود'), findsOneWidget);
    expect(find.byKey(const Key('settings-change-mp-current')), findsOneWidget);
    expect(find.byKey(const Key('settings-change-mp-new')), findsOneWidget);
    expect(find.byKey(const Key('settings-change-mp-confirm')), findsOneWidget);

    await tester.tap(find.byKey(const Key('settings-change-mp-cancel')));
    await pumpAuthSettle(tester);

    expect(find.byKey(const Key('settings-change-mp-current')), findsNothing);
    expect(auth.changeMasterPasswordCount, 0);
  });

  testWidgets('empty current password does not call auth', (tester) async {
    await pumpSettings(tester);
    await openChangeDialog(tester);
    await fillChangeForm(
      tester,
      next: 'new-password',
      confirm: 'new-password',
    );
    await submitChange(tester);

    expect(auth.changeMasterPasswordCount, 0);
    expect(find.textContaining('تغییر رمز اصلی'), findsWidgets);
    expect(find.textContaining('رمز اصلی فعلی را وارد کنید'), findsOneWidget);
    expect(find.byKey(const Key('settings-change-mp-current')), findsOneWidget);
    AppToast.dismiss();
  });

  testWidgets('empty new password does not call auth', (tester) async {
    await pumpSettings(tester);
    await openChangeDialog(tester);
    await fillChangeForm(tester, current: 'old-password');
    await submitChange(tester);

    expect(auth.changeMasterPasswordCount, 0);
    expect(find.textContaining('رمز اصلی جدید را وارد کنید'), findsOneWidget);
    AppToast.dismiss();
  });

  testWidgets('too-short new password does not call auth', (tester) async {
    await pumpSettings(tester);
    await openChangeDialog(tester);
    await fillChangeForm(
      tester,
      current: 'old-password',
      next: 'short',
      confirm: 'short',
    );
    await submitChange(tester);

    expect(auth.changeMasterPasswordCount, 0);
    expect(
      find.textContaining('رمز اصلی جدید باید حداقل ۸ کاراکتر باشد'),
      findsOneWidget,
    );
    AppToast.dismiss();
  });

  testWidgets('empty confirmation does not call auth', (tester) async {
    await pumpSettings(tester);
    await openChangeDialog(tester);
    await fillChangeForm(
      tester,
      current: 'old-password',
      next: 'new-password',
    );
    await submitChange(tester);

    expect(auth.changeMasterPasswordCount, 0);
    expect(
      find.textContaining('تکرار رمز اصلی جدید را وارد کنید'),
      findsOneWidget,
    );
    AppToast.dismiss();
  });

  testWidgets('mismatched confirmation does not call auth', (tester) async {
    await pumpSettings(tester);
    await openChangeDialog(tester);
    await fillChangeForm(
      tester,
      current: 'old-password',
      next: 'new-password',
      confirm: 'other-password',
    );
    await submitChange(tester);

    expect(auth.changeMasterPasswordCount, 0);
    expect(
      find.textContaining('تکرار رمز با رمز اصلی جدید یکسان نیست'),
      findsOneWidget,
    );
    AppToast.dismiss();
  });

  testWidgets('new password equal to current does not call auth', (tester) async {
    await pumpSettings(tester);
    await openChangeDialog(tester);
    await fillChangeForm(
      tester,
      current: 'same-password',
      next: 'same-password',
      confirm: 'same-password',
    );
    await submitChange(tester);

    expect(auth.changeMasterPasswordCount, 0);
    expect(
      find.textContaining('رمز اصلی جدید باید با رمز فعلی متفاوت باشد'),
      findsOneWidget,
    );
    AppToast.dismiss();
  });

  testWidgets('wrong current password stays on the dialog', (tester) async {
    auth.changeMasterPasswordFailure = const AuthenticationFailure();
    await pumpSettings(tester);
    await openChangeDialog(tester);
    await fillChangeForm(
      tester,
      current: 'wrong-password',
      next: 'new-password',
      confirm: 'new-password',
    );
    await submitChange(tester);

    expect(auth.changeMasterPasswordCount, 1);
    expect(session.isAuthenticated, isTrue);
    expect(find.textContaining('رمز اصلی فعلی صحیح نیست'), findsOneWidget);
    expect(find.byKey(const Key('settings-change-mp-current')), findsOneWidget);
    AppToast.dismiss();
  });

  testWidgets('persist failure stays on the dialog', (tester) async {
    auth.changeMasterPasswordFailure = const DatabaseFailure();
    await pumpSettings(tester);
    await openChangeDialog(tester);
    await fillChangeForm(
      tester,
      current: 'old-password',
      next: 'new-password',
      confirm: 'new-password',
    );
    await submitChange(tester);

    expect(auth.changeMasterPasswordCount, 1);
    expect(session.isAuthenticated, isTrue);
    expect(find.textContaining('تغییر رمز اصلی انجام نشد'), findsOneWidget);
    expect(find.byKey(const Key('settings-change-mp-current')), findsOneWidget);
    AppToast.dismiss();
  });

  testWidgets('successful change closes the dialog and shows a result toast', (
    tester,
  ) async {
    await pumpSettings(tester);
    await openChangeDialog(tester);
    await fillChangeForm(
      tester,
      current: 'old-password',
      next: 'new-password',
      confirm: 'new-password',
    );
    await submitChange(tester);

    expect(auth.changeMasterPasswordCount, 1);
    expect(auth.lastCurrentPassword, 'old-password');
    expect(auth.lastNewPassword, 'new-password');
    expect(find.byKey(const Key('settings-change-mp-current')), findsNothing);
    expect(find.textContaining('رمز اصلی تغییر کرد'), findsOneWidget);
    expect(
      find.textContaining('از این به بعد برای ورود با رمز'),
      findsOneWidget,
    );
    AppToast.dismiss();
  });
}
