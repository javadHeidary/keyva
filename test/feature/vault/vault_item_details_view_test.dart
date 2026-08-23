import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:keyva/feature/category/model/category_constants.dart';
import 'package:keyva/feature/home/viewmodel/home_viewmodel.dart';
import 'package:keyva/feature/type/bank_card/view/bank_card_details_view.dart';
import 'package:keyva/feature/type/bank_card/viewmodel/bank_card_details_viewmodel.dart';
import 'package:keyva/feature/type/login/view/login_details_view.dart';
import 'package:keyva/feature/type/login/viewmodel/login_details_viewmodel.dart';
import 'package:keyva/feature/type/login/widget/login_detail_credential_card.dart';
import 'package:keyva/feature/type/note/view/note_details_view.dart';
import 'package:keyva/feature/type/note/viewmodel/note_details_viewmodel.dart';
import 'package:keyva/feature/vault/model/bank_card_item.dart';
import 'package:keyva/feature/vault/model/category_item.dart';
import 'package:keyva/feature/vault/model/login_item.dart';
import 'package:keyva/feature/vault/model/secure_note_item.dart';
import 'package:keyva/feature/vault/model/vault_data.dart';
import 'package:keyva/feature/vault/viewmodel/vault_home_viewmodel.dart';
import 'package:keyva/shared/icons/app_icons.dart';
import 'package:keyva/shared/utils/jalali_date_formatter.dart';
import 'package:keyva/shared/widget/toast_widget.dart';

