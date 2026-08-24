import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:keyva/core/routes/app_routing.dart';
import 'package:keyva/feature/category/controller/category_catalog_controller.dart';
import 'package:keyva/feature/category/model/category_constants.dart';
import 'package:keyva/feature/category/model/category_defaults.dart';
import 'package:keyva/feature/category/view/category_items_view.dart';
import 'package:keyva/feature/category/view/category_list_view.dart';
import 'package:keyva/feature/category/viewmodel/category_list_viewmodel.dart';
import 'package:keyva/feature/home/viewmodel/home_viewmodel.dart';
import 'package:keyva/feature/type/bank_card/view/bank_card_details_view.dart';
import 'package:keyva/feature/type/bank_card/viewmodel/bank_card_details_viewmodel.dart';
import 'package:keyva/feature/type/login/view/login_create_view.dart';
import 'package:keyva/feature/type/login/view/login_details_view.dart';
import 'package:keyva/feature/type/login/viewmodel/login_create_viewmodel.dart';
import 'package:keyva/feature/type/login/viewmodel/login_details_viewmodel.dart';
import 'package:keyva/feature/type/note/view/note_details_view.dart';
import 'package:keyva/feature/type/note/viewmodel/note_details_viewmodel.dart';
import 'package:keyva/feature/vault/model/bank_card_item.dart';
import 'package:keyva/feature/vault/model/login_item.dart';
import 'package:keyva/feature/vault/model/secure_note_item.dart';
import 'package:keyva/feature/vault/model/vault_data.dart';
import 'package:keyva/feature/vault/view/vault_item_navigation.dart';
import 'package:keyva/feature/vault/viewmodel/vault_home_viewmodel.dart';
import 'package:keyva/feature/vault/viewmodel/vault_item_viewmodel.dart';
import 'package:keyva/shared/icons/app_icons.dart';
import 'package:keyva/shared/widget/app_buttom_widget.dart';
import 'package:keyva/shared/widget/app_empty_widget.dart';
import 'package:keyva/shared/widget/toast_widget.dart';

