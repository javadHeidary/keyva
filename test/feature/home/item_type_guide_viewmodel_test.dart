import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:keyva/core/exceptions/app_failure.dart';
import 'package:keyva/core/routes/app_routing.dart';
import 'package:keyva/feature/home/model/item_type_guide_status.dart';
import 'package:keyva/feature/home/model/vault_models.dart';
import 'package:keyva/feature/home/viewmodel/home_viewmodel.dart';
import 'package:keyva/feature/vault/model/login_item.dart';
import 'package:keyva/feature/vault/model/vault_data.dart';
import 'package:keyva/feature/vault/viewmodel/vault_home_viewmodel.dart';
import 'package:keyva/shared/widget/toast_widget.dart';

import '../settings/support/fake_settings_repository.dart';
import '../vault/support/fake_vault_operation_service.dart';
import '../vault/support/vault_widget_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeVaultOperationService operations;
  late VaultHomeViewModel vault;
  late FakeSettingsRepository settings;
  late HomeController home;

  VaultData emptyVault() {
    return VaultData(
      version: VaultData.currentVersion,
      logins: const [],
      bankCards: const [],
      secureNotes: const [],
      categories: const [],
    );
  }

  Future<BuildContext> pumpHost(WidgetTester tester) async {
    setupVaultWidgetSurface(tester);
    operations.vault = emptyVault();
    await home.loadVault();
    await home.loadTypeGuideStatuses();
    await tester.pumpWidget(
      vaultTestApp(
        home: const Scaffold(body: Text('guide-host')),
        initialRoute: AppRoutes.home,
        getPages: [
          GetPage(
            name: AppRoutes.home,
            page: () => const Scaffold(body: Text('guide-host')),
          ),
          GetPage(
            name: AppRoutes.typeList,
            page: () => const Scaffold(
              key: Key('type-list'),
              body: Text('type-list'),
            ),
          ),
          GetPage(
            name: AppRoutes.loginDetails,
            page: () => const Scaffold(
              key: Key('login-details'),
              body: Text('login-details'),
            ),
          ),
        ],
      ),
    );
    await pumpVaultFrame(tester);
    return tester.element(find.text('guide-host'));
  }

  setUp(() {
    Get.testMode = true;
    operations = FakeVaultOperationService();
    vault = VaultHomeViewModel(operations: operations);
    settings = FakeSettingsRepository();
    home = HomeController(vault: vault, settings: settings);
    Get.put(vault);
    Get.put(home);
  });

  tearDown(() {
    AppToast.dismiss();
    Get.reset();
  });

  testWidgets('guide visibility is independent per item type', (tester) async {
    final context = await pumpHost(tester);

    expect(home.isTypeGuideVisible(VaultItemType.login), isTrue);
    expect(home.isTypeGuideVisible(VaultItemType.bankCard), isTrue);

    await home.dismissTypeGuide(
      context,
      VaultItemType.login,
      ItemTypeGuideStatus.dismissed,
    );

    expect(home.isTypeGuideVisible(VaultItemType.login), isFalse);
    expect(home.isTypeGuideVisible(VaultItemType.bankCard), isTrue);
    expect(home.isTypeGuideVisible(VaultItemType.secureNote), isTrue);
    expect(settings.itemTypeGuideStatuses['login'], 'dismissed');
  });

  testWidgets('got it and dont show again persist different statuses', (
    tester,
  ) async {
    final context = await pumpHost(tester);

    await home.dismissTypeGuide(
      context,
      VaultItemType.login,
      ItemTypeGuideStatus.acknowledged,
    );
    await home.dismissTypeGuide(
      context,
      VaultItemType.bankCard,
      ItemTypeGuideStatus.dismissed,
    );

    expect(settings.itemTypeGuideStatuses['login'], 'acknowledged');
    expect(settings.itemTypeGuideStatuses['bankCard'], 'dismissed');
    expect(home.isTypeGuideVisible(VaultItemType.login), isFalse);
    expect(home.isTypeGuideVisible(VaultItemType.bankCard), isFalse);
    expect(
      home.typeGuideStatus(VaultItemType.login),
      ItemTypeGuideStatus.acknowledged,
    );
    expect(
      home.typeGuideStatus(VaultItemType.bankCard),
      ItemTypeGuideStatus.dismissed,
    );
  });

  testWidgets('create sample saves, hides the icon, and opens the type list', (
    tester,
  ) async {
    final context = await pumpHost(tester);

    await home.createTypeGuideSample(context, VaultItemType.login);
    await pumpVaultFrame(tester);

    expect(operations.addCount, 1);
    expect(operations.lastAdded, isA<LoginItem>());
    expect(settings.itemTypeGuideStatuses['login'], 'sampleCreated');
    expect(home.isTypeGuideVisible(VaultItemType.login), isFalse);
    expect(Get.currentRoute, AppRoutes.typeList);
    expect(Get.arguments, VaultItemType.login);
    expect(find.byKey(const Key('type-list')), findsOneWidget);
    expect(find.byKey(const Key('login-details')), findsNothing);
  });

  for (final type in const [
    VaultItemType.bankCard,
    VaultItemType.secureNote,
  ]) {
    testWidgets(
      'create ${type.name} sample opens that type list without details',
      (tester) async {
        final context = await pumpHost(tester);
        await home.createTypeGuideSample(context, type);
        await pumpVaultFrame(tester);

        expect(operations.addCount, 1);
        expect(settings.itemTypeGuideStatuses[type.name], 'sampleCreated');
        expect(Get.currentRoute, AppRoutes.typeList);
        expect(Get.arguments, type);
        expect(find.byKey(const Key('login-details')), findsNothing);
      },
    );
  }

  testWidgets('image type does not create a sample or navigate', (tester) async {
    final context = await pumpHost(tester);

    await home.createTypeGuideSample(context, VaultItemType.image);
    await pumpVaultFrame(tester);

    expect(operations.addCount, 0);
    expect(home.isTypeGuideVisible(VaultItemType.image), isTrue);
    expect(settings.itemTypeGuideStatuses.containsKey('image'), isFalse);
    expect(Get.currentRoute, AppRoutes.home);
  });

  testWidgets('failed sample creation keeps the info icon visible', (
    tester,
  ) async {
    operations.addFailure = const DatabaseFailure();
    final context = await pumpHost(tester);

    await home.createTypeGuideSample(context, VaultItemType.login);
    await pumpVaultFrame(tester);
    AppToast.dismiss();

    expect(operations.addCount, 1);
    expect(home.isTypeGuideVisible(VaultItemType.login), isTrue);
    expect(settings.itemTypeGuideStatuses.containsKey('login'), isFalse);
    expect(Get.currentRoute, AppRoutes.home);
  });

  testWidgets('persist failure after create does not navigate or hide info', (
    tester,
  ) async {
    settings.saveItemTypeGuideShouldFail = true;
    final context = await pumpHost(tester);

    await home.createTypeGuideSample(context, VaultItemType.login);
    await pumpVaultFrame(tester);
    AppToast.dismiss();

    expect(operations.addCount, 1);
    expect(home.isTypeGuideVisible(VaultItemType.login), isTrue);
    expect(Get.currentRoute, AppRoutes.home);
    expect(find.byKey(const Key('login-details')), findsNothing);
    expect(find.byKey(const Key('type-list')), findsNothing);
  });

  testWidgets('persist failure on dismiss keeps the info icon', (tester) async {
    settings.saveItemTypeGuideShouldFail = true;
    final context = await pumpHost(tester);

    await home.dismissTypeGuide(
      context,
      VaultItemType.login,
      ItemTypeGuideStatus.dismissed,
    );
    AppToast.dismiss();

    expect(home.isTypeGuideVisible(VaultItemType.login), isTrue);
    expect(settings.itemTypeGuideStatuses, isEmpty);
  });

  testWidgets('rapid overlapping create taps add only one sample', (
    tester,
  ) async {
    operations.addGate = Completer<void>();
    final context = await pumpHost(tester);

    final first = home.createTypeGuideSample(context, VaultItemType.login);
    final second = home.createTypeGuideSample(context, VaultItemType.login);
    operations.addGate!.complete();
    await first;
    await second;
    await pumpVaultFrame(tester);

    expect(operations.addCount, 1);
  });
}
