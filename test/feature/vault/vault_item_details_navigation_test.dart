import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:keyva/core/routes/app_routing.dart';
import 'package:keyva/feature/home/view/home_view.dart';
import 'package:keyva/feature/home/view/type_list_item_view.dart';
import 'package:keyva/feature/home/viewmodel/home_viewmodel.dart';
import 'package:keyva/feature/search/viewmodel/search_viewmodel.dart';
import 'package:keyva/feature/type/login/view/login_create_view.dart';
import 'package:keyva/feature/type/login/view/login_details_view.dart';
import 'package:keyva/feature/type/login/view/login_edit_view.dart';
import 'package:keyva/feature/type/login/viewmodel/login_create_viewmodel.dart';
import 'package:keyva/feature/type/login/viewmodel/login_details_viewmodel.dart';
import 'package:keyva/feature/type/login/viewmodel/login_edit_viewmodel.dart';
import 'package:keyva/feature/vault/model/login_item.dart';
import 'package:keyva/feature/vault/model/vault_data.dart';
import 'package:keyva/feature/vault/view/vault_item_navigation.dart';
import 'package:keyva/feature/vault/viewmodel/vault_home_viewmodel.dart';
import 'package:keyva/feature/vault/viewmodel/vault_item_viewmodel.dart';
import 'package:keyva/shared/widget/app_search_widget.dart';

