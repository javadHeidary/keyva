import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:keyva/core/di/injection_container.dart';
import 'package:keyva/core/session/session_service.dart';
import 'package:keyva/core/session/session_service_impl.dart';
import 'package:keyva/core/store/store_config.dart';
import 'package:keyva/core/store/store_link_launcher.dart';
import 'package:keyva/core/theme/app_responsive.dart';
import 'package:keyva/core/theme/app_theme.dart';
import 'package:keyva/feature/settings/model/support_us_content.dart';
import 'package:keyva/feature/settings/view/settings_view.dart';
import 'package:keyva/feature/settings/viewmodel/settings_viewmodel.dart';
import 'package:keyva/feature/vault/service/vault_unlock_service.dart';
import 'package:keyva/feature/vault/share/share_sheet_service.dart';
import 'package:keyva/shared/widget/toast_widget.dart';

import '../../core/security/support/fake_screen_protection_service.dart';
import '../auth/support/auth_widget_harness.dart';
import '../auth/support/fake_auth_repository.dart';
import '../auth/support/fake_biometric_service.dart';
import '../auth/support/fake_pin_service.dart';
import '../auth/support/fake_vault_unlock_service.dart';
import '../vault/support/fake_share_sheet_service.dart';

class _StoreLaunchCall {
  _StoreLaunchCall({required this.action, required this.uri, this.package});

  final String action;
  final String uri;
  final String? package;
}

class FakeStoreLinkLauncher implements StoreLinkLauncher {
  final nativeCalls = <_StoreLaunchCall>[];
  final urlCalls = <String>[];
  final nativeResults = <bool>[];
  final urlResults = <bool>[];
  bool defaultNativeResult = true;
  bool defaultUrlResult = true;

  @override
  Future<bool> launchNative({
    required String action,
    required String uri,
    String? package,
  }) async {
    nativeCalls.add(
      _StoreLaunchCall(action: action, uri: uri, package: package),
    );
    if (nativeResults.isNotEmpty) {
      return nativeResults.removeAt(0);
    }
    return defaultNativeResult;
  }

  @override
  Future<bool> launchExternalUrl(String url) async {
    urlCalls.add(url);
    if (urlResults.isNotEmpty) {
      return urlResults.removeAt(0);
    }
    return defaultUrlResult;
  }
}

