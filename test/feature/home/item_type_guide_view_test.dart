import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:keyva/core/routes/app_routing.dart';
import 'package:keyva/feature/home/model/item_type_guide_status.dart';
import 'package:keyva/feature/home/model/item_type_sample_factory.dart';
import 'package:keyva/feature/home/model/vault_models.dart';
import 'package:keyva/feature/home/view/home_view.dart';
import 'package:keyva/feature/home/view/type_list_item_view.dart';
import 'package:keyva/feature/home/viewmodel/home_viewmodel.dart';
import 'package:keyva/feature/vault/model/vault_data.dart';
import 'package:keyva/feature/vault/viewmodel/vault_home_viewmodel.dart';
import 'package:keyva/shared/icons/app_icons.dart';
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

  Future<void> pumpHome(WidgetTester tester) async {
    setupVaultWidgetSurface(tester);
    operations.vault = emptyVault();
    await home.loadVault();
    await home.loadTypeGuideStatuses();
    await tester.pumpWidget(
      vaultTestApp(
        home: const HomeView(),
        initialRoute: AppRoutes.home,
        getPages: [
          GetPage(name: AppRoutes.home, page: () => const HomeView()),
          GetPage(
            name: AppRoutes.typeList,
            page: () => TypeListItemView(),
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

  testWidgets('shows an info icon for every item type by default', (
    tester,
  ) async {
    await pumpHome(tester);

    expect(find.byKey(const Key('item-type-guide-info-login')), findsOneWidget);
    expect(
      find.byKey(const Key('item-type-guide-info-bankCard')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('item-type-guide-info-secureNote')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('item-type-guide-info-image')), findsOneWidget);
    expect(find.byIcon(AppIcon.chevronRight), findsNWidgets(4));
  });

  testWidgets('tapping login info opens the login guide dialog', (
    tester,
  ) async {
    await pumpHome(tester);

    await tester.tap(find.byKey(const Key('item-type-guide-info-login')));
    await tester.pumpAndSettle();

    expect(find.text('اکانت چیست؟'), findsOneWidget);
    expect(find.textContaining('حساب جیمیل'), findsOneWidget);
    expect(find.text('ساخت نمونه'), findsOneWidget);
    expect(find.text('دیگر نشان نده'), findsOneWidget);
    expect(find.text('متوجه شدم'), findsOneWidget);
    expect(find.byKey(const Key('vault-type-list')), findsNothing);
  });

  testWidgets('dont show again hides only that type info icon', (tester) async {
    await pumpHome(tester);

    await tester.tap(find.byKey(const Key('item-type-guide-info-login')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('item-type-guide-dont-show-again')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('item-type-guide-info-login')), findsNothing);
    expect(
      find.byKey(const Key('item-type-guide-info-bankCard')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('item-type-guide-info-secureNote')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('item-type-guide-info-image')), findsOneWidget);
    expect(settings.itemTypeGuideStatuses['login'], 'dismissed');
  });

  testWidgets('got it hides the info icon without creating an item', (
    tester,
  ) async {
    await pumpHome(tester);

    await tester.tap(find.byKey(const Key('item-type-guide-info-login')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('item-type-guide-got-it')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('item-type-guide-info-login')), findsNothing);
    expect(operations.addCount, 0);
    expect(settings.itemTypeGuideStatuses['login'], 'acknowledged');
  });

  testWidgets('dismissing the dialog without an action keeps the info icon', (
    tester,
  ) async {
    await pumpHome(tester);

    await tester.tap(find.byKey(const Key('item-type-guide-info-login')));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(8, 8));
    await tester.pumpAndSettle();

    expect(find.text('اکانت چیست؟'), findsNothing);
    expect(find.byKey(const Key('item-type-guide-info-login')), findsOneWidget);
    expect(settings.itemTypeGuideStatuses.containsKey('login'), isFalse);
  });

  testWidgets('create a sample from the dialog opens that type list', (
    tester,
  ) async {
    await pumpHome(tester);

    await tester.tap(find.byKey(const Key('item-type-guide-info-login')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('item-type-guide-create-sample')));
    await tester.pumpAndSettle();

    expect(operations.addCount, 1);
    expect(home.isTypeGuideVisible(VaultItemType.login), isFalse);
    expect(Get.currentRoute, AppRoutes.typeList);
    expect(Get.arguments, VaultItemType.login);
    expect(find.byKey(const Key('vault-type-list')), findsOneWidget);
    expect(find.text(ItemTypeSampleFactory.loginTitle), findsOneWidget);
    expect(find.byKey(const Key('login-details')), findsNothing);

    await tester.tap(find.text(ItemTypeSampleFactory.loginTitle));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('login-details')), findsOneWidget);
  });

  for (final setup in [
    (
      type: VaultItemType.bankCard,
      infoKey: 'item-type-guide-info-bankCard',
      title: ItemTypeSampleFactory.bankCardTitle,
    ),
    (
      type: VaultItemType.secureNote,
      infoKey: 'item-type-guide-info-secureNote',
      title: ItemTypeSampleFactory.noteTitle,
    ),
  ]) {
    testWidgets(
      'create a ${setup.type.name} sample opens that type list',
      (tester) async {
        await pumpHome(tester);

        await tester.tap(find.byKey(Key(setup.infoKey)));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('item-type-guide-create-sample')));
        await tester.pumpAndSettle();

        expect(operations.addCount, 1);
        expect(home.isTypeGuideVisible(setup.type), isFalse);
        expect(Get.currentRoute, AppRoutes.typeList);
        expect(Get.arguments, setup.type);
        expect(find.byKey(const Key('vault-type-list')), findsOneWidget);
        expect(find.text(setup.title), findsOneWidget);
        expect(find.byKey(const Key('login-details')), findsNothing);
      },
    );
  }

  testWidgets('image guide explains the type without a sample action', (
    tester,
  ) async {
    await pumpHome(tester);

    await tester.tap(find.byKey(const Key('item-type-guide-info-image')));
    await tester.pumpAndSettle();

    expect(find.text('پوشه تصاویر چیست؟'), findsOneWidget);
    expect(find.textContaining('پوشه'), findsWidgets);
    expect(find.text('ساخت نمونه'), findsNothing);
    expect(find.text('متوجه شدم'), findsOneWidget);
    expect(find.text('دیگر نشان نده'), findsOneWidget);

    await tester.tap(find.byKey(const Key('item-type-guide-got-it')));
    await tester.pumpAndSettle();

    expect(operations.addCount, 0);
    expect(find.byKey(const Key('item-type-guide-info-image')), findsNothing);
    expect(settings.itemTypeGuideStatuses['image'], 'acknowledged');
    expect(Get.currentRoute, AppRoutes.home);
  });

  testWidgets('previously dismissed types do not show the info icon', (
    tester,
  ) async {
    settings.itemTypeGuideStatuses[VaultItemType.login.name] =
        ItemTypeGuideStatus.dismissed.name;
    await pumpHome(tester);

    expect(find.byKey(const Key('item-type-guide-info-login')), findsNothing);
    expect(
      find.byKey(const Key('item-type-guide-info-bankCard')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('item-type-guide-info-image')), findsOneWidget);
  });
}