import 'support/fake_share_sheet_service.dart';
import 'support/fake_vault_operation_service.dart';
import 'support/vault_widget_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeVaultOperationService operations;
  late VaultHomeViewModel vault;
  late VaultItemViewModel items;
  late HomeController home;

  final createdAt = DateTime.utc(2026, 7, 1, 10);
  final updatedAt = DateTime.utc(2026, 7, 2, 11);

  LoginItem login({
    String id = 'login-1',
    String title = 'Mail',
  }) {
    return LoginItem(
      id: id,
      title: title,
      username: 'keep-this-user',
      password: 'keep-this-password',
      website: 'https://mail.test',
      notes: null,
      categoryId: null,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  VaultData populatedVault() {
    return VaultData(
      version: VaultData.currentVersion,
      logins: [login()],
      bankCards: const [],
      secureNotes: const [],
      categories: const [],
    );
  }

  VaultData emptyVault() {
    return VaultData(
      version: VaultData.currentVersion,
      logins: const [],
      bankCards: const [],
      secureNotes: const [],
      categories: const [],
    );
  }

  void ensureControllers() {
    if (!Get.isRegistered<VaultHomeViewModel>()) {
      Get.put(vault, permanent: true);
    }
    if (!Get.isRegistered<VaultItemViewModel>()) {
      Get.put(items, permanent: true);
    }
    if (!Get.isRegistered<HomeController>()) {
      Get.put(home, permanent: true);
    }
  }

  List<GetPage> appPages() {
    return [
      GetPage(
        name: AppRoutes.home,
        page: () => const HomeView(),
        binding: BindingsBuilder(ensureControllers),
      ),
      GetPage(
        name: AppRoutes.typeList,
        page: () => TypeListItemView(),
        binding: BindingsBuilder(ensureControllers),
      ),
      GetPage(
        name: AppRoutes.search,
        page: () => const AppSearchWidget(),
        binding: BindingsBuilder(() {
          ensureControllers();
          Get.lazyPut(SearchViewModel.new, fenix: true);
        }),
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
        name: AppRoutes.loginEdit,
        page: () => const LoginEditView(),
        binding: BindingsBuilder(() {
          ensureControllers();
          if (Get.isRegistered<LoginEditViewModel>()) {
            Get.delete<LoginEditViewModel>(force: true);
          }
          Get.put(
            LoginEditViewModel(
              loginId: vaultRouteItemId(),
              items: items,
            ),
          );
        }),
      ),
    ];
  }

  Future<void> pumpRoutedHome(WidgetTester tester) async {
    setupVaultWidgetSurface(tester);
    await home.loadVault();
    await tester.pumpWidget(
      vaultTestApp(
        home: const HomeView(),
        initialRoute: AppRoutes.home,
        getPages: appPages(),
      ),
    );
    await pumpVaultFrame(tester);
  }

  Future<void> revealFinder(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await pumpVaultFrame(tester);
  }

  Future<void> pumpOpenedRoute(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump();
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
    home = HomeController(vault: vault);
    Get.put(vault, permanent: true);
    Get.put(items, permanent: true);
    Get.put(home, permanent: true);
  });

  tearDown(Get.reset);

  testWidgets('home item tap opens detail not edit', (tester) async {
    operations.vault = populatedVault();
    await pumpRoutedHome(tester);
    await revealFinder(tester, find.byKey(const Key('vault-item-login-1')));

    await tester.tap(find.text('Mail'));
    await pumpOpenedRoute(tester);

    expect(find.byKey(const Key('vault-login-details')), findsOneWidget);
    expect(find.text('ویرایش اکانت'), findsNothing);
    expect(find.text('keep-this-user'), findsWidgets);
  });

  testWidgets('search item tap opens detail', (tester) async {
    operations.vault = populatedVault();
    await pumpRoutedHome(tester);

    await tester.tap(find.byKey(const Key('home-search')));
    await pumpOpenedRoute(tester);

    expect(find.byKey(const Key('vault-search-field')), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'mail');
    await tester.pump(const Duration(milliseconds: 350));
    await pumpVaultFrame(tester);

    await tester.tap(find.text('Mail'));
    await pumpOpenedRoute(tester);

    expect(find.byKey(const Key('vault-login-details')), findsOneWidget);
    expect(find.text('ویرایش اکانت'), findsNothing);

    await popOpenedRoute(tester);

    expect(Get.currentRoute, AppRoutes.search);
    expect(find.byKey(const Key('vault-search-field')), findsOneWidget);
    expect(find.byKey(const Key('vault-login-details')), findsNothing);
  });

  testWidgets('edit button opens existing edit and back returns to detail', (
    tester,
  ) async {
    operations.vault = populatedVault();
    await pumpRoutedHome(tester);
    await revealFinder(tester, find.text('Mail'));

    await tester.tap(find.text('Mail'));
    await pumpOpenedRoute(tester);
    expect(find.byKey(const Key('vault-login-details')), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('vault-item-edit')));
    await tester.tap(find.byKey(const Key('vault-item-edit')));
    await pumpOpenedRoute(tester);

    expect(Get.currentRoute, AppRoutes.loginEdit);
    expect(find.text('ویرایش اکانت'), findsOneWidget);

    await popOpenedRoute(tester);

    expect(Get.currentRoute, AppRoutes.loginDetails);
    expect(find.byKey(const Key('vault-login-details')), findsOneWidget);
    expect(find.text('ویرایش اکانت'), findsNothing);
  });

  testWidgets('back from detail returns to home', (tester) async {
    operations.vault = populatedVault();
    await pumpRoutedHome(tester);
    await revealFinder(tester, find.text('Mail'));

    await tester.tap(find.text('Mail'));
    await pumpOpenedRoute(tester);
    expect(find.byKey(const Key('vault-login-details')), findsOneWidget);

    expect(Get.currentRoute, AppRoutes.loginDetails);

    await popOpenedRoute(tester);

    expect(Get.currentRoute, AppRoutes.home);
    expect(find.byKey(const Key('home-account-header')), findsOneWidget);
    expect(find.byKey(const Key('vault-login-details')), findsNothing);
  });

  testWidgets('more menu keeps copy and delete and does not open edit', (
    tester,
  ) async {
    operations.vault = populatedVault();
    await pumpRoutedHome(tester);
    await revealFinder(tester, find.byKey(const Key('vault-item-login-1')));

    await tester.tap(find.byIcon(Icons.more_horiz).first);
    await pumpVaultFrame(tester);

    expect(find.text('کپی نام کاربری'), findsOneWidget);
    expect(find.text('کپی رمز عبور'), findsOneWidget);
    expect(find.text('حذف'), findsOneWidget);
    expect(find.text('ویرایش'), findsNothing);
    expect(find.byKey(const Key('vault-login-details')), findsNothing);

    await tester.tap(find.text('حذف').last);
    await pumpVaultFrame(tester);
    await tester.tap(find.text('حذف').last);
    await pumpVaultFrame(tester);

    expect(operations.lastDeletedId, 'login-1');
  });

  testWidgets('create opens detail then back shows type list then home', (
    tester,
  ) async {
    operations.vault = emptyVault();
    await pumpRoutedHome(tester);

    Get.toNamed(AppRoutes.loginCreate);
    await pumpOpenedRoute(tester);
    expect(find.text('ایجاد اکانت'), findsWidgets);

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Work Mail');
    await tester.enterText(fields.at(2), 'user@test.com');
    await tester.enterText(fields.at(3), 'secret-pass');
    await Get.find<LoginCreateViewModel>().submit();
    await pumpOpenedRoute(tester);
    await tester.pump();

    expect(Get.currentRoute, AppRoutes.loginDetails);
    expect(find.byKey(const Key('vault-login-details')), findsOneWidget);
    expect(find.text('Work Mail'), findsWidgets);
    expect(find.text('ایجاد اکانت'), findsNothing);

    await popOpenedRoute(tester);

    expect(Get.currentRoute, AppRoutes.typeList);
    expect(find.byKey(const Key('vault-type-list')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('vault-type-list')),
        matching: find.text('Work Mail'),
      ),
      findsOneWidget,
    );

    await popOpenedRoute(tester);

    expect(Get.currentRoute, AppRoutes.home);
    expect(find.byKey(const Key('home-account-header')), findsOneWidget);
    expect(find.byKey(const Key('vault-type-list')), findsNothing);
  });

  testWidgets('search results refresh after vault item title changes', (
    tester,
  ) async {
    operations.vault = populatedVault();
    await vault.loadVault();
    Get.put(SearchViewModel());

    setupVaultWidgetSurface(tester);
    await tester.pumpWidget(vaultTestApp(home: const AppSearchWidget()));
    await pumpVaultFrame(tester);

    await tester.enterText(find.byType(TextField), 'mail');
    await tester.pump(const Duration(milliseconds: 350));
    await pumpVaultFrame(tester);
    expect(find.text('Mail'), findsOneWidget);

    operations.vault = VaultData(
      version: VaultData.currentVersion,
      logins: [login(title: 'Updated Mail')],
      bankCards: const [],
      secureNotes: const [],
      categories: const [],
    );
    await vault.refreshVault();
    await pumpVaultFrame(tester);

    expect(find.text('Updated Mail'), findsOneWidget);
    expect(find.text('Mail'), findsNothing);
  });
}
