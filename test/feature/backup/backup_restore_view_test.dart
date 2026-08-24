import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:keyva/core/di/injection_container.dart';
import 'package:keyva/core/exceptions/app_failure.dart';
import 'package:keyva/core/routes/app_routing.dart';
import 'package:keyva/core/session/session_service_impl.dart';
import 'package:keyva/core/theme/app_responsive.dart';
import 'package:keyva/core/theme/app_theme.dart';
import 'package:keyva/feature/backup/model/backup_file_result.dart';
import 'package:keyva/feature/backup/model/backup_preview.dart';
import 'package:keyva/feature/backup/model/restore_progress.dart';
import 'package:keyva/feature/backup/view/backup_restore_view.dart';
import 'package:keyva/feature/backup/viewmodel/backup_viewmodel.dart';
import 'package:keyva/feature/backup/viewmodel/restore_viewmodel.dart';
import 'package:keyva/feature/backup/widget/restore_new_account_success_dialog.dart';
import 'package:keyva/feature/backup/widget/restore_progress_overlay.dart';
import 'package:keyva/feature/settings/view/settings_view.dart';
import 'package:keyva/feature/settings/viewmodel/settings_viewmodel.dart';
import 'package:keyva/feature/vault/model/bank_card_item.dart';
import 'package:keyva/feature/vault/model/category_item.dart';
import 'package:keyva/feature/vault/model/login_item.dart';
import 'package:keyva/feature/vault/model/secure_note_item.dart';
import 'package:keyva/feature/vault/model/vault_data.dart';
import 'package:keyva/shared/widget/toast_widget.dart';