import '../vault/support/fake_share_sheet_service.dart';
import '../vault/support/fake_vault_operation_service.dart';
import '../vault/support/vault_widget_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeVaultOperationService operations;
  late VaultHomeViewModel vault;
  late VaultItemViewModel items;
  late CategoryCatalogController catalog;
  late HomeController home;
  late CategoryListViewModel categories;

  final createdAt = DateTime.utc(2026, 8, 1, 10);
  final updatedAt = DateTime.utc(2026, 8, 2, 11);

  LoginItem login({
    String id = 'login-work',
    String title = 'Login A',
    String? categoryId,
    bool isPinned = false,
  }) {
    return LoginItem(
      id: id,
      title: title,
      username: 'keep-this-user',
      password: 'keep-this-password',
      website: 'https://mail.test',
      notes: null,
      categoryId: categoryId,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isPinned: isPinned,
    );
  }

  BankCardItem card({
    String id = 'card-a',
    String title = 'Bank Card A',
    String? categoryId,
    bool isPinned = false,
  }) {
    return BankCardItem(
      id: id,
      title: title,
      cardNumber: '6219861234567890',
      cardHolder: 'Nima Karimi',
      expiryDate: '06/30',
      cvv: '321',
      bankName: 'Saman',
      notes: null,
      categoryId: categoryId,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isPinned: isPinned,
    );
  }

  SecureNoteItem note({
    String id = 'note-personal',
    String title = 'Note A',
    String? categoryId,
  }) {
    return SecureNoteItem(
      id: id,
      title: title,
      content: 'private-note',
      categoryId: categoryId,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  VaultData mixedVault() {
    return VaultData(
      version: VaultData.currentVersion,
      logins: [login(categoryId: CategoryDefaults.workId)],
      bankCards: [
        card(categoryId: CategoryDefaults.financeId),
        card(
          id: 'card-b',
          title: 'Bank Card B',
          categoryId: CategoryDefaults.financeId,
        ),
      ],
      secureNotes: [note(categoryId: CategoryDefaults.personalId)],
      categories: CategoryDefaults.items,
    );
  }

  void ensureControllers() {
    if (!Get.isRegistered<VaultHomeViewModel>()) {
      Get.put(vault, permanent: true);
    }
    if (!Get.isRegistered<VaultItemViewModel>()) {
      Get.put(items, permanent: true);
    }
    if (!Get.isRegistered<CategoryCatalogController>()) {
      Get.put(catalog, permanent: true);
    }
    if (!Get.isRegistered<HomeController>()) {
      Get.put(home, permanent: true);
    }
    if (!Get.isRegistered<CategoryListViewModel>()) {
      Get.put(categories, permanent: true);
    }
  }

  List<GetPage> appPages() {
    return [
      GetPage(
        name: AppRoutes.shell,
        page: () => const CategoryListView(),
        binding: BindingsBuilder(ensureControllers),
      ),
      GetPage(
        name: AppRoutes.categoryItems,
        page: () => CategoryItemsView(),
        binding: BindingsBuilder(ensureControllers),
      ),
      GetPage(
        name: AppRoutes.loginCreate,
        page: () => const LoginCreateView(),
        binding: BindingsBuilder(() {
          ensureControllers();
          Get.lazyPut(() => LoginCreateViewModel(items: items), fenix: true);
        }),
      ),
      GetPage(
        name: AppRoutes.loginDetails,
        page: () => const LoginDetailsView(),
        binding: BindingsBuilder(() {
          ensureControllers();
          if (Get.isRegistered<LoginDetailsViewModel>()) {
            Get.delete<LoginDetailsViewModel>(force: true);
          }
          Get.put(
            LoginDetailsViewModel(
              loginId: vaultRouteItemId(),
              shareSheet: FakeShareSheetService(),
            ),
          );
        }),
      ),
      GetPage(
        name: AppRoutes.bankCardDetails,
        page: () => const BankCardDetailsView(),
        binding: BindingsBuilder(() {
          ensureControllers();
          if (Get.isRegistered<BankCardDetailsViewModel>()) {
            Get.delete<BankCardDetailsViewModel>(force: true);
          }
          Get.put(
            BankCardDetailsViewModel(
              cardId: vaultRouteItemId(),
              shareSheet: FakeShareSheetService(),
            ),
          );
        }),
      ),
      GetPage(
        name: AppRoutes.noteDetails,
        page: () => const NoteDetailsView(),
        binding: BindingsBuilder(() {
          ensureControllers();
          if (Get.isRegistered<NoteDetailsViewModel>()) {
            Get.delete<NoteDetailsViewModel>(force: true);
          }
          Get.put(
            NoteDetailsViewModel(
              noteId: vaultRouteItemId(),
              shareSheet: FakeShareSheetService(),
            ),
          );
        }),
      ),
    ];
  }

  Future<void> pumpCategories(WidgetTester tester) async {
    setupVaultWidgetSurface(tester);
    await home.loadVault();
    await tester.pumpWidget(
      vaultTestApp(
        home: const CategoryListView(),
        initialRoute: AppRoutes.shell,
        getPages: appPages(),
      ),
    );
    await pumpVaultFrame(tester);
  }

  Future<void> pumpOpenedRoute(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump();
  }

  Future<void> openCategory(
    WidgetTester tester, {
    String id = CategoryDefaults.financeId,
  }) async {
    await tester.tap(find.byKey(Key('category-card-$id')));
    await pumpOpenedRoute(tester);
  }

  Future<void> popOpenedRoute(WidgetTester tester) async {
    final navigator = tester.state<NavigatorState>(find.byType(Navigator).first);
    expect(navigator.canPop(), isTrue);
    navigator.pop();
    await pumpOpenedRoute(tester);
  }

  setUp(() {
    Get.testMode = true;
    operations = FakeVaultOperationService();
    vault = VaultHomeViewModel(operations: operations);
    items = VaultItemViewModel(operations: operations);
    catalog = CategoryCatalogController();
    home = HomeController(vault: vault);
    categories = CategoryListViewModel();
    Get.put(vault, permanent: true);
    Get.put(items, permanent: true);
    Get.put(catalog, permanent: true);
    Get.put(home, permanent: true);
    Get.put(categories, permanent: true);
  });

  tearDown(Get.reset);

  test('itemsForCategory filters the in-memory vault list by categoryId', () async {
    operations.vault = mixedVault();
    await home.loadVault();

    final finance = home.itemsForCategory(CategoryDefaults.financeId);
    expect(finance.map((item) => item.id), ['card-a', 'card-b']);

    final work = home.itemsForCategory(CategoryDefaults.workId);
    expect(work.map((item) => item.id), ['login-work']);

    expect(home.itemsForCategory(CategoryDefaults.personalId).single.id, 'note-personal');
    expect(home.selectedCategoryId.value, CategoryConstants.filterAllId);
  });

  testWidgets('tapping a category opens the category items screen', (
    tester,
  ) async {
    operations.vault = mixedVault();
    await pumpCategories(tester);
    final loadsBeforeOpen = operations.getVaultCount;

    await openCategory(tester);

    expect(Get.currentRoute, AppRoutes.categoryItems);
    expect(find.byKey(const Key('category-items')), findsOneWidget);
    expect(find.text('مالی'), findsWidgets);
    expect(operations.getVaultCount, loadsBeforeOpen);
    expect(home.selectedCategoryId.value, CategoryConstants.filterAllId);
  });

  testWidgets('category items screen shows only matching mixed types', (
    tester,
  ) async {
    operations.vault = mixedVault();
    await pumpCategories(tester);
    await openCategory(tester);

    expect(find.byKey(const Key('vault-item-card-a')), findsOneWidget);
    expect(find.byKey(const Key('vault-item-card-b')), findsOneWidget);
    expect(find.text('Bank Card A'), findsOneWidget);
    expect(find.text('Bank Card B'), findsOneWidget);
    expect(find.text('Login A'), findsNothing);
    expect(find.text('Note A'), findsNothing);
  });

  testWidgets('empty category shows the empty state without an Add button', (
    tester,
  ) async {
    operations.vault = VaultData(
      version: VaultData.currentVersion,
      logins: [login(categoryId: CategoryDefaults.workId)],
      bankCards: const [],
      secureNotes: const [],
      categories: CategoryDefaults.items,
    );
    await pumpCategories(tester);
    await openCategory(tester);

    expect(find.byKey(const Key('category-items-empty')), findsOneWidget);
    expect(find.text('این دسته خالی است'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('category-items-empty')),
        matching: find.byType(AppButtonWidget),
      ),
      findsNothing,
    );
    expect(find.byType(AppEmptyWidget), findsOneWidget);
  });

  testWidgets('item tap opens detail not edit and back returns to category items', (
    tester,
  ) async {
    operations.vault = mixedVault();
    await pumpCategories(tester);
    await openCategory(tester);

    await tester.tap(find.text('Bank Card A'));
    await pumpOpenedRoute(tester);

    expect(Get.currentRoute, AppRoutes.bankCardDetails);
    expect(find.byKey(const Key('vault-bank-card-details')), findsOneWidget);
    expect(find.text('ویرایش کارت'), findsNothing);

    await popOpenedRoute(tester);

    expect(Get.currentRoute, AppRoutes.categoryItems);
    expect(find.byKey(const Key('category-items')), findsOneWidget);
    expect(find.text('Bank Card A'), findsOneWidget);
  });

  testWidgets('login and note items from other categories open their details', (
    tester,
  ) async {
    operations.vault = mixedVault();
    await pumpCategories(tester);

    await openCategory(tester, id: CategoryDefaults.workId);
    await tester.tap(find.text('Login A'));
    await pumpOpenedRoute(tester);
    expect(find.byKey(const Key('vault-login-details')), findsOneWidget);
    await popOpenedRoute(tester);

    await popOpenedRoute(tester);
    await openCategory(tester, id: CategoryDefaults.personalId);
    await tester.tap(find.text('Note A'));
    await pumpOpenedRoute(tester);
    expect(find.byKey(const Key('vault-note-details')), findsOneWidget);
  });

  testWidgets('back from category items returns to categories', (tester) async {
    operations.vault = mixedVault();
    await pumpCategories(tester);
    await openCategory(tester);

    expect(Get.currentRoute, AppRoutes.categoryItems);
    await tester.tap(find.byIcon(AppIcon.arrowBack));
    await pumpOpenedRoute(tester);

    expect(Get.currentRoute, AppRoutes.shell);
    expect(find.text('دسته‌بندی‌ها'), findsOneWidget);
    expect(find.byKey(const Key('category-items')), findsNothing);
  });

  testWidgets('pin and unpin from category items uses shared pin state', (
    tester,
  ) async {
    operations.vault = VaultData(
      version: VaultData.currentVersion,
      logins: const [],
      bankCards: [
        card(categoryId: CategoryDefaults.financeId),
        card(
          id: 'card-b',
          title: 'Bank Card B',
          categoryId: CategoryDefaults.financeId,
        ),
      ],
      secureNotes: const [],
      categories: CategoryDefaults.items,
    );
    await pumpCategories(tester);
    await openCategory(tester);

    await tester.tap(find.byIcon(Icons.more_horiz).last);
    await pumpVaultFrame(tester);
    await tester.tap(find.text('سنجاق کردن'));
    await pumpVaultFrame(tester);

    expect(operations.vault!.bankCards.last.isPinned, isTrue);
    expect(find.byKey(const Key('vault-item-pin-indicator')), findsOneWidget);

    final pinnedTop = tester.getTopLeft(find.byKey(const Key('vault-item-card-b')));
    final unpinnedTop = tester.getTopLeft(
      find.byKey(const Key('vault-item-card-a')),
    );
    expect(pinnedTop.dy, lessThan(unpinnedTop.dy));

    await tester.tap(find.byIcon(Icons.more_horiz).first);
    await pumpVaultFrame(tester);
    await tester.tap(find.text('برداشتن سنجاق'));
    await pumpVaultFrame(tester);

    expect(
      operations.vault!.bankCards.every((item) => !item.isPinned),
      isTrue,
    );
  });

  testWidgets('category items enforces the existing 5-item pin limit', (
    tester,
  ) async {
    operations.vault = VaultData(
      version: VaultData.currentVersion,
      logins: [
        for (var i = 1; i <= 5; i++)
          login(
            id: 'login-$i',
            title: 'Login $i',
            categoryId: CategoryDefaults.workId,
            isPinned: true,
          ),
      ],
      bankCards: [card(categoryId: CategoryDefaults.financeId)],
      secureNotes: const [],
      categories: CategoryDefaults.items,
    );
    await pumpCategories(tester);
    await openCategory(tester);

    await tester.tap(find.byIcon(Icons.more_horiz).first);
    await pumpVaultFrame(tester);
    await tester.tap(find.text('سنجاق کردن'));
    await pumpVaultFrame(tester);

    expect(find.text('حداکثر سنجاق'), findsOneWidget);
    expect(find.text('حداکثر ۵ مورد را می‌توانید سنجاق کنید.'), findsOneWidget);
    expect(operations.vault!.bankCards.single.isPinned, isFalse);
    AppToast.dismiss();
  });

  testWidgets('create from category items preselects the current category', (
    tester,
  ) async {
    operations.vault = mixedVault();
    await pumpCategories(tester);
    await openCategory(tester);

    await tester.tap(find.byIcon(AppIcon.add));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    await tester.tap(find.byKey(const Key('category-items-fab-login')));
    await pumpOpenedRoute(tester);

    expect(Get.currentRoute, AppRoutes.loginCreate);
    expect(
      Get.find<LoginCreateViewModel>().selectedCategoryId.value,
      CategoryDefaults.financeId,
    );
  });

  testWidgets('deleting the open category leaves the items screen safely', (
    tester,
  ) async {
    operations.vault = mixedVault();
    await pumpCategories(tester);
    await openCategory(tester);
    expect(find.byKey(const Key('category-items')), findsOneWidget);

    await categories.deleteCategory(CategoryDefaults.financeId);
    await pumpOpenedRoute(tester);

    expect(Get.currentRoute, AppRoutes.shell);
    expect(find.text('دسته‌بندی‌ها'), findsOneWidget);
    expect(find.byKey(const Key('category-card-cat_finance')), findsNothing);
    expect(operations.vault!.bankCards, isNotEmpty);
  });

  testWidgets('category items only show the unlocked vault session data', (
    tester,
  ) async {
    operations.vault = mixedVault();
    await pumpCategories(tester);
    await openCategory(tester);
    expect(find.text('Bank Card A'), findsOneWidget);

    operations.vault = VaultData(
      version: VaultData.currentVersion,
      logins: const [],
      bankCards: [
        card(
          id: 'card-other-account',
          title: 'Other Account Card',
          categoryId: CategoryDefaults.financeId,
        ),
      ],
      secureNotes: const [],
      categories: CategoryDefaults.items,
    );
    await home.refreshVault();
    await pumpVaultFrame(tester);

    expect(find.text('Other Account Card'), findsOneWidget);
    expect(find.text('Bank Card A'), findsNothing);
    expect(find.text('Login A'), findsNothing);
  });
}
