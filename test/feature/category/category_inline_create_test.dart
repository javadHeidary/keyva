import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:keyva/core/exceptions/app_failure.dart';
import 'package:keyva/core/routes/app_routing.dart';
import 'package:keyva/feature/category/controller/category_catalog_controller.dart';
import 'package:keyva/feature/category/model/category_constants.dart';
import 'package:keyva/feature/type/login/view/login_create_view.dart';
import 'package:keyva/feature/type/login/viewmodel/login_create_viewmodel.dart';
import 'package:keyva/feature/vault/model/category_item.dart';
import 'package:keyva/feature/vault/model/vault_data.dart';
import 'package:keyva/feature/vault/viewmodel/vault_home_viewmodel.dart';
import 'package:keyva/feature/vault/viewmodel/vault_item_viewmodel.dart';

import '../vault/support/fake_vault_operation_service.dart';
import '../vault/support/vault_widget_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeVaultOperationService operations;
  late VaultItemViewModel items;
  late CategoryCatalogController catalog;
  late VaultHomeViewModel home;
  late LoginCreateViewModel form;

  setUp(() {
    Get.testMode = true;
    operations = FakeVaultOperationService()
      ..vault = VaultData(
        version: VaultData.currentVersion,
        logins: const [],
        bankCards: const [],
        secureNotes: const [],
        categories: const [],
      );
    items = VaultItemViewModel(operations: operations);
    catalog = CategoryCatalogController();
    home = VaultHomeViewModel(operations: operations);
    Get.put(items);
    Get.put(catalog, permanent: true);
    Get.put(home);
    form = LoginCreateViewModel(items: items);
    Get.put(form);
  });

  tearDown(Get.reset);

  Future<void> pumpCreate(WidgetTester tester) async {
    setupVaultWidgetSurface(tester);
    await home.loadVault();
    await tester.pumpWidget(
      vaultTestApp(
        home: const LoginCreateView(),
        initialRoute: AppRoutes.loginCreate,
        getPages: [
          GetPage(
            name: AppRoutes.home,
            page: () => const Scaffold(key: Key('home-root')),
          ),
          GetPage(
            name: AppRoutes.loginCreate,
            page: () => const LoginCreateView(),
          ),
        ],
      ),
    );
    await pumpVaultFrame(tester);
  }

  test('createInlineCategory persists, trims, and selects the new category', () async {
    await home.loadVault();

    final error = await form.createInlineCategory('  پروژه  ');

    expect(error, isNull);
    expect(operations.addCount, 1);
    expect(operations.lastAdded, isA<CategoryItem>());
    final added = operations.lastAdded! as CategoryItem;
    expect(added.name, 'پروژه');
    expect(added.icon, 'folder');
    expect(form.selectedCategoryId.value, added.id);
    expect(catalog.categories.single.id, added.id);
    expect(catalog.categories.single.name, 'پروژه');
  });

  test('createInlineCategory rejects empty, duplicate, and oversized names', () async {
    operations.vault = VaultData(
      version: VaultData.currentVersion,
      logins: const [],
      bankCards: const [],
      secureNotes: const [],
      categories: [
        CategoryItem(
          id: 'cat-work',
          name: 'کاری',
          icon: 'work',
          createdAt: DateTime.utc(2026, 1, 1),
        ),
      ],
    );
    await home.loadVault();

    expect(
      await form.createInlineCategory('   '),
      CategoryConstants.emptyNameMessage,
    );
    expect(
      await form.createInlineCategory('کاری'),
      CategoryConstants.duplicateNameMessage,
    );
    expect(
      await form.createInlineCategory('abcdefghijk'),
      CategoryConstants.tooLongNameMessage,
    );
    expect(operations.addCount, 0);
    expect(form.selectedCategoryId.value, isNull);
  });

  test('createInlineCategory keeps the selection unchanged on persist failure', () async {
    operations.addFailure = const CryptoFailure();
    await home.loadVault();

    final error = await form.createInlineCategory('پروژه');

    expect(error, 'عملیات امنیتی انجام نشد.');
    expect(form.selectedCategoryId.value, isNull);
    expect(catalog.categories, isEmpty);
  });

  testWidgets('inline create stays on the item form and selects the new category', (
    tester,
  ) async {
    await pumpCreate(tester);

    await tester.tap(find.byKey(const Key('category-inline-add')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('category-inline-name')), 'پروژه');
    await tester.tap(find.byKey(const Key('category-inline-submit')));
    await pumpVaultFrame(tester);
    await tester.pumpAndSettle();

    expect(find.text('ایجاد ورود'), findsWidgets);
    expect(operations.lastAdded, isA<CategoryItem>());
    expect((operations.lastAdded! as CategoryItem).name, 'پروژه');
    expect(form.selectedCategoryId.value, isNotNull);
    expect(find.text('پروژه'), findsWidgets);
  });

  testWidgets('cancel closes the dialog without persisting', (tester) async {
    await pumpCreate(tester);

    await tester.tap(find.byKey(const Key('category-inline-add')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('category-inline-name')), 'پروژه');
    await tester.tap(find.byKey(const Key('category-inline-cancel')));
    await tester.pumpAndSettle();

    expect(operations.addCount, 0);
    expect(form.selectedCategoryId.value, isNull);
    expect(find.byKey(const Key('category-inline-name')), findsNothing);
    expect(find.text('ایجاد ورود'), findsWidgets);
  });
}
