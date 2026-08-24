import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:keyva/core/exceptions/app_failure.dart';
import 'package:keyva/core/session/session_service_impl.dart';
import 'package:keyva/core/theme/app_responsive.dart';
import 'package:keyva/core/theme/app_theme.dart';
import 'package:keyva/feature/settings/viewmodel/settings_viewmodel.dart';
import 'package:keyva/shared/widget/toast_widget.dart';

import '../../core/security/support/fake_screen_protection_service.dart';
import '../auth/support/fake_auth_repository.dart';
import '../auth/support/fake_biometric_service.dart';
import '../auth/support/fake_pin_service.dart';
import '../auth/support/fake_vault_unlock_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SessionServiceImpl session;
  late FakeAuthRepository auth;
  late FakeScreenProtectionService protection;
  late SettingsViewModel settings;

  setUp(() {
    Get.testMode = true;
    session = SessionServiceImpl();
    session.setAuthenticated(
      userId: 'user-1',
      username: 'test',
      vaultKey: Uint8List(32),
    );
    auth = FakeAuthRepository();
    protection = FakeScreenProtectionService();
    settings = _createSettings(
      session: session,
      auth: auth,
      protection: protection,
    );
  });

  tearDown(() {
    AppToast.dismiss();
    Get.reset();
  });

  test('default screenshot setting is off', () {
    expect(settings.security.value.preventScreenshot, isFalse);
  });

  test('recreated ViewModel loads the persisted screenshot setting', () async {
    auth.preventScreenshots = true;
    await settings.loadSecuritySettings();
    expect(settings.security.value.preventScreenshot, isTrue);

    final recreated = _createSettings(
      session: session,
      auth: auth,
      protection: protection,
    );
    await recreated.loadSecuritySettings();
    expect(recreated.security.value.preventScreenshot, isTrue);
    expect(auth.preventScreenshots, isTrue);
  });

  testWidgets('enable persists then applies runtime protection', (tester) async {
    final context = await _pumpOverlay(tester);
    await settings.setPreventScreenshot(true, context);
    await tester.pump();

    expect(auth.setPreventScreenshotsCount, 1);
    expect(auth.preventScreenshots, isTrue);
    expect(protection.setEnabledCount, 1);
    expect(protection.isEnabled, isTrue);
    expect(settings.security.value.preventScreenshot, isTrue);
  });

  testWidgets('disable persists then clears runtime protection', (tester) async {
    auth.preventScreenshots = true;
    protection.isEnabled = true;
    settings.security.value = settings.security.value.copyWith(
      preventScreenshot: true,
    );
    final context = await _pumpOverlay(tester);

    await settings.setPreventScreenshot(false, context);
    await tester.pump();

    expect(auth.preventScreenshots, isFalse);
    expect(protection.isEnabled, isFalse);
    expect(settings.security.value.preventScreenshot, isFalse);
  });

  testWidgets('persist failure does not apply FLAG_SECURE', (tester) async {
    auth.setPreventScreenshotsFailure = const DatabaseFailure();
    final context = await _pumpOverlay(tester);

    await settings.setPreventScreenshot(true, context);
    await tester.pump();

    expect(auth.preventScreenshots, isFalse);
    expect(protection.setEnabledCount, 0);
    expect(settings.security.value.preventScreenshot, isFalse);
    AppToast.dismiss();
    await tester.pump();
  });

  testWidgets('platform failure rolls back persisted state', (tester) async {
    protection.setEnabledFailure = const ScreenProtectionFailure();
    final context = await _pumpOverlay(tester);

    await settings.setPreventScreenshot(true, context);
    await tester.pump();

    expect(auth.setPreventScreenshotsCount, 2);
    expect(auth.preventScreenshots, isFalse);
    expect(protection.isEnabled, isFalse);
    expect(settings.security.value.preventScreenshot, isFalse);
    expect(find.text('محافظت صفحه'), findsOneWidget);
    expect(find.text('به‌روزرسانی محافظت صفحه انجام نشد.'), findsOneWidget);
    AppToast.dismiss();
    await tester.pump();
  });
}

SettingsViewModel _createSettings({
  required SessionServiceImpl session,
  required FakeAuthRepository auth,
  required FakeScreenProtectionService protection,
}) {
  return SettingsViewModel(
    unlock: FakeVaultUnlockService(session: session),
    pin: FakePinService(),
    biometric: FakeBiometricService(),
    session: session,
    auth: auth,
    screenProtection: protection,
  );
}

Future<BuildContext> _pumpOverlay(WidgetTester tester) async {
  late BuildContext saved;
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.75;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    GetMaterialApp(
      theme: AppTheme.light,
      locale: const Locale('fa', 'IR'),
      home: Builder(
        builder: (context) {
          AppResponsive.init(context);
          saved = context;
          return const SizedBox.shrink();
        },
      ),
    ),
  );
  await tester.pump();
  return saved;
}
