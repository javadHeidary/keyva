import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:keyva/core/exceptions/app_failure.dart';
import 'package:keyva/core/routes/app_routing.dart';
import 'package:keyva/feature/home/model/vault_models.dart';
import 'package:keyva/feature/home/view/home_view.dart';
import 'package:keyva/feature/home/viewmodel/home_viewmodel.dart';
import 'package:keyva/feature/settings/util/settings_avatar_icons.dart';
import 'package:keyva/feature/search/viewmodel/search_viewmodel.dart';
import 'package:keyva/feature/vault/model/bank_card_item.dart';
import 'package:keyva/feature/vault/model/category_item.dart';
import 'package:keyva/feature/vault/model/login_item.dart';
import 'package:keyva/feature/vault/model/secure_note_item.dart';
import 'package:keyva/feature/vault/model/vault_data.dart';
import 'package:keyva/feature/vault/viewmodel/vault_home_viewmodel.dart';
import 'package:keyva/feature/vault/viewmodel/vault_ui_status.dart';
import 'package:keyva/shared/widget/app_empty_widget.dart';
import 'package:keyva/shared/widget/app_fab_widget.dart';
import 'package:keyva/shared/widget/app_search_widget.dart';

import 'support/fake_vault_operation_service.dart';
import 'support/vault_widget_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeVaultOperationService operations;
  late VaultHomeViewModel vault;
  late HomeController home;

  final createdAt = DateTime.utc(2026, 7, 1, 10);
  final updatedAt = DateTime.utc(2026, 7, 2, 11);

  LoginItem login({
    String id = 'login-1',
    String title = 'Mail',
    String username = 'keep-this-user',
  }) {
    return LoginItem(
      id: id,
      title: title,
      username: username,
      password: 'keep-this-password',
      website: 'https://mail.test',
      notes: null,
      categoryId: null,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  BankCardItem card() {
    return BankCardItem(
      id: 'card-1',
      title: 'Travel',
      cardNumber: '6219861234567890',
      cardHolder: 'Nima Karimi',
      expiryDate: '06/30',
      cvv: '321',
      bankName: 'Saman',
      notes: null,
      categoryId: null,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  SecureNoteItem note() {
    return SecureNoteItem(
      id: 'note-1',
      title: 'Gate',
      content: 'building-code-42',
      categoryId: null,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  CategoryItem category() {
    return CategoryItem(
      id: 'cat-1',
      name: 'Work',
      icon: 'inbox',
      createdAt: createdAt,
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

  VaultData populatedVault() {
    return VaultData(
      version: VaultData.currentVersion,
      logins: [login()],
      bankCards: [card()],
      secureNotes: [note()],
      categories: [category()],
    );
  }

  Future<void> pumpHome(
    WidgetTester tester, {
    bool loadBeforePump = true,
  }) async {
    setupVaultWidgetSurface(tester);
    if (loadBeforePump) {
      await home.loadVault();
    }
    await tester.pumpWidget(vaultTestApp(home: const HomeView()));
    await pumpVaultFrame(tester);
  }

  Future<void> revealFinder(WidgetTester tester, Finder finder) async {
    final verticalScrollable = find.descendant(
      of: find.byType(CustomScrollView),
      matching: find.byType(Scrollable),
    );
    await tester.scrollUntilVisible(
      finder,
      200,
      scrollable: verticalScrollable.first,
    );
    await pumpVaultFrame(tester);
  }

  setUp(() {
    Get.testMode = true;
    operations = FakeVaultOperationService();
    vault = VaultHomeViewModel(operations: operations);
    home = HomeController(vault: vault);
    Get.put(vault);
    Get.put(home);
  });

  tearDown(Get.reset);

  testWidgets('loading state renders', (tester) async {
    vault.status.value = VaultUiStatus.loading;

    await pumpHome(tester, loadBeforePump: false);

    expect(find.byKey(const Key('vault-home-loading')), findsOneWidget);
    expect(find.text('در حال بارگذاری گاوصندوق'), findsOneWidget);
  });

  testWidgets('loaded state renders items and skips categories', (tester) async {
    operations.vault = populatedVault();

    await pumpHome(tester);
    await revealFinder(tester, find.byKey(const Key('vault-item-login-1')));

    expect(find.byKey(const Key('vault-item-login-1')), findsOneWidget);
    expect(find.text('Mail'), findsOneWidget);
    expect(find.text('keep-this-user'), findsOneWidget);
    await revealFinder(tester, find.text('Travel'));
    expect(find.text('Travel'), findsOneWidget);
    expect(find.text('Saman'), findsOneWidget);
    await revealFinder(tester, find.text('Gate'));
    expect(find.text('Gate'), findsOneWidget);
    expect(find.text('Work'), findsNothing);
    expect(find.text('keep-this-password'), findsNothing);
    expect(find.text('6219861234567890'), findsNothing);
  });

  Future<void> expectHomeChrome(WidgetTester tester) async {
    expect(find.byKey(const Key('home-account-header')), findsOneWidget);
    expect(find.byKey(const Key('home-search-chip')), findsOneWidget);
    expect(find.byKey(const Key('home-type-selector')), findsOneWidget);
    expect(find.text('انواع آیتم‌ها'), findsOneWidget);
    expect(find.text('ورودها'), findsOneWidget);
    expect(find.text('کارت‌های بانکی'), findsOneWidget);
    expect(find.text('یادداشت‌ها'), findsOneWidget);
    expect(find.byType(AppFabWidget), findsOneWidget);
  }

  testWidgets('empty vault keeps Home chrome and content empty state', (
    tester,
  ) async {
    operations.vault = emptyVault();

    await pumpHome(tester);
    await revealFinder(tester, find.byKey(const Key('vault-home-empty')));

    await expectHomeChrome(tester);
    expect(find.byKey(const Key('vault-home-empty')), findsOneWidget);
    expect(find.byKey(const Key('vault-home-empty-cta')), findsOneWidget);
    expect(find.text('هنوز چیزی اضافه نکرده‌اید'), findsOneWidget);
    expect(find.text('اولین اطلاعات خود را به کیوا اضافه کنید.'), findsOneWidget);
    expect(find.text('افزودن آیتم'), findsOneWidget);
    expect(find.text('هنوز چیزی ذخیره نکرده‌اید'), findsNothing);
    expect(find.text('ایجاد اولین آیتم'), findsNothing);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is AppEmptyWidget && widget.layout == AppEmptyLayout.page,
      ),
      findsNothing,
    );
  });

  testWidgets('account header shows the persisted name and avatar', (
    tester,
  ) async {
    operations.vault = emptyVault();
    home.updateAccountProfile(name: 'رضا', avatarId: 'star');

    await pumpHome(tester);

    expect(find.text('رضا'), findsOneWidget);
    expect(
      find.byIcon(SettingsAvatarIcons.iconForId('star')),
      findsOneWidget,
    );
  });

  testWidgets('empty vault CTA opens the existing FAB create flow', (
    tester,
  ) async {
    operations.vault = emptyVault();
    var openedLoginCreate = false;

    setupVaultWidgetSurface(tester);
    await home.loadVault();
    await tester.pumpWidget(
      vaultTestApp(
        home: const HomeView(),
        initialRoute: '/home',
        getPages: [
          GetPage(name: '/home', page: () => const HomeView()),
          GetPage(
            name: AppRoutes.loginCreate,
            page: () {
              openedLoginCreate = true;
              return const Scaffold(
                key: Key('login-create-test'),
                body: SizedBox.shrink(),
              );
            },
          ),
        ],
      ),
    );
    await pumpVaultFrame(tester);
    await revealFinder(tester, find.byKey(const Key('vault-home-empty-cta')));

    await tester.tap(find.byKey(const Key('vault-home-empty-cta')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.byKey(const Key('home-fab-login')), findsOneWidget);

    await tester.tap(find.byKey(const Key('home-fab-login')));
    await pumpVaultFrame(tester);

    expect(openedLoginCreate, isTrue);
    expect(find.byKey(const Key('login-create-test')), findsOneWidget);
    expect(operations.addCount, 0);
  });

  testWidgets('create from empty replaces content empty state with the item', (
    tester,
  ) async {
    operations.vault = emptyVault();

    await pumpHome(tester);
    await revealFinder(tester, find.byKey(const Key('vault-home-empty')));

    operations.vault = VaultData(
      version: VaultData.currentVersion,
      logins: [login()],
      bankCards: const [],
      secureNotes: const [],
      categories: const [],
    );
    await home.refreshVault();
    await pumpVaultFrame(tester);
    await revealFinder(tester, find.byKey(const Key('vault-item-login-1')));

    await expectHomeChrome(tester);
    expect(find.byKey(const Key('vault-item-login-1')), findsOneWidget);
    expect(find.text('Mail'), findsOneWidget);
    expect(find.byKey(const Key('vault-home-empty')), findsNothing);
  });

  testWidgets('deleting the last item restores content empty state', (
    tester,
  ) async {
    operations.vault = VaultData(
      version: VaultData.currentVersion,
      logins: [login()],
      bankCards: const [],
      secureNotes: const [],
      categories: const [],
    );

    await pumpHome(tester);
    await revealFinder(tester, find.byKey(const Key('vault-item-login-1')));

    await tester.tap(find.byIcon(Icons.more_horiz).first);
    await pumpVaultFrame(tester);
    await tester.tap(find.text('حذف').last);
    await pumpVaultFrame(tester);
    await tester.tap(find.text('حذف').last);
    await pumpVaultFrame(tester);
    await tester.pump(const Duration(milliseconds: 100));
    await revealFinder(tester, find.byKey(const Key('vault-home-empty')));

    expect(operations.lastDeletedId, 'login-1');
    await expectHomeChrome(tester);
    expect(find.byKey(const Key('vault-home-empty')), findsOneWidget);
    expect(find.byKey(const Key('vault-item-login-1')), findsNothing);
  });

  testWidgets('type filter with zero items keeps Home chrome', (tester) async {
    operations.vault = VaultData(
      version: VaultData.currentVersion,
      logins: [login()],
      bankCards: const [],
      secureNotes: const [],
      categories: const [],
    );

    await pumpHome(tester);
    await revealFinder(tester, find.byKey(const Key('vault-item-login-1')));

    home.selectType(VaultItemType.bankCard);
    await pumpVaultFrame(tester);
    await revealFinder(tester, find.byKey(const Key('vault-home-empty')));

    await expectHomeChrome(tester);
    expect(find.byKey(const Key('vault-item-login-1')), findsNothing);
    expect(find.text('هنوز کارت بانکی ثبت نشده'), findsOneWidget);
    expect(find.text('افزودن آیتم'), findsNothing);
  });

  testWidgets('empty vault search stays idle instead of no-results', (
    tester,
  ) async {
    operations.vault = emptyVault();
    await vault.loadVault();
    Get.put(SearchViewModel());

    setupVaultWidgetSurface(tester);
    await tester.pumpWidget(vaultTestApp(home: const AppSearchWidget()));
    await pumpVaultFrame(tester);

    await tester.enterText(find.byType(TextField), 'anything');
    await tester.pump(const Duration(milliseconds: 350));
    await pumpVaultFrame(tester);

    expect(find.text('برای جستجو تایپ کنید'), findsOneWidget);
    expect(find.text('موردی یافت نشد'), findsNothing);
  });

  testWidgets('error state renders', (tester) async {
    operations.getVaultFailure = const DatabaseFailure();

    await pumpHome(tester);
    await pumpVaultFrame(tester);

    expect(find.byKey(const Key('vault-home-error')), findsOneWidget);
    expect(find.text('بارگذاری گاوصندوق ممکن نشد'), findsOneWidget);
    expect(find.byKey(const Key('vault-home-retry')), findsOneWidget);
    expect(find.textContaining('Hive'), findsNothing);
    expect(find.textContaining('Exception'), findsNothing);
  });

  testWidgets('retry triggers ViewModel loadVault', (tester) async {
    operations.getVaultFailure = const AuthenticationFailure();

    await pumpHome(tester);
    await pumpVaultFrame(tester);

    final loadsBeforeRetry = operations.getVaultCount;
    expect(find.byKey(const Key('vault-home-retry')), findsOneWidget);

    operations.getVaultFailure = null;
    operations.vault = emptyVault();

    await tester.tap(find.byKey(const Key('vault-home-retry')));
    await pumpVaultFrame(tester);
    await revealFinder(tester, find.byKey(const Key('vault-home-empty')));

    expect(operations.getVaultCount, loadsBeforeRetry + 1);
    expect(find.byKey(const Key('vault-home-empty')), findsOneWidget);
    expect(find.byKey(const Key('home-type-selector')), findsOneWidget);
  });

  testWidgets('search updates displayed results', (tester) async {
    operations.vault = populatedVault();

    await pumpHome(tester);
    await revealFinder(tester, find.text('Mail'));
    await revealFinder(tester, find.text('Travel'));

    home.searchItems('mail');
    await pumpVaultFrame(tester);
    await revealFinder(tester, find.text('Mail'));

    expect(find.text('Mail'), findsOneWidget);
    expect(find.text('Travel'), findsNothing);
    expect(find.text('Gate'), findsNothing);

    home.searchItems('');
    await pumpVaultFrame(tester);
    await revealFinder(tester, find.text('Travel'));
    await revealFinder(tester, find.text('Gate'));

    expect(find.text('Mail'), findsOneWidget);
    expect(find.text('Travel'), findsOneWidget);
    expect(find.text('Gate'), findsOneWidget);
  });

  testWidgets('search screen uses ViewModel search', (tester) async {
    operations.vault = populatedVault();
    await vault.loadVault();
    Get.put(SearchViewModel());

    setupVaultWidgetSurface(tester);
    await tester.pumpWidget(vaultTestApp(home: const AppSearchWidget()));
    await pumpVaultFrame(tester);

    expect(find.byKey(const Key('vault-search-field')), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'saman');
    await tester.pump(const Duration(milliseconds: 350));
    await pumpVaultFrame(tester);

    expect(find.text('Travel'), findsOneWidget);
    expect(find.text('Mail'), findsNothing);
    expect(operations.persistCount, 0);
  });

  testWidgets('delete action triggers ViewModel operation', (tester) async {
    operations.vault = populatedVault();

    await pumpHome(tester);
    await revealFinder(tester, find.byKey(const Key('vault-item-login-1')));

    await tester.tap(find.byIcon(Icons.more_horiz).first);
    await pumpVaultFrame(tester);

    await tester.tap(find.text('حذف').last);
    await pumpVaultFrame(tester);

    expect(find.text('حذف آیتم'), findsOneWidget);

    await tester.tap(find.text('حذف').last);
    await pumpVaultFrame(tester);

    expect(operations.lastDeletedId, 'login-1');
  });
}
