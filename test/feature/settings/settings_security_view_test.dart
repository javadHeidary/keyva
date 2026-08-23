import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:keyva/core/di/injection_container.dart';
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
import '../auth/support/fake_biometric_service.dart';
import '../auth/support/fake_pin_service.dart';
import '../../core/security/support/fake_screen_protection_service.dart';
import '../auth/support/fake_vault_unlock_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SessionServiceImpl session;
  late FakeVaultUnlockService unlock;
  late FakePinService pin;
  late FakeBiometricService biometric;
  late FakeAuthRepository auth;
  late FakeScreenProtectionService protection;
  late SettingsViewModel settings;

  setUp(() async {
    Get.testMode = true;
    await getIt.reset();
    session = SessionServiceImpl();
    session.setAuthenticated(
      userId: 'user-1',
      username: 'test',
      vaultKey: Uint8List(32),
    );
    unlock = FakeVaultUnlockService(session: session);
    pin = FakePinService();
    biometric = FakeBiometricService();
    auth = FakeAuthRepository();
    protection = FakeScreenProtectionService();
    settings = SettingsViewModel(
      unlock: unlock,
      pin: pin,
      biometric: biometric,
      session: session,
      auth: auth,
      screenProtection: protection,
    );
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

  testWidgets('PIN setup dialog validates length before enabling', (tester) async {
    await pumpSettings(tester);

    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('settings-pin-toggle')),
        matching: find.byType(Switch),
      ),
    );
    await pumpAuthSettle(tester);

    expect(find.text('تنظیم کد PIN'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('settings-pin-new')), '12');
    await tester.enterText(find.byKey(const Key('settings-pin-confirm')), '12');
    await tester.tap(find.byKey(const Key('settings-pin-save')));
    await pumpAuthSettle(tester);
    AppToast.dismiss();

    expect(pin.enableCount, 0);
    expect(settings.security.value.pinEnabled, isFalse);
  });

  testWidgets('PIN dialog ignores outside tap and closes with cancel', (
    tester,
  ) async {
    await pumpSettings(tester);

    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('settings-pin-toggle')),
        matching: find.byType(Switch),
      ),
    );
    await pumpAuthSettle(tester);
    expect(find.text('تنظیم کد PIN'), findsOneWidget);
    await tester.tapAt(const Offset(8, 8));
    await tester.pump();
    expect(find.text('تنظیم کد PIN'), findsOneWidget);
    await tester.tap(find.byKey(const Key('settings-pin-cancel')));
    await pumpAuthSettle(tester);
    expect(find.text('تنظیم کد PIN'), findsNothing);
    expect(pin.enableCount, 0);
  });

  testWidgets('PIN setup dialog enables PIN on matching valid values', (
    tester,
  ) async {
    await pumpSettings(tester);

    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('settings-pin-toggle')),
        matching: find.byType(Switch),
      ),
    );
    await pumpAuthSettle(tester);

    await tester.enterText(find.byKey(const Key('settings-pin-new')), '123456');
    await tester.enterText(find.byKey(const Key('settings-pin-confirm')), '123456');
    await tester.tap(find.byKey(const Key('settings-pin-save')));
    await pumpAuthSettle(tester);

    expect(pin.enableCount, 1);
    expect(pin.lastEnabledPin, '123456');
    expect(settings.security.value.pinEnabled, isTrue);
  });

  testWidgets('disabling PIN asks for confirmation', (tester) async {
    pin.enabled = true;
    settings.security.value = settings.security.value.copyWith(pinEnabled: true);
    await pumpSettings(tester);

    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('settings-pin-toggle')),
        matching: find.byType(Switch),
      ),
    );
    await pumpAuthSettle(tester);

    expect(find.text('غیرفعال کردن PIN'), findsOneWidget);
    await tester.tap(find.text('غیرفعال کردن'));
    await pumpAuthSettle(tester);

    expect(pin.disableCount, 1);
    expect(settings.security.value.pinEnabled, isFalse);
  });

  testWidgets('hides biometric toggle when the device has no biometrics', (
    tester,
  ) async {
    biometric.available = false;
    await pumpSettings(tester);

    expect(find.byKey(const Key('settings-biometric-toggle')), findsNothing);
  });

  testWidgets('change Master Password validates length before calling auth', (
    tester,
  ) async {
    await pumpSettings(tester);

    await tester.tap(find.byKey(const Key('settings-change-master-password')));
    await pumpAuthSettle(tester);

    await tester.enterText(
      find.byKey(const Key('settings-change-mp-current')),
      'old-password',
    );
    await tester.enterText(
      find.byKey(const Key('settings-change-mp-new')),
      'short',
    );
    await tester.enterText(
      find.byKey(const Key('settings-change-mp-confirm')),
      'short',
    );
    await tester.tap(find.byKey(const Key('settings-change-mp-submit')));
    await pumpAuthSettle(tester);
    AppToast.dismiss();

    expect(auth.changeMasterPasswordCount, 0);
    expect(find.text('تغییر رمز اصلی'), findsWidgets);
  });

  testWidgets('change Master Password submits matching valid values', (
    tester,
  ) async {
    await pumpSettings(tester);

    await tester.tap(find.byKey(const Key('settings-change-master-password')));
    await pumpAuthSettle(tester);

    await tester.enterText(
      find.byKey(const Key('settings-change-mp-current')),
      'old-password',
    );
    await tester.enterText(
      find.byKey(const Key('settings-change-mp-new')),
      'new-password',
    );
    await tester.enterText(
      find.byKey(const Key('settings-change-mp-confirm')),
      'new-password',
    );
    await tester.tap(find.byKey(const Key('settings-change-mp-submit')));
    await pumpAuthSettle(tester);
    AppToast.dismiss();

    expect(auth.changeMasterPasswordCount, 1);
    expect(auth.lastCurrentPassword, 'old-password');
    expect(auth.lastNewPassword, 'new-password');
  });

  testWidgets('auto-lock picker persists the selected timeout', (tester) async {
    await pumpSettings(tester);

    await tester.scrollUntilVisible(
      find.byKey(const Key('settings-auto-lock')),
      200,
      scrollable: find.byType(Scrollable),
    );
    await tester.tap(find.byKey(const Key('settings-auto-lock')));
    await pumpAuthSettle(tester);

    await tester.tap(find.byKey(const Key('settings-auto-lock-option-30')));
    await pumpAuthSettle(tester);

    expect(auth.setAutoLockTimeoutCount, 1);
    expect(auth.lastAutoLockTimeout, const Duration(seconds: 30));
    expect(settings.security.value.autoLockTimeout, const Duration(seconds: 30));
  });

  testWidgets('screenshot toggle defaults to off', (tester) async {
    await pumpSettings(tester);
    await tester.scrollUntilVisible(
      find.byKey(const Key('settings-prevent-screenshot')),
      200,
      scrollable: find.byType(Scrollable),
    );

    final toggle = tester.widget<Switch>(
      find.descendant(
        of: find.byKey(const Key('settings-prevent-screenshot')),
        matching: find.byType(Switch),
      ),
    );
    expect(toggle.value, isFalse);
  });

  testWidgets('screenshot toggle reflects the persisted setting', (tester) async {
    auth.preventScreenshots = true;
    await pumpSettings(tester);
    await tester.scrollUntilVisible(
      find.byKey(const Key('settings-prevent-screenshot')),
      200,
      scrollable: find.byType(Scrollable),
    );

    final toggle = tester.widget<Switch>(
      find.descendant(
        of: find.byKey(const Key('settings-prevent-screenshot')),
        matching: find.byType(Switch),
      ),
    );
    expect(toggle.value, isTrue);
  });

  testWidgets('enabling screenshot protection persists and applies', (
    tester,
  ) async {
    await pumpSettings(tester);
    await tester.scrollUntilVisible(
      find.byKey(const Key('settings-prevent-screenshot')),
      200,
      scrollable: find.byType(Scrollable),
    );
    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('settings-prevent-screenshot')),
        matching: find.byType(Switch),
      ),
    );
    await pumpAuthSettle(tester);

    expect(auth.setPreventScreenshotsCount, 1);
    expect(auth.preventScreenshots, isTrue);
    expect(protection.isEnabled, isTrue);
    expect(settings.security.value.preventScreenshot, isTrue);
  });
}
