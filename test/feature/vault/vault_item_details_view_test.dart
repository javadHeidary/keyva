import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:keyva/feature/home/viewmodel/home_viewmodel.dart';
import 'package:keyva/feature/type/bank_card/view/bank_card_details_view.dart';
import 'package:keyva/feature/type/bank_card/viewmodel/bank_card_details_viewmodel.dart';
import 'package:keyva/feature/type/login/view/login_details_view.dart';
import 'package:keyva/feature/type/login/viewmodel/login_details_viewmodel.dart';
import 'package:keyva/feature/type/note/view/note_details_view.dart';
import 'package:keyva/feature/type/note/viewmodel/note_details_viewmodel.dart';
import 'package:keyva/feature/vault/model/bank_card_item.dart';
import 'package:keyva/feature/vault/model/login_item.dart';
import 'package:keyva/feature/vault/model/secure_note_item.dart';
import 'package:keyva/feature/vault/model/vault_data.dart';
import 'package:keyva/feature/vault/viewmodel/vault_home_viewmodel.dart';

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
  });

  testWidgets('secure note detail displays title and content', (tester) async {
    operations.vault = populatedVault();
    await vault.loadVault();
    Get.put(NoteDetailsViewModel(noteId: 'note-1'));

    setupVaultWidgetSurface(tester);
    await tester.pumpWidget(vaultTestApp(home: const NoteDetailsView()));
    await pumpVaultFrame(tester);

    expect(find.byKey(const Key('vault-note-details')), findsOneWidget);
    expect(find.text('Gate'), findsWidgets);
    expect(find.text('building-code-42'), findsOneWidget);
    expect(find.text('تاریخ ایجاد'), findsNothing);
    expect(find.text('دسته‌بندی'), findsNothing);
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
