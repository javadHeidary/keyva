import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:keyva/core/routes/app_routing.dart';
import 'package:keyva/feature/category/controller/category_catalog_controller.dart';
import 'package:keyva/feature/category/model/category_constants.dart';
import 'package:keyva/feature/category/view/category_create_view.dart';
import 'package:keyva/feature/category/viewmodel/category_form_viewmodel.dart';
import 'package:keyva/feature/category/viewmodel/category_list_viewmodel.dart';
import 'package:keyva/feature/home/view/home_view.dart';
import 'package:keyva/feature/home/viewmodel/home_viewmodel.dart';
import 'package:keyva/feature/type/login/viewmodel/login_create_viewmodel.dart';
import 'package:keyva/feature/type/login/viewmodel/login_details_viewmodel.dart';
import 'package:keyva/feature/vault/model/category_item.dart';
import 'package:keyva/feature/vault/model/login_item.dart';
import 'package:keyva/feature/vault/model/vault_data.dart';
import 'package:keyva/feature/vault/view/vault_list_item_mapper.dart';
import 'package:keyva/feature/vault/viewmodel/vault_home_viewmodel.dart';
import 'package:keyva/feature/vault/viewmodel/vault_item_viewmodel.dart';

import '../vault/support/fake_vault_operation_service.dart';
import '../vault/support/vault_widget_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeVaultOperationService operations;
  late VaultHomeViewModel vaultHome;
  late VaultItemViewModel items;
  late CategoryCatalogController catalog;
  late HomeController home;

  final createdAt = DateTime.utc(2026, 8, 1, 10);
  final updatedAt = DateTime.utc(2026, 8, 2, 11);

  CategoryItem workCategory() {
    return CategoryItem(
      id: 'cat-work',
      name: 'Work',
      icon: 'work',
      createdAt: createdAt,
    );
  }

  LoginItem login({String? categoryId}) {
    return LoginItem(
      id: 'login-1',
      title: 'Mail',
      username: 'keep-this-user',
      password: 'keep-this-password',
      website: 'https://mail.test',
      notes: null,
      categoryId: categoryId,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  VaultData vaultData({
    List<LoginItem> logins = const [],
    List<CategoryItem> categories = const [],
  }) {
    return VaultData(
      version: VaultData.currentVersion,
      logins: logins,
      bankCards: const [],
      secureNotes: const [],
      categories: categories,
    );
  }

  void registerStack() {
    Get.testMode = true;
    operations = FakeVaultOperationService()..vault = vaultData();
    vaultHome = VaultHomeViewModel(operations: operations);
    items = VaultItemViewModel(operations: operations);
    catalog = CategoryCatalogController();
    home = HomeController(vault: vaultHome);
    Get.put(vaultHome);
    Get.put(items);
    Get.put(catalog, permanent: true);
    Get.put(home);
  }

  setUp(registerStack);

  tearDown(Get.reset);

  test(
    'persisted vault with no categories does not backfill defaults into the catalog',
    () async {
      await vaultHome.loadVault();

      expect(catalog.categories, isEmpty);
      expect(
        home.filterCategories.map((category) => category.id),
        [CategoryConstants.filterAllId],
      );
      expect(home.filterCategories.single.name, CategoryConstants.filterAllName);
    },
  );

  test('loadVault hydrates default categories from an initial vault', () async {
    operations.vault = VaultData.initial();

    await vaultHome.loadVault();

    expect(
      catalog.categories.map((category) => category.name),
      ['شخصی', 'کاری', 'مالی'],
    );
    expect(
      home.filterCategories.map((category) => category.name),
      [CategoryConstants.filterAllName, 'شخصی', 'کاری', 'مالی'],
    );
  });

  test('loadVault hydrates the catalog from VaultData.categories', () async {
    operations.vault = vaultData(categories: [workCategory()]);

    await vaultHome.loadVault();

    expect(catalog.categories.map((category) => category.id), ['cat-work']);
    expect(catalog.categories.single.name, 'Work');
    expect(catalog.categories.single.iconId, 'work');
    expect(
      home.filterCategories.map((category) => category.id),
      [CategoryConstants.filterAllId, 'cat-work'],
    );
  });

  testWidgets('create form persists a CategoryItem through the vault pipeline', (
    tester,
  ) async {
    await vaultHome.loadVault();
    Get.put(
      CategoryFormViewModel(mode: CategoryFormMode.create, items: items),
    );

    setupVaultWidgetSurface(tester);
    await tester.pumpWidget(
      vaultTestApp(
        home: const SizedBox.shrink(),
        initialRoute: AppRoutes.categoryCreate,
        getPages: [
          GetPage(
            name: AppRoutes.home,
            page: () => const Scaffold(key: Key('home-root')),
          ),
          GetPage(
            name: AppRoutes.categoryCreate,
            page: () => const CategoryCreateView(),
          ),
        ],
      ),
    );
    await pumpVaultFrame(tester);

    await tester.enterText(find.byType(TextFormField), 'Projects');
    await tester.tap(find.byKey(const Key('vault-form-submit')));
    await tester.pump();
    await pumpVaultFrame(tester);

    final added = operations.lastAdded;
    expect(added, isA<CategoryItem>());
    final category = added! as CategoryItem;
    expect(category.name, 'Projects');
    expect(category.icon, isNotEmpty);
    expect(operations.vault!.categories.single.name, 'Projects');
    expect(catalog.categories.single.name, 'Projects');
    expect(catalog.categories.single.id, category.id);
  });

  testWidgets('update and delete go through vault operations', (tester) async {
    operations.vault = vaultData(categories: [workCategory()]);
    await vaultHome.loadVault();

    setupVaultWidgetSurface(tester);
    await tester.pumpWidget(vaultTestApp(home: const Scaffold()));
    await pumpVaultFrame(tester);

    final form = CategoryFormViewModel(
      mode: CategoryFormMode.edit,
      items: items,
      categoryId: 'cat-work',
    );
    form.onInit();
    form.nameController.text = 'Office';
    form.selectIcon('business');
    await form.submit();

    final updated = operations.lastUpdated;
    expect(updated, isA<CategoryItem>());
    final updatedCategory = updated! as CategoryItem;
    expect(updatedCategory.id, 'cat-work');
    expect(updatedCategory.name, 'Office');
    expect(updatedCategory.createdAt, createdAt);
    expect(operations.vault!.categories.single.name, 'Office');
    expect(catalog.categories.single.name, 'Office');

    Get.put(CategoryListViewModel());
    await Get.find<CategoryListViewModel>().deleteCategory('cat-work');

    expect(operations.lastDeletedId, 'cat-work');
    expect(operations.vault!.categories, isEmpty);
    expect(catalog.categories, isEmpty);
  });

  test(
    'simulated restart hydrates persisted categories, not constructor seeds',
    () async {
      operations.vault = vaultData(categories: [workCategory()]);
      await vaultHome.loadVault();
      expect(catalog.categories, isNotEmpty);

      Get.reset();
      Get.testMode = true;
      final restartedCatalog = CategoryCatalogController();
      expect(restartedCatalog.categories, isEmpty);

      final restartedHome = VaultHomeViewModel(operations: operations);
      Get.put(restartedCatalog, permanent: true);
      Get.put(restartedHome);
      await restartedHome.loadVault();

      expect(restartedCatalog.categories.map((category) => category.id), [
        'cat-work',
      ]);
      expect(restartedCatalog.categories.single.name, 'Work');
    },
  );

  test(
    'login form selectable categories come from persisted vault data',
    () async {
      operations.vault = vaultData(categories: [workCategory()]);
      await vaultHome.loadVault();

      final loginForm = LoginCreateViewModel(items: items);

      expect(loginForm.selectableCategories.map((category) => category.id), [
        'cat-work',
      ]);
      expect(loginForm.selectableCategories.single.name, 'Work');
    },
  );

  test(
    'login form selectable categories include defaults from an initial vault',
    () async {
      operations.vault = VaultData.initial();
      await vaultHome.loadVault();

      final loginForm = LoginCreateViewModel(items: items);

      expect(
        loginForm.selectableCategories.map((category) => category.name),
        ['شخصی', 'کاری', 'مالی'],
      );
    },
  );

  test(
    'details label resolves after reload when categoryId matches vault',
    () async {
      operations.vault = vaultData(
        logins: [login(categoryId: 'cat-work')],
        categories: [workCategory()],
      );
      await vaultHome.loadVault();

      final details = LoginDetailsViewModel(loginId: 'login-1');
      expect(details.categoryLabel, 'Work');
      expect(vaultCategoryLabel(operations.vault, 'cat-work'), 'Work');
    },
  );

  test(
    'restore payload categories appear in the catalog after refresh',
    () async {
      await vaultHome.loadVault();
      expect(catalog.categories, isEmpty);

      operations.vault = vaultData(categories: [workCategory()]);
      await vaultHome.refreshVault();

      expect(catalog.categories.map((category) => category.name), ['Work']);
      expect(
        home.filterCategories.map((category) => category.id),
        [CategoryConstants.filterAllId, 'cat-work'],
      );
    },
  );

  testWidgets('Home chips show default categories after loading an initial vault', (
    tester,
  ) async {
    operations.vault = VaultData.initial();
    await vaultHome.loadVault();

    setupVaultWidgetSurface(tester);
    await tester.pumpWidget(vaultTestApp(home: const HomeView()));
    await pumpVaultFrame(tester);

    expect(find.text(CategoryConstants.filterAllName), findsOneWidget);
    expect(find.text('شخصی'), findsOneWidget);
    expect(find.text('کاری'), findsOneWidget);
    expect(find.text('مالی'), findsOneWidget);
  });

  testWidgets('Home chips show persisted categories after load', (tester) async {
    operations.vault = vaultData(categories: [workCategory()]);
    await vaultHome.loadVault();

    setupVaultWidgetSurface(tester);
    await tester.pumpWidget(vaultTestApp(home: const HomeView()));
    await pumpVaultFrame(tester);

    expect(find.text(CategoryConstants.filterAllName), findsOneWidget);
    expect(find.text('Work'), findsOneWidget);
  });
}