import '../auth/support/auth_widget_harness.dart';
import '../auth/support/fake_vault_unlock_service.dart';
import 'support/fake_backup_file_service.dart';
import 'support/fake_backup_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SessionServiceImpl session;
  late FakeBackupService backup;
  late FakeBackupFileService files;
  late BackupViewModel backupVm;
  late RestoreViewModel restoreVm;

  VaultData populatedVault() {
    return VaultData(
      version: VaultData.currentVersion,
      logins: [
        LoginItem(
          id: 'login-1',
          title: 'Work mail',
          username: 'preview-user',
          password: 'must-not-appear',
          website: null,
          notes: null,
          categoryId: 'cat-1',
          createdAt: DateTime.utc(2026, 1, 1),
          updatedAt: DateTime.utc(2026, 1, 2),
        ),
      ],
      bankCards: [
        BankCardItem(
          id: 'card-1',
          title: 'Main card',
          cardNumber: '6219860000000000',
          cardHolder: 'HIDDEN HOLDER',
          expiryDate: '12/29',
          cvv: '999',
          bankName: 'Test Bank',
          notes: null,
          categoryId: 'cat-1',
          createdAt: DateTime.utc(2026, 1, 1),
          updatedAt: DateTime.utc(2026, 1, 2),
        ),
      ],
      secureNotes: [
        SecureNoteItem(
          id: 'note-1',
          title: 'Safe note',
          content: 'must-not-appear-note',
          categoryId: 'cat-1',
          createdAt: DateTime.utc(2026, 1, 1),
          updatedAt: DateTime.utc(2026, 1, 2),
        ),
      ],
      categories: [
        CategoryItem(
          id: 'cat-1',
          name: 'Work',
          icon: 'work',
          createdAt: DateTime.utc(2026, 1, 1),
        ),
      ],
    );
  }

  final emptyVault = VaultData(
    version: VaultData.currentVersion,
    logins: const [],
    bankCards: const [],
    secureNotes: const [],
    categories: const [],
  );

  setUp(() async {
    Get.testMode = true;
    await getIt.reset();
    session = SessionServiceImpl();
    session.setAuthenticated(
      userId: 'user-1',
      username: 'test',
      vaultKey: Uint8List(32),
    );
    backup = FakeBackupService();
    files = FakeBackupFileService();
    backupVm = BackupViewModel(backup: backup, files: files, session: session);
    restoreVm = RestoreViewModel(
      backup: backup,
      files: files,
      session: session,
    );
  });

  tearDown(() async {
    AppToast.dismiss();
    Get.reset();
    await getIt.reset();
  });

  Future<void> pumpHub(WidgetTester tester) async {
    setupAuthWidgetSurface(tester);
    Get.put(backupVm);
    Get.put(restoreVm);
    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.light,
        locale: const Locale('fa', 'IR'),
        home: const BackupRestoreView(),
        builder: (context, child) {
          AppResponsive.init(context);
          return Directionality(
            textDirection: TextDirection.rtl,
            child: child!,
          );
        },
      ),
    );
    await pumpAuthSettle(tester);
  }

  testWidgets('settings shows the backup restore row', (tester) async {
    setupAuthWidgetSurface(tester);
    final unlock = FakeVaultUnlockService(session: session);
    Get.put(
      SettingsViewModel(unlock: unlock, session: session),
    );
    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.light,
        locale: const Locale('fa', 'IR'),
        home: const SettingsView(),
        builder: (context, child) {
          AppResponsive.init(context);
          return Directionality(
            textDirection: TextDirection.rtl,
            child: child!,
          );
        },
      ),
    );
    await pumpAuthSettle(tester);
    await tester.scrollUntilVisible(
      find.byKey(const Key('settings-backup-restore')),
      300,
      scrollable: find.byType(Scrollable),
    );
    expect(find.text('پشتیبان‌گیری و بازیابی'), findsWidgets);
  });

  testWidgets('hub shows backup and restore copy', (tester) async {
    await pumpHub(tester);
    expect(
      find.text('یک فایل رمزنگاری‌شده از اطلاعات Vault ایجاد کنید.'),
      findsOneWidget,
    );
    expect(
      find.text('اطمینان حاصل کنید که فایل پشتیبان متعلق به Keyva است.'),
      findsOneWidget,
    );
  });

  testWidgets('create backup validates password length', (tester) async {
    await pumpHub(tester);
    await tester.tap(find.byKey(const Key('backup-restore-create')));
    await pumpAuthSettle(tester);
    await tester.enterText(find.byKey(const Key('backup-create-password')), 'short');
    await tester.enterText(find.byKey(const Key('backup-create-confirm')), 'short');
    await tester.tap(find.byKey(const Key('backup-create-submit')));
    await pumpAuthSettle(tester);
    AppToast.dismiss();
    expect(backup.createCount, 0);
  });

  testWidgets('create backup requires matching confirmation', (tester) async {
    await pumpHub(tester);
    await tester.tap(find.byKey(const Key('backup-restore-create')));
    await pumpAuthSettle(tester);
    await tester.enterText(
      find.byKey(const Key('backup-create-password')),
      'backup-pass',
    );
    await tester.enterText(
      find.byKey(const Key('backup-create-confirm')),
      'different-pass',
    );
    await tester.tap(find.byKey(const Key('backup-create-submit')));
    await pumpAuthSettle(tester);
    AppToast.dismiss();
    expect(backup.createCount, 0);
  });

  testWidgets('create backup exports bytes and handles cancellation', (tester) async {
    files.exportResult = const BackupFileExportCancelled();
    await pumpHub(tester);
    await tester.tap(find.byKey(const Key('backup-restore-create')));
    await pumpAuthSettle(tester);
    await tester.enterText(
      find.byKey(const Key('backup-create-password')),
      'backup-pass',
    );
    await tester.enterText(
      find.byKey(const Key('backup-create-confirm')),
      'backup-pass',
    );
    await tester.tap(find.byKey(const Key('backup-create-submit')));
    await pumpAuthSettle(tester);
    expect(backup.createCount, 1);
    expect(files.exportCount, 1);
    expect(find.text('ایجاد پشتیبان'), findsWidgets);
  });

  testWidgets('create backup shows failure without exporting success', (tester) async {
    backup.createFailure = const CryptoFailure();
    await pumpHub(tester);
    await tester.tap(find.byKey(const Key('backup-restore-create')));
    await pumpAuthSettle(tester);
    await tester.enterText(
      find.byKey(const Key('backup-create-password')),
      'backup-pass',
    );
    await tester.enterText(
      find.byKey(const Key('backup-create-confirm')),
      'backup-pass',
    );
    await tester.tap(find.byKey(const Key('backup-create-submit')));
    await pumpAuthSettle(tester);
    expect(files.exportCount, 0);
    expect(find.text('پشتیبان‌گیری'), findsWidgets);
    expect(find.text('عملیات امنیتی انجام نشد.'), findsOneWidget);
    AppToast.dismiss();
  });

  testWidgets('create backup succeeds and closes the dialog', (tester) async {
    await pumpHub(tester);
    await tester.tap(find.byKey(const Key('backup-restore-create')));
    await pumpAuthSettle(tester);
    await tester.enterText(
      find.byKey(const Key('backup-create-password')),
      'backup-pass',
    );
    await tester.enterText(
      find.byKey(const Key('backup-create-confirm')),
      'backup-pass',
    );
    await tester.tap(find.byKey(const Key('backup-create-submit')));
    await pumpAuthSettle(tester);
    expect(files.lastFileName, contains('keyva_backup_'));
    expect(find.byKey(const Key('backup-create-submit')), findsNothing);
    AppToast.dismiss();
  });

  testWidgets('restore file picker cancellation does not start decrypt', (
    tester,
  ) async {
    files.pickResult = const BackupFilePickCancelled();
    await pumpHub(tester);
    await tester.tap(find.byKey(const Key('backup-restore-restore')));
    await pumpAuthSettle(tester);
    expect(backup.validateCount, 0);
    expect(find.byKey(const Key('backup-restore-password')), findsNothing);
  });

  testWidgets('restore rejects an invalid backup file', (tester) async {
    files.pickResult = BackupFilePicked(Uint8List.fromList([1, 2, 3]));
    backup.validateFailure = const InvalidBackupFormatFailure();
    await pumpHub(tester);
    await tester.tap(find.byKey(const Key('backup-restore-restore')));
    await pumpAuthSettle(tester);
    expect(find.text('بازیابی پشتیبان'), findsWidgets);
    expect(find.text('ساختار فایل پشتیبان معتبر نیست.'), findsOneWidget);
    expect(find.byKey(const Key('backup-restore-password')), findsNothing);
    AppToast.dismiss();
  });

  testWidgets('restore stays on password dialog for a wrong password', (
    tester,
  ) async {
    files.pickResult = BackupFilePicked(Uint8List.fromList([1, 2, 3]));
    backup.decryptFailure = const WrongBackupPasswordFailure();
    await pumpHub(tester);
    await tester.tap(find.byKey(const Key('backup-restore-restore')));
    await pumpAuthSettle(tester);
    await tester.enterText(
      find.byKey(const Key('backup-restore-password')),
      'backup-pass',
    );
    await tester.tap(find.byKey(const Key('backup-restore-submit')));
    await pumpAuthSettle(tester);
    expect(find.text('بازیابی پشتیبان'), findsWidgets);
    expect(find.text('رمز عبور فایل پشتیبان صحیح نیست.'), findsOneWidget);
    expect(find.byKey(const Key('backup-restore-submit')), findsOneWidget);
    expect(backup.restoreCount, 0);
    AppToast.dismiss();
  });

  testWidgets('restore preview shows item counts and hides secrets', (
    tester,
  ) async {
    final vault = populatedVault();
    files.pickResult = BackupFilePicked(Uint8List.fromList([1, 2, 3]));
    backup.plan = BackupRestorePlan(
      vault: vault,
      preview: BackupPreview.fromVault(vault),
    );
    await pumpHub(tester);
    await tester.tap(find.byKey(const Key('backup-restore-restore')));
    await pumpAuthSettle(tester);
    await tester.enterText(
      find.byKey(const Key('backup-restore-password')),
      'backup-pass',
    );
    await tester.tap(find.byKey(const Key('backup-restore-submit')));
    await pumpAuthSettle(tester);
    expect(find.text('هشدار'), findsOneWidget);
    expect(find.textContaining('اکانت: 1'), findsOneWidget);
    expect(find.textContaining('کارت بانکی: 1'), findsOneWidget);
    expect(find.textContaining('یادداشت امن: 1'), findsOneWidget);
    expect(find.textContaining('دسته‌بندی: 1'), findsOneWidget);
    expect(find.text('must-not-appear'), findsNothing);
    expect(find.text('6219860000000000'), findsNothing);
    expect(find.text('999'), findsNothing);
    expect(find.text('must-not-appear-note'), findsNothing);
    expect(backup.restoreCount, 0);
  });

  testWidgets('restore confirmation commits the replacement', (tester) async {
    files.pickResult = BackupFilePicked(Uint8List.fromList([1, 2, 3]));
    backup.plan = BackupRestorePlan(
      vault: emptyVault,
      preview: BackupPreview.fromVault(emptyVault),
    );
    await pumpHub(tester);
    await tester.tap(find.byKey(const Key('backup-restore-restore')));
    await pumpAuthSettle(tester);
    await tester.enterText(
      find.byKey(const Key('backup-restore-password')),
      'backup-pass',
    );
    await tester.tap(find.byKey(const Key('backup-restore-submit')));
    await pumpAuthSettle(tester);
    expect(find.text('هشدار'), findsOneWidget);
    expect(find.textContaining('اکانت: 0'), findsOneWidget);
    await tester.tap(find.text('جایگزینی'));
    await pumpAuthSettle(tester);
    expect(backup.restoreCount, 1);
    expect(backup.restored, emptyVault);
    AppToast.dismiss();
  });

  testWidgets('lock before confirm restore does not mutate the vault', (
    tester,
  ) async {
    files.pickResult = BackupFilePicked(Uint8List.fromList([1, 2, 3]));
    backup.plan = BackupRestorePlan(
      vault: emptyVault,
      preview: BackupPreview.fromVault(emptyVault),
    );
    await pumpHub(tester);
    await tester.tap(find.byKey(const Key('backup-restore-restore')));
    await pumpAuthSettle(tester);
    await tester.enterText(
      find.byKey(const Key('backup-restore-password')),
      'backup-pass',
    );
    await tester.tap(find.byKey(const Key('backup-restore-submit')));
    await pumpAuthSettle(tester);
    session.clear();
    await tester.tap(find.text('جایگزینی'));
    await pumpAuthSettle(tester);
    expect(backup.restoreCount, 0);
    expect(restoreVm.hasPendingRestore, isFalse);
    expect(find.text('اطلاعات Vault جایگزین شد'), findsNothing);
    AppToast.dismiss();
  });

  testWidgets('lock during restore does not show success or keep pending data', (
    tester,
  ) async {
    files.pickResult = BackupFilePicked(Uint8List.fromList([1, 2, 3]));
    backup.plan = BackupRestorePlan(
      vault: emptyVault,
      preview: BackupPreview.fromVault(emptyVault),
    );
    backup.restoreGate = Completer<void>();
    await pumpHub(tester);
    await tester.tap(find.byKey(const Key('backup-restore-restore')));
    await pumpAuthSettle(tester);
    await tester.enterText(
      find.byKey(const Key('backup-restore-password')),
      'backup-pass',
    );
    await tester.tap(find.byKey(const Key('backup-restore-submit')));
    await pumpAuthSettle(tester);
    await tester.tap(find.text('جایگزینی'));
    await tester.pump();
    expect(backup.restoreCount, 1);
    session.clear();
    backup.restoreGate!.complete();
    await pumpAuthSettle(tester);
    expect(find.text('اطلاعات Vault جایگزین شد'), findsNothing);
    expect(restoreVm.hasPendingRestore, isFalse);
    expect(find.byKey(const Key('backup-restore-restore')), findsOneWidget);
    AppToast.dismiss();
  });

  testWidgets('restore failure leaves the hub and does not hide the error', (
    tester,
  ) async {
    files.pickResult = BackupFilePicked(Uint8List.fromList([1, 2, 3]));
    backup.plan = BackupRestorePlan(
      vault: emptyVault,
      preview: BackupPreview.fromVault(emptyVault),
    );
    backup.restoreFailure = const BackupRestorePersistenceFailure();
    await pumpHub(tester);
    await tester.tap(find.byKey(const Key('backup-restore-restore')));
    await pumpAuthSettle(tester);
    await tester.enterText(
      find.byKey(const Key('backup-restore-password')),
      'backup-pass',
    );
    await tester.tap(find.byKey(const Key('backup-restore-submit')));
    await pumpAuthSettle(tester);
    await tester.tap(find.text('جایگزینی'));
    await pumpAuthSettle(tester);
    expect(find.text('بازیابی پشتیبان'), findsWidgets);
    expect(find.text('بازیابی اطلاعات انجام نشد.'), findsOneWidget);
    AppToast.dismiss();
  });

  testWidgets('restore cancel leaves the vault unmutated', (tester) async {
    files.pickResult = BackupFilePicked(Uint8List.fromList([1, 2, 3]));
    backup.plan = BackupRestorePlan(
      vault: emptyVault,
      preview: BackupPreview.fromVault(emptyVault),
    );
    await pumpHub(tester);
    await tester.tap(find.byKey(const Key('backup-restore-restore')));
    await pumpAuthSettle(tester);
    await tester.enterText(
      find.byKey(const Key('backup-restore-password')),
      'backup-pass',
    );
    await tester.tap(find.byKey(const Key('backup-restore-submit')));
    await pumpAuthSettle(tester);
    expect(find.byKey(const Key('backup-restore-cancel')), findsOneWidget);
    await tester.tap(find.byKey(const Key('backup-restore-cancel')));
    await pumpAuthSettle(tester);
    expect(backup.restoreCount, 0);
    expect(restoreVm.hasPendingRestore, isFalse);
  });

  testWidgets('logged-out restore hub hides create and does not require a session',
      (tester) async {
    session.clear();
    restoreVm = RestoreViewModel(
      backup: backup,
      files: files,
      session: session,
      mode: RestoreMode.createAccount,
    );
    files.pickResult = BackupFilePicked(Uint8List.fromList([1, 2, 3]));
    final vault = populatedVault();
    backup.plan = BackupRestorePlan(
      vault: vault,
      preview: BackupPreview.fromVault(vault),
    );
    setupAuthWidgetSurface(tester);
    Get.put(backupVm);
    Get.put(restoreVm);
    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.light,
        locale: const Locale('fa', 'IR'),
        home: const BackupRestoreView(createAccountMode: true),
        getPages: [
          GetPage(
            name: '/auth/restore/setup',
            page: () => const Scaffold(
              key: Key('restore-setup-page'),
              body: SizedBox.shrink(),
            ),
          ),
        ],
        builder: (context, child) {
          AppResponsive.init(context);
          return Directionality(
            textDirection: TextDirection.rtl,
            child: child!,
          );
        },
      ),
    );
    await pumpAuthSettle(tester);
    expect(find.byKey(const Key('backup-restore-create')), findsNothing);
    await tester.tap(find.byKey(const Key('backup-restore-restore')));
    await pumpAuthSettle(tester);
    await tester.enterText(
      find.byKey(const Key('backup-restore-password')),
      'backup-pass',
    );
    await tester.tap(find.byKey(const Key('backup-restore-submit')));
    await pumpAuthSettle(tester);
    expect(find.text('بازیابی پشتیبان'), findsWidgets);
    expect(find.text('جایگزینی'), findsNothing);
    expect(find.text('ادامه'), findsOneWidget);
    expect(find.text('must-not-appear'), findsNothing);
    await tester.tap(find.text('ادامه'));
    await pumpAuthSettle(tester);
    expect(backup.restoreCount, 0);
    expect(backup.restoreNewAccountCount, 0);
    expect(restoreVm.hasPendingRestore, isTrue);
  });

  testWidgets('new-account restore commits with a new master password',
      (tester) async {
    session.clear();
    restoreVm = RestoreViewModel(
      backup: backup,
      files: files,
      session: session,
      mode: RestoreMode.createAccount,
    );
    files.pickResult = BackupFilePicked(Uint8List.fromList([1, 2, 3]));
    backup.plan = BackupRestorePlan(
      vault: emptyVault,
      preview: BackupPreview.fromVault(emptyVault),
    );
    setupAuthWidgetSurface(tester);
    Get.put(restoreVm);
    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.light,
        locale: const Locale('fa', 'IR'),
        home: Builder(
          builder: (context) {
            return TextButton(
              key: const Key('run-restore'),
              onPressed: () async {
                await restoreVm.pickBackup(context);
                await restoreVm.decryptSelectedBackup(
                  password: 'backup-pass',
                  context: context,
                );
                restoreVm.usernameController.text = 'restored';
                restoreVm.passwordController.text = 'new-master-password';
                restoreVm.confirmPasswordController.text = 'new-master-password';
                await restoreVm.completeNewAccountRestore(context);
              },
              child: const Text('run'),
            );
          },
        ),
        getPages: [
          GetPage(
            name: AppRoutes.shell,
            page: () => const Scaffold(
              key: Key('shell-page'),
              body: SizedBox.shrink(),
            ),
          ),
        ],
        builder: (context, child) {
          AppResponsive.init(context);
          return child!;
        },
      ),
    );
    await tester.tap(find.byKey(const Key('run-restore')));
    await pumpAuthSettle(tester);
    expect(backup.restoreNewAccountCount, 1);
    expect(backup.lastNewAccountUsername, 'restored');
    expect(backup.lastNewAccountMasterPassword, 'new-master-password');
    expect(backup.lastPassword, 'backup-pass');
    expect(backup.lastNewAccountMasterPassword, isNot(backup.lastPassword));
    expect(backup.restoreCount, 0);
  });

  testWidgets('restore confirm ignores outside tap', (tester) async {
    files.pickResult = BackupFilePicked(Uint8List.fromList([1, 2, 3]));
    backup.plan = BackupRestorePlan(
      vault: emptyVault,
      preview: BackupPreview.fromVault(emptyVault),
    );
    await pumpHub(tester);
    await _reachConfirmDialog(tester);
    expect(find.text('هشدار'), findsOneWidget);
    await tester.tapAt(const Offset(8, 8));
    await tester.pump();
    expect(find.text('هشدار'), findsOneWidget);
    expect(backup.restoreCount, 0);
  });

  testWidgets('blocking restore overlay ignores back and outside tap', (
    tester,
  ) async {
    files.pickResult = BackupFilePicked(Uint8List.fromList([1, 2, 3]));
    backup.plan = BackupRestorePlan(
      vault: emptyVault,
      preview: BackupPreview.fromVault(emptyVault),
    );
    backup.restoreGate = Completer<void>();
    await pumpHub(tester);
    await _reachConfirmDialog(tester);
    await tester.tap(find.text('جایگزینی'));
    await tester.pump();
    expect(find.byKey(const Key('restore-progress-overlay')), findsOneWidget);
    expect(find.byKey(const Key('restore-progress-percent')), findsOneWidget);
    expect(find.text(RestoreProgressMessages.stayOpen), findsOneWidget);
    expect(restoreVm.progress.value?.percent, lessThan(100));

    await tester.tapAt(const Offset(8, 8));
    await tester.pump();
    expect(find.byKey(const Key('restore-progress-overlay')), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.byKey(const Key('restore-progress-overlay')), findsOneWidget);

    await tester.tap(
      find.byKey(const Key('backup-restore-restore')),
      warnIfMissed: false,
    );
    await tester.pump();
    expect(backup.restoreCount, 1);

    backup.restoreGate!.complete();
    await pumpAuthSettle(tester);
    expect(find.byKey(const Key('restore-progress-overlay')), findsNothing);
    expect(restoreVm.progress.value, isNull);
    expect(find.text('اطلاعات Vault جایگزین شد'), findsOneWidget);
    AppToast.dismiss();
  });

  testWidgets('restore failure removes the overlay and keeps the hub', (
    tester,
  ) async {
    files.pickResult = BackupFilePicked(Uint8List.fromList([1, 2, 3]));
    backup.plan = BackupRestorePlan(
      vault: emptyVault,
      preview: BackupPreview.fromVault(emptyVault),
    );
    backup.restoreFailure = const BackupRestorePersistenceFailure();
    await pumpHub(tester);
    await _reachConfirmDialog(tester);
    await tester.tap(find.text('جایگزینی'));
    await pumpAuthSettle(tester);
    expect(find.byKey(const Key('restore-progress-overlay')), findsNothing);
    expect(restoreVm.progress.value, isNull);
    expect(find.text('بازیابی پشتیبان'), findsWidgets);
    expect(find.text('بازیابی اطلاعات انجام نشد.'), findsOneWidget);
    expect(find.byKey(const Key('backup-restore-restore')), findsOneWidget);
    AppToast.dismiss();
  });

  testWidgets('decrypt overlay is removed after a wrong backup password', (
    tester,
  ) async {
    files.pickResult = BackupFilePicked(Uint8List.fromList([1, 2, 3]));
    backup.decryptFailure = const WrongBackupPasswordFailure();
    await pumpHub(tester);
    await tester.tap(find.byKey(const Key('backup-restore-restore')));
    await pumpAuthSettle(tester);
    await tester.enterText(
      find.byKey(const Key('backup-restore-password')),
      'backup-pass',
    );
    await tester.tap(find.byKey(const Key('backup-restore-submit')));
    await pumpAuthSettle(tester);
    expect(find.byKey(const Key('restore-progress-overlay')), findsNothing);
    expect(restoreVm.progress.value, isNull);
    expect(find.byKey(const Key('backup-restore-submit')), findsOneWidget);
    expect(find.byKey(const Key('backup-restore-password-cancel')), findsOneWidget);
    AppToast.dismiss();
  });

  testWidgets('new-account restore reports create and persist stages', (
    tester,
  ) async {
    session.clear();
    restoreVm = RestoreViewModel(
      backup: backup,
      files: files,
      session: session,
      mode: RestoreMode.createAccount,
    );
    files.pickResult = BackupFilePicked(Uint8List.fromList([1, 2, 3]));
    backup.plan = BackupRestorePlan(
      vault: emptyVault,
      preview: BackupPreview.fromVault(emptyVault),
    );
    backup.restoreNewAccountGate = Completer<void>();
    setupAuthWidgetSurface(tester);
    Get.put(restoreVm);
    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.light,
        locale: const Locale('fa', 'IR'),
        home: Builder(
          builder: (context) {
            return TextButton(
              key: const Key('run-restore-progress'),
              onPressed: () {
                runRestoreWithProgressOverlay(
                  context: context,
                  restore: restoreVm,
                  action: () async {
                    await restoreVm.pickBackup(context);
                    await restoreVm.decryptSelectedBackup(
                      password: 'backup-pass',
                      context: context,
                    );
                    restoreVm.usernameController.text = 'restored';
                    restoreVm.passwordController.text = 'new-master-password';
                    restoreVm.confirmPasswordController.text =
                        'new-master-password';
                    await restoreVm.completeNewAccountRestore(context);
                  },
                );
              },
              child: const Text('run'),
            );
          },
        ),
        getPages: [
          GetPage(
            name: AppRoutes.shell,
            page: () => const Scaffold(
              key: Key('shell-page'),
              body: SizedBox.shrink(),
            ),
          ),
        ],
        builder: (context, child) {
          AppResponsive.init(context);
          return child!;
        },
      ),
    );
    await tester.tap(find.byKey(const Key('run-restore-progress')));
    await tester.pump();
    expect(find.byKey(const Key('restore-progress-overlay')), findsOneWidget);
    expect(
      backup.restoreNewAccountProgress.map((report) => report.stage),
      containsAll(<RestoreProgressStage>[
        RestoreProgressStage.preparingAccount,
        RestoreProgressStage.creatingAccount,
        RestoreProgressStage.unlocking,
        RestoreProgressStage.persisting,
      ]),
    );
    expect(restoreVm.progress.value?.isCompleted, isNot(true));
    backup.restoreNewAccountGate!.complete();
    await pumpAuthSettle(tester);
    expect(find.byKey(const Key('restore-progress-overlay')), findsNothing);
    expect(backup.restoreNewAccountProgress.last.stage, RestoreProgressStage.completed);
    expect(backup.restoreNewAccountProgress.last.percent, 100);
  });

  testWidgets(
    'new-account restore shows a success dialog after 100% and waits for Got it',
    (tester) async {
      session.clear();
      restoreVm = RestoreViewModel(
        backup: backup,
        files: files,
        session: session,
        mode: RestoreMode.createAccount,
      );
      files.pickResult = BackupFilePicked(Uint8List.fromList([1, 2, 3]));
      backup.plan = BackupRestorePlan(
        vault: emptyVault,
        preview: BackupPreview.fromVault(emptyVault),
      );
      setupAuthWidgetSurface(tester);
      Get.put(restoreVm);
      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.light,
          locale: const Locale('fa', 'IR'),
          home: Builder(
            builder: (context) {
              return TextButton(
                key: const Key('run-restore-success'),
                onPressed: () async {
                  await restoreVm.pickBackup(context);
                  await restoreVm.decryptSelectedBackup(
                    password: 'backup-pass',
                    context: context,
                  );
                  restoreVm.usernameController.text = 'restored';
                  restoreVm.passwordController.text = 'new-master-password';
                  restoreVm.confirmPasswordController.text =
                      'new-master-password';
                  await runRestoreWithProgressOverlay(
                    context: context,
                    restore: restoreVm,
                    action: () => restoreVm.completeNewAccountRestore(context),
                  );
                  restoreVm.presentNewAccountRestoreSuccess(context);
                  restoreVm.presentNewAccountRestoreSuccess(context);
                },
                child: const Text('run'),
              );
            },
          ),
          getPages: [
            GetPage(
              name: AppRoutes.shell,
              page: () => const Scaffold(
                key: Key('shell-page'),
                body: SizedBox.shrink(),
              ),
            ),
            GetPage(
              name: AppRoutes.home,
              page: () => const Scaffold(
                key: Key('home-page'),
                body: SizedBox.shrink(),
              ),
            ),
          ],
          builder: (context, child) {
            AppResponsive.init(context);
            return child!;
          },
        ),
      );
      await tester.tap(find.byKey(const Key('run-restore-success')));
      await pumpAuthSettle(tester);

      expect(backup.restoreNewAccountProgress.last.percent, 100);
      expect(backup.restoreNewAccountProgress.last.stage, RestoreProgressStage.completed);
      expect(find.byKey(const Key('restore-progress-overlay')), findsNothing);
      expect(restoreVm.progress.value, isNull);
      expect(restoreVm.didCompleteNewAccountRestore, isTrue);
      expect(find.byKey(const Key('backup-restore-success-dialog')), findsOneWidget);
      expect(find.text(restoreNewAccountSuccessDescription), findsOneWidget);
      expect(find.byKey(const Key('shell-page')), findsNothing);

      await tester.tapAt(const Offset(8, 8));
      await tester.pump();
      expect(find.byKey(const Key('backup-restore-success-dialog')), findsOneWidget);

      await tester.tap(find.byKey(const Key('backup-restore-success-got-it')));
      await pumpAuthSettle(tester);
      expect(find.byKey(const Key('backup-restore-success-dialog')), findsNothing);
      expect(find.byKey(const Key('shell-page')), findsOneWidget);
    },
  );
}

Future<void> _reachConfirmDialog(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('backup-restore-restore')));
  await pumpAuthSettle(tester);
  await tester.enterText(
    find.byKey(const Key('backup-restore-password')),
    'backup-pass',
  );
  await tester.tap(find.byKey(const Key('backup-restore-submit')));
  await pumpAuthSettle(tester);
}
