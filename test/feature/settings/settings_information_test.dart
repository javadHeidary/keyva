import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:keyva/core/di/injection_container.dart';
import 'package:keyva/core/routes/app_routing.dart';
import 'package:keyva/core/session/session_service.dart';
import 'package:keyva/core/session/session_service_impl.dart';
import 'package:keyva/core/theme/app_responsive.dart';
import 'package:keyva/core/theme/app_theme.dart';
import 'package:keyva/feature/settings/model/about_content.dart';
import 'package:keyva/feature/settings/model/app_info.dart';
import 'package:keyva/feature/settings/model/privacy_policy_content.dart';
import 'package:keyva/feature/settings/view/about_view.dart';
import 'package:keyva/feature/settings/view/privacy_policy_view.dart';
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
  late List<Uri> launched;
  late Future<bool> Function(Uri uri) launchHandler;

  setUp(() async {
    Get.testMode = true;
    await getIt.reset();
    launched = <Uri>[];
    launchHandler = (_) async => true;
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
      launchUrlFn: (uri) async {
        launched.add(uri);
        return launchHandler(uri);
      },
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
        getPages: [
          GetPage(
            name: AppRoutes.privacyPolicy,
            page: () => const PrivacyPolicyView(),
          ),
          GetPage(name: AppRoutes.about, page: () => const AboutView()),
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

  Future<void> reveal(WidgetTester tester, Key key) async {
    await tester.scrollUntilVisible(
      find.byKey(key),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }

  testWidgets('privacy policy row opens the dedicated page', (tester) async {
    await pumpSettings(tester);
    await reveal(tester, const Key('settings-privacy-policy'));
    await tester.tap(find.byKey(const Key('settings-privacy-policy')));
    await tester.pumpAndSettle();

    expect(find.byType(PrivacyPolicyView), findsOneWidget);
    expect(find.text(PrivacyPolicyContent.title), findsWidgets);
    expect(find.text('ذخیره‌سازی داده‌ها'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.byType(PrivacyPolicyView))),
      TextDirection.rtl,
    );
  });

  testWidgets('about row opens the dedicated page with version', (
    tester,
  ) async {
    await pumpSettings(tester);
    await reveal(tester, const Key('settings-about'));
    await tester.tap(find.byKey(const Key('settings-about')));
    await tester.pumpAndSettle();

    expect(find.byType(AboutView), findsOneWidget);
    expect(find.text(AboutContent.aboutTitle), findsWidgets);
    expect(find.text(AboutContent.tagline), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(AboutView),
        matching: find.text(AppInfo.displayVersion),
      ),
      findsOneWidget,
    );
    expect(
      Directionality.of(tester.element(find.byType(AboutView))),
      TextDirection.rtl,
    );
  });

  testWidgets('contact row opens a sheet with three options', (tester) async {
    await pumpSettings(tester);
    await reveal(tester, const Key('settings-contact'));
    await tester.tap(find.byKey(const Key('settings-contact')));
    await tester.pumpAndSettle();

    expect(find.text('ارتباط با ما'), findsOneWidget);
    expect(find.byKey(const Key('contact-telegram')), findsOneWidget);
    expect(find.byKey(const Key('contact-bale')), findsOneWidget);
    expect(find.byKey(const Key('contact-email')), findsOneWidget);
    expect(find.text('تلگرام'), findsOneWidget);
    expect(find.text('بله'), findsOneWidget);
    expect(find.text('ایمیل'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.text('ارتباط با ما'))),
      TextDirection.rtl,
    );
  });

  testWidgets('unconfigured telegram shows a friendly toast', (tester) async {
    await pumpSettings(tester);
    await reveal(tester, const Key('settings-contact'));
    await tester.tap(find.byKey(const Key('settings-contact')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('contact-telegram')));
    await tester.pump();

    expect(find.text('لینک تلگرام کیوا هنوز تنظیم نشده است.'), findsOneWidget);
    expect(launched, isEmpty);
    expect(find.text('ارتباط با ما'), findsWidgets);
    AppToast.dismiss();
    await tester.pump();
  });

  testWidgets('unconfigured bale shows a friendly toast', (tester) async {
    await pumpSettings(tester);
    await reveal(tester, const Key('settings-contact'));
    await tester.tap(find.byKey(const Key('settings-contact')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('contact-bale')));
    await tester.pump();

    expect(find.text('لینک بله کیوا هنوز تنظیم نشده است.'), findsOneWidget);
    expect(launched, isEmpty);
    expect(find.text('ارتباط با ما'), findsWidgets);
    AppToast.dismiss();
    await tester.pump();
  });

  testWidgets('email launches mailto and closes the sheet', (tester) async {
    await pumpSettings(tester);
    await reveal(tester, const Key('settings-contact'));
    await tester.tap(find.byKey(const Key('settings-contact')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('contact-email')));
    await tester.pumpAndSettle();

    expect(launched, hasLength(1));
    expect(launched.single.scheme, 'mailto');
    expect(launched.single.path, AppInfo.feedbackEmail);
    expect(find.text('ارتباط با ما'), findsNothing);
  });

  testWidgets('email launch failure keeps sheet and shows address', (
    tester,
  ) async {
    launchHandler = (_) async => false;
    await pumpSettings(tester);
    await reveal(tester, const Key('settings-contact'));
    await tester.tap(find.byKey(const Key('settings-contact')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('contact-email')));
    await tester.pump();

    expect(find.text('ایمیل: ${AppInfo.feedbackEmail}'), findsOneWidget);
    expect(find.text('ایمیل'), findsWidgets);
    expect(find.text('ارتباط با ما'), findsOneWidget);
    AppToast.dismiss();
    await tester.pump();
  });

  testWidgets('configured telegram launches and closes the sheet', (
    tester,
  ) async {
    settings = SettingsViewModel(
      unlock: unlock,
      pin: pin,
      biometric: biometric,
      session: session,
      auth: auth,
      screenProtection: protection,
      telegramUrl: 'https://t.me/keyva',
      launchUrlFn: (uri) async {
        launched.add(uri);
        return launchHandler(uri);
      },
    );
    await pumpSettings(tester);
    await reveal(tester, const Key('settings-contact'));
    await tester.tap(find.byKey(const Key('settings-contact')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('contact-telegram')));
    await tester.pumpAndSettle();

    expect(launched.single.toString(), 'https://t.me/keyva');
    expect(find.text('ارتباط با ما'), findsNothing);
  });

  testWidgets('bale falls back to web url when the app url fails', (
    tester,
  ) async {
    launchHandler = (uri) async => uri.scheme == 'https';
    settings = SettingsViewModel(
      unlock: unlock,
      pin: pin,
      biometric: biometric,
      session: session,
      auth: auth,
      screenProtection: protection,
      baleUrl: 'bale://ble.ir/keyva',
      baleFallbackUrl: 'https://ble.ir/keyva',
      launchUrlFn: (uri) async {
        launched.add(uri);
        return launchHandler(uri);
      },
    );
    await pumpSettings(tester);
    await reveal(tester, const Key('settings-contact'));
    await tester.tap(find.byKey(const Key('settings-contact')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('contact-bale')));
    await tester.pumpAndSettle();

    expect(launched.map((uri) => uri.toString()).toList(), [
      'bale://ble.ir/keyva',
      'https://ble.ir/keyva',
    ]);
    expect(find.text('ارتباط با ما'), findsNothing);
  });

  testWidgets('telegram launch exception shows a friendly toast', (
    tester,
  ) async {
    settings = SettingsViewModel(
      unlock: unlock,
      pin: pin,
      biometric: biometric,
      session: session,
      auth: auth,
      screenProtection: protection,
      telegramUrl: 'https://t.me/keyva',
      launchUrlFn: (uri) async {
        launched.add(uri);
        throw Exception('unavailable');
      },
    );
    await pumpSettings(tester);
    await reveal(tester, const Key('settings-contact'));
    await tester.tap(find.byKey(const Key('settings-contact')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('contact-telegram')));
    await tester.pump();

    expect(
      find.text('امکان باز کردن این مسیر ارتباطی وجود ندارد.'),
      findsOneWidget,
    );
    expect(find.text('ارتباط با ما'), findsWidgets);
    AppToast.dismiss();
    await tester.pump();
  });
}
