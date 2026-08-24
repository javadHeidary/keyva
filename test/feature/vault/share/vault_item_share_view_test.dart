import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:keyva/shared/icons/app_icons.dart';

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

  LoginItem login() {
    return LoginItem(
      id: 'login-1',
      title: 'Mail',
      username: 'keep-this-user',
      password: 'keep-this-password',
      website: null,
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
  }

  setUp(() {
    Get.testMode = true;
    operations = FakeVaultOperationService();
    vault = VaultHomeViewModel(operations: operations);
    shareSheet = FakeShareSheetService();
    Get.put(vault);
    Get.put(HomeController(vault: vault));
  });

  tearDown(Get.reset);

  testWidgets('each details screen shows a share icon', (tester) async {
    operations.vault = populatedVault();
    await vault.loadVault();

    Get.put(LoginDetailsViewModel(loginId: 'login-1', shareSheet: shareSheet));
    setupVaultWidgetSurface(tester);
    await tester.pumpWidget(vaultTestApp(home: const LoginDetailsView()));
    await pumpVaultFrame(tester);
    expect(find.byKey(const Key('vault-item-share')), findsOneWidget);
    expect(find.byIcon(AppIcon.share), findsOneWidget);
    Get.delete<LoginDetailsViewModel>(force: true);

    Get.put(
      BankCardDetailsViewModel(cardId: 'card-1', shareSheet: shareSheet),
    );
    tester.view.physicalSize = const Size(2160, 2400);
    await tester.pumpWidget(vaultTestApp(home: const BankCardDetailsView()));
    await pumpVaultFrame(tester);
    expect(find.byKey(const Key('vault-item-share')), findsOneWidget);
    Get.delete<BankCardDetailsViewModel>(force: true);

    Get.put(NoteDetailsViewModel(noteId: 'note-1', shareSheet: shareSheet));
    await tester.pumpWidget(vaultTestApp(home: const NoteDetailsView()));
    await pumpVaultFrame(tester);
    expect(find.byKey(const Key('vault-item-share')), findsOneWidget);
  });

  testWidgets('share cancel does not invoke native share or clipboard', (
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

    operations.vault = populatedVault();
    await vault.loadVault();
    Get.put(LoginDetailsViewModel(loginId: 'login-1', shareSheet: shareSheet));
    setupVaultWidgetSurface(tester);
    await tester.pumpWidget(vaultTestApp(home: const LoginDetailsView()));
    await pumpVaultFrame(tester);

    await tester.tap(find.byKey(const Key('vault-item-share')));
    await tester.pumpAndSettle();
    expect(find.text('اشتراک‌گذاری'), findsWidgets);

    await tester.tap(find.byKey(const Key('vault-item-share-cancel')));
    await tester.pumpAndSettle();

    expect(shareSheet.shareCount, 0);
    expect(copied, isEmpty);
  });

  testWidgets('share confirm invokes native share with omitted empty fields', (
    tester,
  ) async {
    operations.vault = populatedVault();
    await vault.loadVault();
    Get.put(LoginDetailsViewModel(loginId: 'login-1', shareSheet: shareSheet));
    setupVaultWidgetSurface(tester);
    await tester.pumpWidget(vaultTestApp(home: const LoginDetailsView()));
    await pumpVaultFrame(tester);

    await tester.tap(find.byKey(const Key('vault-item-share')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('vault-item-share-confirm')));
    await tester.pumpAndSettle();

    expect(shareSheet.shareCount, 1);
    expect(shareSheet.lastText, contains('Keyva — اطلاعات اکانت'));
    expect(shareSheet.lastText, contains('عنوان: Mail'));
    expect(shareSheet.lastText, isNot(contains('وب‌سایت')));
    expect(shareSheet.lastText, isNot(contains('یادداشت')));
    expect(shareSheet.lastSubject, 'Keyva — اطلاعات اکانت');
  });
}
