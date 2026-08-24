import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:keyva/feature/home/viewmodel/home_viewmodel.dart';
import 'package:keyva/feature/type/bank_card/viewmodel/bank_card_details_viewmodel.dart';
import 'package:keyva/feature/type/login/viewmodel/login_details_viewmodel.dart';
import 'package:keyva/feature/type/note/viewmodel/note_details_viewmodel.dart';
import 'package:keyva/feature/vault/model/bank_card_item.dart';
import 'package:keyva/feature/vault/model/login_item.dart';
import 'package:keyva/feature/vault/model/secure_note_item.dart';
import 'package:keyva/feature/vault/model/vault_data.dart';
import 'package:keyva/feature/vault/share/share_sheet_service.dart';
import 'package:keyva/feature/vault/share/vault_item_share_formatter.dart';
import 'package:keyva/feature/vault/viewmodel/vault_home_viewmodel.dart';
import 'package:keyva/shared/widget/toast_widget.dart';

import '../support/fake_share_sheet_service.dart';
import '../support/fake_vault_operation_service.dart';
import '../support/vault_widget_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeVaultOperationService operations;
  late VaultHomeViewModel vault;
  late FakeShareSheetService shareSheet;

  final createdAt = DateTime.utc(2026, 7, 1, 10);
  final updatedAt = DateTime.utc(2026, 7, 2, 11);
  const formatter = VaultItemShareFormatter();

  LoginItem loginItem() {
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

  setUp(() {
    Get.testMode = true;
    operations = FakeVaultOperationService();
    vault = VaultHomeViewModel(operations: operations);
    shareSheet = FakeShareSheetService();
    Get.put(vault);
    Get.put(HomeController(vault: vault));
  });

  tearDown(() {
    AppToast.dismiss();
    Get.reset();
  });

  Future<void> pumpHost(WidgetTester tester) async {
    operations.vault = VaultData(
      version: VaultData.currentVersion,
      logins: [loginItem()],
      bankCards: [
        BankCardItem(
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
        ),
      ],
      secureNotes: [
        SecureNoteItem(
          id: 'note-1',
          title: 'Gate',
          content: 'building-code-42',
          categoryId: null,
          createdAt: createdAt,
          updatedAt: updatedAt,
        ),
      ],
      categories: const [],
    );
    await vault.loadVault();
    setupVaultWidgetSurface(tester);
    await tester.pumpWidget(
      vaultTestApp(home: const SizedBox.shrink(key: Key('share-host'))),
    );
    await pumpVaultFrame(tester);
  }

  Future<void> shareFromHost(
    WidgetTester tester,
    Future<void> Function(BuildContext context) share,
  ) {
    return share(tester.element(find.byKey(const Key('share-host'))));
  }

  testWidgets('login confirm shares formatted text and skips clipboard', (
    tester,
  ) async {
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

    final vm = LoginDetailsViewModel(
      loginId: 'login-1',
      shareSheet: shareSheet,
      confirmShare: (_) async => true,
    );
    Get.put(vm);
    await pumpHost(tester);
    await shareFromHost(tester, vm.shareItem);

    expect(shareSheet.shareCount, 1);
    expect(
      shareSheet.lastText,
      formatter.formatLogin(loginItem(), categoryName: vm.categoryLabel),
    );
    expect(shareSheet.lastSubject, VaultItemShareFormatter.loginSubject);
    expect(copied, isEmpty);
  });

  testWidgets('login cancel does not invoke the share sheet', (tester) async {
    final vm = LoginDetailsViewModel(
      loginId: 'login-1',
      shareSheet: shareSheet,
      confirmShare: (_) async => false,
    );
    Get.put(vm);
    await pumpHost(tester);
    await shareFromHost(tester, vm.shareItem);

    expect(shareSheet.shareCount, 0);
    expect(shareSheet.lastText, isNull);
  });

  testWidgets('dismissed share does not show an error toast', (tester) async {
    shareSheet.result = ShareSheetResult.dismissed;
    final vm = LoginDetailsViewModel(
      loginId: 'login-1',
      shareSheet: shareSheet,
      confirmShare: (_) async => true,
    );
    Get.put(vm);
    await pumpHost(tester);
    await shareFromHost(tester, vm.shareItem);
    await tester.pump();

    expect(shareSheet.shareCount, 1);
    expect(find.text('اشتراک‌گذاری انجام نشد'), findsNothing);
  });

  testWidgets('unavailable share shows a generic error', (tester) async {
    shareSheet.result = ShareSheetResult.unavailable;
    final vm = LoginDetailsViewModel(
      loginId: 'login-1',
      shareSheet: shareSheet,
      confirmShare: (_) async => true,
    );
    Get.put(vm);
    await pumpHost(tester);
    await shareFromHost(tester, vm.shareItem);
    await tester.pump();

    expect(find.text('اشتراک‌گذاری انجام نشد'), findsOneWidget);
    AppToast.dismiss();
  });

  testWidgets('bank card and note share use their own templates', (tester) async {
    final cardVm = BankCardDetailsViewModel(
      cardId: 'card-1',
      shareSheet: shareSheet,
      confirmShare: (_) async => true,
    );
    Get.put(cardVm);
    await pumpHost(tester);
    await shareFromHost(tester, cardVm.shareItem);
    expect(shareSheet.lastSubject, VaultItemShareFormatter.cardSubject);
    expect(shareSheet.lastText, contains('CVV2: 321'));
    expect(shareSheet.lastText, contains('تاریخ انقضا: 06 / 30'));

    final noteShare = FakeShareSheetService();
    final noteVm = NoteDetailsViewModel(
      noteId: 'note-1',
      shareSheet: noteShare,
      confirmShare: (_) async => true,
    );
    Get.put(noteVm);
    await shareFromHost(tester, noteVm.shareItem);
    expect(noteShare.lastSubject, VaultItemShareFormatter.noteSubject);
    expect(noteShare.lastText, contains('توضیحات:\nbuilding-code-42'));
  });
}
