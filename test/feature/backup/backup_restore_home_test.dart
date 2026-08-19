import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:keyva/core/exceptions/result.dart';
import 'package:keyva/core/session/session_service_impl.dart';
import 'package:keyva/feature/backup/model/backup_file_result.dart';
import 'package:keyva/feature/backup/model/backup_preview.dart';
import 'package:keyva/feature/backup/viewmodel/restore_viewmodel.dart';
import 'package:keyva/feature/home/view/home_view.dart';
import 'package:keyva/feature/home/viewmodel/home_viewmodel.dart';
import 'package:keyva/feature/search/viewmodel/search_viewmodel.dart';
import 'package:keyva/feature/vault/model/login_item.dart';
import 'package:keyva/feature/vault/model/vault_data.dart';
import 'package:keyva/feature/vault/viewmodel/vault_home_viewmodel.dart';
import 'package:keyva/shared/widget/app_search_widget.dart';
import 'package:keyva/shared/widget/toast_widget.dart';

import '../vault/support/fake_vault_operation_service.dart';
import '../vault/support/vault_widget_harness.dart';
import 'support/fake_backup_file_service.dart';
import 'support/fake_backup_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeVaultOperationService operations;
  late VaultHomeViewModel vaultHome;
  late HomeController home;
  late SessionServiceImpl session;
  late _HomeAwareBackupService backup;
  late FakeBackupFileService files;
  late RestoreViewModel restore;

  final createdAt = DateTime.utc(2026, 8, 1);
  final updatedAt = DateTime.utc(2026, 8, 2);

  VaultData vaultA() {
    return VaultData(
      version: VaultData.currentVersion,
      logins: [
        LoginItem(
          id: 'login-a',
          title: 'Alpha Mail',
          username: 'alpha-user',
          password: 'alpha-secret',
          website: null,
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
  }

  VaultData vaultB() {
    return VaultData(
      version: VaultData.currentVersion,
      logins: [
        LoginItem(
          id: 'login-b',
          title: 'Beta Mail',
          username: 'beta-user',
          password: 'beta-secret',
          website: null,
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
  }

  setUp(() {
    Get.testMode = true;
    operations = FakeVaultOperationService()..vault = vaultA();
    vaultHome = VaultHomeViewModel(operations: operations);
    home = HomeController(vault: vaultHome);
    session = SessionServiceImpl();
    session.setAuthenticated(
      userId: 'user-1',
      username: 'owner',
      vaultKey: Uint8List(32),
    );
    backup = _HomeAwareBackupService(operations);
    files = FakeBackupFileService();
    restore = RestoreViewModel(
      backup: backup,
      files: files,
      session: session,
    );
    Get.put(vaultHome);
    Get.put(home);
    Get.put(restore);
  });

  tearDown(() {
    AppToast.dismiss();
    Get.reset();
  });

  testWidgets('restore replaces Home and Search snapshots with Vault B', (
    tester,
  ) async {
    await vaultHome.loadVault();
    Get.put(SearchViewModel());
    home.searchItems('Alpha');

    setupVaultWidgetSurface(tester);
    await tester.pumpWidget(vaultTestApp(home: const HomeView()));
    await pumpVaultFrame(tester);

    expect(find.byKey(const Key('vault-item-login-a')), findsOneWidget);
    expect(find.text('Alpha Mail'), findsOneWidget);
    expect(find.text('alpha-user'), findsOneWidget);
    expect(find.text('Beta Mail'), findsNothing);
    expect(find.text('alpha-secret'), findsNothing);

    final search = Get.find<SearchViewModel>();
    search.searchQuery.value = 'Alpha';
    expect(search.results.map((item) => item.title), ['Alpha Mail']);

    files.pickResult = BackupFilePicked(Uint8List.fromList([1, 2, 3]));
    backup.plan = BackupRestorePlan(
      vault: vaultB(),
      preview: BackupPreview.fromVault(vaultB()),
    );

    final context = tester.element(find.byType(HomeView));
    expect(await restore.pickBackup(context), isTrue);
    expect(
      await restore.decryptSelectedBackup(
        password: 'backup-pass',
        context: context,
      ),
      isNotNull,
    );
    await restore.confirmRestore(context);
    await tester.pump(const Duration(milliseconds: 350));
    await pumpVaultFrame(tester);

    expect(find.byKey(const Key('vault-item-login-a')), findsNothing);
    expect(find.text('Alpha Mail'), findsNothing);
    expect(find.text('alpha-user'), findsNothing);
    expect(find.byKey(const Key('vault-item-login-b')), findsOneWidget);
    expect(find.text('Beta Mail'), findsOneWidget);
    expect(find.text('beta-user'), findsOneWidget);
    expect(find.text('beta-secret'), findsNothing);
    expect(search.results.map((item) => item.title), ['Beta Mail']);
    expect(search.searchQuery.value, isEmpty);

    await tester.pumpWidget(vaultTestApp(home: const AppSearchWidget()));
    await tester.pump(const Duration(milliseconds: 350));
    await pumpVaultFrame(tester);
    expect(find.text('Beta Mail'), findsOneWidget);
    expect(find.text('Alpha Mail'), findsNothing);
    AppToast.dismiss();
  });
}

class _HomeAwareBackupService extends FakeBackupService {
  _HomeAwareBackupService(this.operations);

  final FakeVaultOperationService operations;

  @override
  Future<Result<void>> restoreVault(VaultData vault) async {
    final restored = await super.restoreVault(vault);
    if (restored is Success<void>) {
      operations.vault = vault;
    }
    return restored;
  }
}