import 'support/fake_vault_operation_service.dart';
import 'support/vault_widget_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeVaultOperationService operations;
  late VaultHomeViewModel vault;
  late HomeController home;

  final createdAt = DateTime.utc(2026, 7, 1, 10);
  final updatedAt = DateTime.utc(2026, 7, 2, 11);

  LoginItem login() {
    return LoginItem(
      id: 'login-1',
      title: 'Mail',
      username: 'keep-this-user',
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

  VaultData populatedVault() {
    return VaultData(
      version: VaultData.currentVersion,
      logins: [login()],
      bankCards: [card()],
      secureNotes: [note()],
      categories: const [],
    );
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

  testWidgets('login detail displays data and hides password by default', (
    tester,
  ) async {
    operations.vault = populatedVault();
    await vault.loadVault();
    Get.put(LoginDetailsViewModel(loginId: 'login-1'));

    setupVaultWidgetSurface(tester);
    await tester.pumpWidget(vaultTestApp(home: const LoginDetailsView()));
    await pumpVaultFrame(tester);

    expect(find.byKey(const Key('vault-login-details')), findsOneWidget);
    expect(find.text('Mail'), findsWidgets);
    expect(find.text('keep-this-user'), findsOneWidget);
    expect(find.text('mail.test'), findsOneWidget);
    expect(find.text('keep-this-password'), findsNothing);
    expect(find.text('•' * 'keep-this-password'.length), findsOneWidget);
    expect(find.text('ویرایش'), findsOneWidget);
    expect(find.text(formatJalaliDate(updatedAt)), findsOneWidget);
  });

  testWidgets('bank card detail displays data and hides cvv by default', (
    tester,
  ) async {
    operations.vault = populatedVault();
    await vault.loadVault();
    Get.put(BankCardDetailsViewModel(cardId: 'card-1'));

    setupVaultWidgetSurface(tester);
    tester.view.physicalSize = const Size(2160, 2400);
    await tester.pumpWidget(vaultTestApp(home: const BankCardDetailsView()));
    await pumpVaultFrame(tester);

    expect(find.byKey(const Key('vault-bank-card-details')), findsOneWidget);
    expect(find.text('Travel'), findsWidgets);
    expect(find.text('Nima Karimi'), findsOneWidget);
    expect(find.text('321'), findsNothing);
    expect(find.text('•' * 3), findsOneWidget);
    expect(find.text('تاریخ ایجاد'), findsOneWidget);
    expect(find.text(formatJalaliDate(createdAt)), findsOneWidget);
  });

  testWidgets('bank card detail shows bank name without a copy action', (
    tester,
  ) async {
    operations.vault = populatedVault();
    await vault.loadVault();
    Get.put(BankCardDetailsViewModel(cardId: 'card-1'));

    setupVaultWidgetSurface(tester);
    tester.view.physicalSize = const Size(2160, 2400);
    await tester.pumpWidget(vaultTestApp(home: const BankCardDetailsView()));
    await pumpVaultFrame(tester);

    final bankNameFinder = find.byKey(const Key('vault-bank-card-bank-name'));
    expect(bankNameFinder, findsOneWidget);

    final vm = Get.find<BankCardDetailsViewModel>();
    expect(vm.displayBankTitle, isNotEmpty);
    expect(find.text(vm.displayBankTitle), findsWidgets);

    final bankCard = tester.widget<LoginDetailCredentialCard>(bankNameFinder);
    expect(bankCard.value, vm.displayBankTitle);
    expect(bankCard.trailing, isNull);
    expect(
      find.descendant(
        of: bankNameFinder,
        matching: find.byIcon(AppIcon.copy),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: bankNameFinder,
        matching: find.byIcon(Icons.copy_rounded),
      ),
      findsNothing,
    );
  });

  testWidgets('bank card detail renders month and year separately', (
    tester,
  ) async {
    operations.vault = populatedVault();
    await vault.loadVault();
    Get.put(BankCardDetailsViewModel(cardId: 'card-1'));

    setupVaultWidgetSurface(tester);
    tester.view.physicalSize = const Size(2160, 2400);
    await tester.pumpWidget(vaultTestApp(home: const BankCardDetailsView()));
    await pumpVaultFrame(tester);

    expect(find.text('ماه'), findsOneWidget);
    expect(find.text('سال'), findsOneWidget);
    expect(find.text('06'), findsOneWidget);
    expect(find.text('30'), findsOneWidget);
    expect(find.byKey(const Key('vault-bank-card-copy-month')), findsOneWidget);
    expect(find.byKey(const Key('vault-bank-card-copy-year')), findsOneWidget);
  });

  testWidgets('bank card detail copies month and year independently', (
    tester,
  ) async {
    operations.vault = populatedVault();
    await vault.loadVault();
    Get.put(BankCardDetailsViewModel(cardId: 'card-1'));

    setupVaultWidgetSurface(tester);
    tester.view.physicalSize = const Size(2160, 2400);
    await tester.pumpWidget(vaultTestApp(home: const BankCardDetailsView()));
    await pumpVaultFrame(tester);

    final copied = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied.add((call.arguments as Map)['text'] as String);
        }
        return null;
      },
    );
    addTearDown(() {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      );
    });

    final monthCopy = find.byKey(const Key('vault-bank-card-copy-month'));
    final yearCopy = find.byKey(const Key('vault-bank-card-copy-year'));

    await tester.ensureVisible(monthCopy);
    await tester.pump();
    await tester.tap(monthCopy);
    await tester.pump();
    expect(copied, ['06']);

    await tester.ensureVisible(yearCopy);
    await tester.pump();
    await tester.tap(yearCopy);
    await tester.pump();
    expect(copied, ['06', '30']);
    AppToast.dismiss();
  });

  testWidgets('bank card expiry month is on the RTL start side of year', (
    tester,
  ) async {
    operations.vault = populatedVault();
    await vault.loadVault();
    Get.put(BankCardDetailsViewModel(cardId: 'card-1'));

    setupVaultWidgetSurface(tester);
    tester.view.physicalSize = const Size(2160, 2400);
    await tester.pumpWidget(vaultTestApp(home: const BankCardDetailsView()));
    await pumpVaultFrame(tester);

    final monthDx = tester
        .getTopLeft(find.byKey(const Key('vault-bank-card-copy-month')))
        .dx;
    final yearDx = tester
        .getTopLeft(find.byKey(const Key('vault-bank-card-copy-year')))
        .dx;
    expect(monthDx, greaterThan(yearDx));
  });

  testWidgets('secure note detail displays title, category, content and date', (
    tester,
  ) async {
    operations.vault = populatedVault();
    await vault.loadVault();
    Get.put(NoteDetailsViewModel(noteId: 'note-1'));

    setupVaultWidgetSurface(tester);
    await tester.pumpWidget(vaultTestApp(home: const NoteDetailsView()));
    await pumpVaultFrame(tester);

    expect(find.byKey(const Key('vault-note-details')), findsOneWidget);
    expect(find.text('Gate'), findsWidgets);
    expect(find.text('building-code-42'), findsOneWidget);
    expect(find.text('دسته‌بندی'), findsOneWidget);
    expect(find.text(CategoryConstants.withoutCategoryLabel), findsOneWidget);
    expect(find.text('تاریخ ایجاد'), findsOneWidget);
    expect(find.text(formatJalaliDate(createdAt)), findsOneWidget);
  });

  testWidgets('secure note detail shows named category', (tester) async {
    operations.vault = VaultData(
      version: VaultData.currentVersion,
      logins: const [],
      bankCards: const [],
      secureNotes: [
        SecureNoteItem(
          id: 'note-1',
          title: 'Gate',
          content: 'building-code-42',
          categoryId: 'cat-work',
          createdAt: createdAt,
          updatedAt: updatedAt,
        ),
      ],
      categories: [
        CategoryItem(
          id: 'cat-work',
          name: 'Work',
          icon: 'briefcase',
          createdAt: createdAt,
        ),
      ],
    );
    await vault.loadVault();
    Get.put(NoteDetailsViewModel(noteId: 'note-1'));

    setupVaultWidgetSurface(tester);
    await tester.pumpWidget(vaultTestApp(home: const NoteDetailsView()));
    await pumpVaultFrame(tester);

    expect(find.text('دسته‌بندی'), findsOneWidget);
    expect(find.text('Work'), findsOneWidget);
    expect(find.text(CategoryConstants.withoutCategoryLabel), findsNothing);
  });

  testWidgets('short note description uses at least five lines of height', (
    tester,
  ) async {
    operations.vault = populatedVault();
    await vault.loadVault();
    Get.put(NoteDetailsViewModel(noteId: 'note-1'));

    setupVaultWidgetSurface(tester);
    await tester.pumpWidget(vaultTestApp(home: const NoteDetailsView()));
    await pumpVaultFrame(tester);

    final size = tester.getSize(find.byKey(NoteDetailsView.descriptionKey));
    expect(
      size.height,
      greaterThanOrEqualTo(NoteDetailsView.descriptionMinHeight()),
    );
  });

  testWidgets('long note description grows without clipping or inner scroll', (
    tester,
  ) async {
    const longContent =
        'خط اول یادداشت\n'
        'خط دوم یادداشت\n'
        'خط سوم یادداشت\n'
        'خط چهارم یادداشت\n'
        'خط پنجم یادداشت\n'
        'خط ششم یادداشت\n'
        'خط هفتم یادداشت\n'
        'خط هشتم یادداشت که باید کامل دیده شود';

    operations.vault = VaultData(
      version: VaultData.currentVersion,
      logins: const [],
      bankCards: const [],
      secureNotes: [
        SecureNoteItem(
          id: 'note-1',
          title: 'Gate',
          content: longContent,
          categoryId: null,
          createdAt: createdAt,
          updatedAt: updatedAt,
        ),
      ],
      categories: const [],
    );
    await vault.loadVault();
    Get.put(NoteDetailsViewModel(noteId: 'note-1'));

    setupVaultWidgetSurface(tester);
    tester.view.physicalSize = const Size(1080, 3600);
    await tester.pumpWidget(vaultTestApp(home: const NoteDetailsView()));
    await pumpVaultFrame(tester);

    expect(find.text(longContent), findsOneWidget);
    expect(
      find.textContaining('خط هشتم یادداشت که باید کامل دیده شود'),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(NoteDetailsView.descriptionKey),
        matching: find.byType(SingleChildScrollView),
      ),
      findsNothing,
    );

    final size = tester.getSize(find.byKey(NoteDetailsView.descriptionKey));
    expect(size.height, greaterThan(NoteDetailsView.descriptionMinHeight()));
    expect(tester.takeException(), isNull);
  });

  testWidgets('login detail title updates after vault refresh', (tester) async {
    operations.vault = populatedVault();
    await vault.loadVault();
    Get.put(LoginDetailsViewModel(loginId: 'login-1'));

    setupVaultWidgetSurface(tester);
    await tester.pumpWidget(vaultTestApp(home: const LoginDetailsView()));
    await pumpVaultFrame(tester);
    expect(find.text('Mail'), findsWidgets);

    operations.vault = VaultData(
      version: VaultData.currentVersion,
      logins: [
        LoginItem(
          id: 'login-1',
          title: 'Updated Mail',
          username: 'keep-this-user',
          password: 'keep-this-password',
          website: 'https://mail.test',
          notes: null,
          categoryId: null,
          createdAt: createdAt,
          updatedAt: updatedAt,
        ),
      ],
      bankCards: const [],
      secureNotes: const [],
      categories: const [],
    );
    await vault.refreshVault();
    await pumpVaultFrame(tester);

    expect(find.text('Updated Mail'), findsWidgets);
    expect(find.text('Mail'), findsNothing);
  });
}
