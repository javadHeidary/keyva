import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:keyva/core/exceptions/app_failure.dart';
import 'package:keyva/feature/home/view/home_view.dart';
import 'package:keyva/feature/home/viewmodel/home_viewmodel.dart';
import 'package:keyva/feature/search/viewmodel/search_viewmodel.dart';
import 'package:keyva/feature/vault/model/bank_card_item.dart';
import 'package:keyva/feature/vault/model/category_item.dart';
import 'package:keyva/feature/vault/model/login_item.dart';
import 'package:keyva/feature/vault/model/secure_note_item.dart';
import 'package:keyva/feature/vault/model/vault_data.dart';
import 'package:keyva/feature/vault/viewmodel/vault_home_viewmodel.dart';
import 'package:keyva/feature/vault/viewmodel/vault_ui_status.dart';
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
    await tester.scrollUntilVisible(
      finder,
      200,
      scrollable: find.byType(Scrollable).first,
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

  testWidgets('empty state renders', (tester) async {
    operations.vault = emptyVault();

    await pumpHome(tester);
    await pumpVaultFrame(tester);

    expect(find.byKey(const Key('vault-home-empty')), findsOneWidget);
    expect(find.text('هنوز چیزی ذخیره نکرده‌اید'), findsOneWidget);
    expect(find.text('ایجاد اولین آیتم'), findsOneWidget);
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

    expect(operations.getVaultCount, loadsBeforeRetry + 1);
    expect(find.byKey(const Key('vault-home-empty')), findsOneWidget);
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