StoreConfig withOtherApps(
  StoreConfig base, {
  required String native,
  required String web,
}) {
  return StoreConfig(
    store: base.store,
    packageId: base.packageId,
    keyvaStoreUrl: base.keyvaStoreUrl,
    reviewNativeUri: base.reviewNativeUri,
    detailsNativeUri: base.detailsNativeUri,
    detailsWebUrl: base.detailsWebUrl,
    otherAppsNativeUri: native,
    otherAppsWebUrl: web,
    reviewIntentAction: base.reviewIntentAction,
    storeAppPackage: base.storeAppPackage,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SessionServiceImpl session;
  late FakeVaultUnlockService unlock;
  late FakePinService pin;
  late FakeBiometricService biometric;
  late FakeAuthRepository auth;
  late FakeScreenProtectionService protection;
  late FakeStoreLinkLauncher storeLinks;
  late FakeShareSheetService shareSheet;
  late SettingsViewModel settings;

  SettingsViewModel buildSettings({StoreConfig? storeConfig}) {
    return SettingsViewModel(
      unlock: unlock,
      pin: pin,
      biometric: biometric,
      session: session,
      auth: auth,
      screenProtection: protection,
      storeConfig: storeConfig ?? StoreConfig.bazaar(),
      storeLinks: storeLinks,
      shareSheet: shareSheet,
    );
  }

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
    storeLinks = FakeStoreLinkLauncher();
    shareSheet = FakeShareSheetService();
    settings = buildSettings();
    getIt.registerSingleton<SessionService>(session);
    getIt.registerSingleton<VaultUnlockService>(unlock);
  });

  tearDown(() async {
    AppToast.dismiss();
    Get.reset();
    await getIt.reset();
  });

  Future<BuildContext> pumpHost(WidgetTester tester) async {
    setupAuthWidgetSurface(tester);
    late BuildContext captured;
    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.light,
        locale: const Locale('fa', 'IR'),
        home: Builder(
          builder: (context) {
            captured = context;
            AppResponsive.init(context);
            return const SizedBox.expand();
          },
        ),
      ),
    );
    await pumpAuthSettle(tester);
    return captured;
  }

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

  testWidgets('review uses the official store intent first', (tester) async {
    final context = await pumpHost(tester);
    await settings.onRateApp(context);

    expect(storeLinks.nativeCalls, hasLength(1));
    expect(storeLinks.nativeCalls.first.action, StoreIntentAction.edit);
    expect(
      storeLinks.nativeCalls.first.uri,
      StoreConfig.bazaar().reviewNativeUri,
    );
    expect(
      storeLinks.nativeCalls.first.package,
      StoreConfig.bazaarStorePackage,
    );
    expect(storeLinks.urlCalls, isEmpty);
  });

  testWidgets('review falls back to the store details page', (tester) async {
    storeLinks.nativeResults.addAll([false, true]);
    final context = await pumpHost(tester);
    await settings.onRateApp(context);

    expect(storeLinks.nativeCalls, hasLength(2));
    expect(storeLinks.nativeCalls[0].action, StoreIntentAction.edit);
    expect(storeLinks.nativeCalls[0].uri, StoreConfig.bazaar().reviewNativeUri);
    expect(storeLinks.nativeCalls[1].action, StoreIntentAction.view);
    expect(
      storeLinks.nativeCalls[1].uri,
      StoreConfig.bazaar().detailsNativeUri,
    );
    expect(storeLinks.urlCalls, isEmpty);
  });

  testWidgets('review falls back to the https store page then toasts', (
    tester,
  ) async {
    storeLinks.defaultNativeResult = false;
    storeLinks.defaultUrlResult = false;
    final context = await pumpHost(tester);
    await settings.onRateApp(context);
    await tester.pump();

    expect(storeLinks.nativeCalls, hasLength(2));
    expect(storeLinks.urlCalls, [StoreConfig.bazaar().detailsWebUrl]);
    expect(find.text(SupportUsContent.rateTitle), findsWidgets);
    expect(find.text(SupportUsContent.rateUnavailable), findsOneWidget);
    AppToast.dismiss();
    await tester.pump();
  });

  testWidgets('Myket review uses the comment intent then Myket URLs', (
    tester,
  ) async {
    settings = buildSettings(storeConfig: StoreConfig.myket());
    storeLinks.nativeResults.addAll([false, false]);
    storeLinks.defaultUrlResult = true;
    final context = await pumpHost(tester);
    await settings.onRateApp(context);

    expect(storeLinks.nativeCalls[0].action, StoreIntentAction.view);
    expect(storeLinks.nativeCalls[0].uri, StoreConfig.myket().reviewNativeUri);
    expect(storeLinks.nativeCalls[1].uri, StoreConfig.myket().detailsNativeUri);
    expect(storeLinks.urlCalls, [StoreConfig.myket().detailsWebUrl]);
    expect(storeLinks.urlCalls.single, contains('myket.ir'));
    expect(storeLinks.urlCalls.single, isNot(contains('cafebazaar.ir')));
  });

  testWidgets('other apps uses native listing then web fallback', (
    tester,
  ) async {
    const native = 'bazaar://collection?slug=by_author&aid=dev';
    const web = 'https://cafebazaar.ir/developer/dev';
    settings = buildSettings(
      storeConfig: withOtherApps(
        StoreConfig.bazaar(),
        native: native,
        web: web,
      ),
    );
    storeLinks.defaultNativeResult = false;
    final context = await pumpHost(tester);
    await settings.onOpenOtherApps(context);

    expect(storeLinks.nativeCalls, hasLength(1));
    expect(storeLinks.nativeCalls.single.uri, native);
    expect(
      storeLinks.nativeCalls.single.package,
      StoreConfig.bazaarStorePackage,
    );
    expect(storeLinks.urlCalls, [web]);
  });

  testWidgets('other apps uses Myket listing URLs on a Myket config', (
    tester,
  ) async {
    const native = 'myket://developer?id=dev';
    const web = 'https://myket.ir/developer/dev';
    settings = buildSettings(
      storeConfig: withOtherApps(StoreConfig.myket(), native: native, web: web),
    );
    final context = await pumpHost(tester);
    await settings.onOpenOtherApps(context);

    expect(storeLinks.nativeCalls.single.uri, native);
    expect(storeLinks.urlCalls, isEmpty);
  });

  testWidgets('missing other-apps URLs show a toast and do not launch', (
    tester,
  ) async {
    final context = await pumpHost(tester);
    await settings.onOpenOtherApps(context);
    await tester.pump();

    expect(storeLinks.nativeCalls, isEmpty);
    expect(storeLinks.urlCalls, isEmpty);
    expect(find.text(SupportUsContent.otherAppsUnconfigured), findsOneWidget);
    AppToast.dismiss();
    await tester.pump();
  });

  testWidgets('share text includes the Bazaar Keyva URL', (tester) async {
    final context = await pumpHost(tester);
    await settings.onShareApp(context);

    expect(shareSheet.shareCount, 1);
    expect(shareSheet.lastSubject, SupportUsContent.shareSubject);
    expect(
      shareSheet.lastText,
      SupportUsContent.shareText(StoreConfig.bazaar().keyvaStoreUrl),
    );
    expect(shareSheet.lastText, contains('Keyva'));
    expect(shareSheet.lastText, contains(StoreConfig.bazaar().keyvaStoreUrl));
    expect(shareSheet.lastText, isNot(contains('myket.ir')));
  });

  testWidgets('share text includes the Myket Keyva URL', (tester) async {
    settings = buildSettings(storeConfig: StoreConfig.myket());
    final context = await pumpHost(tester);
    await settings.onShareApp(context);

    expect(
      shareSheet.lastText,
      SupportUsContent.shareText(StoreConfig.myket().keyvaStoreUrl),
    );
    expect(shareSheet.lastText, contains(StoreConfig.myket().keyvaStoreUrl));
    expect(shareSheet.lastText, isNot(contains('cafebazaar.ir')));
  });

  testWidgets('share failure shows a friendly toast', (tester) async {
    shareSheet.result = ShareSheetResult.unavailable;
    final context = await pumpHost(tester);
    await settings.onShareApp(context);
    await tester.pump();

    expect(find.text(SupportUsContent.shareUnavailableTitle), findsOneWidget);
    expect(find.text(SupportUsContent.shareUnavailableMessage), findsOneWidget);
    AppToast.dismiss();
    await tester.pump();
  });

  testWidgets('Support Us rows use store-agnostic titles', (tester) async {
    await pumpSettings(tester);

    expect(find.text(SupportUsContent.rateTitle), findsOneWidget);
    expect(find.text(SupportUsContent.otherAppsTitle), findsOneWidget);
    expect(find.text(SupportUsContent.shareTitle), findsOneWidget);
    expect(find.text('https://cafebazaar.ir'), findsNothing);
    expect(find.text('https://myket.ir'), findsNothing);
  });

  test('settings UI source does not hard-code store URLs', () {
    const needles = ['cafebazaar.ir', 'myket.ir', 'bazaar://', 'myket://'];
    final files = <File>[
      File('lib/feature/settings/view/settings_view.dart'),
      ...Directory('lib/feature/settings/widget').listSync().whereType<File>(),
    ];

    for (final file in files) {
      if (!file.path.endsWith('.dart')) continue;
      final source = file.readAsStringSync();
      for (final needle in needles) {
        expect(
          source.contains(needle),
          isFalse,
          reason: '${file.path} contains $needle',
        );
      }
    }
  });
}
