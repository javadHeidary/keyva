import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:keyva/core/crypto/crypto_service_impl.dart';
import 'package:keyva/core/crypto/key_management_service_impl.dart';
import 'package:keyva/core/database/hive_database.dart';
import 'package:keyva/core/database/hive_user_data_source.dart';
import 'package:keyva/core/database/hive_vault_data_source.dart';
import 'package:keyva/core/exceptions/app_failure.dart';
import 'package:keyva/core/exceptions/result.dart';
import 'package:keyva/core/session/session_service_impl.dart';
import 'package:keyva/feature/auth/repository/auth_repository_impl.dart';
import 'package:keyva/feature/backup/model/backup_preview.dart';
import 'package:keyva/feature/backup/model/restore_progress.dart';
import 'package:keyva/feature/backup/service/backup_service_impl.dart';
import 'package:keyva/feature/vault/blob/encrypted_blob_store_impl.dart';
import 'package:keyva/feature/vault/model/image_folder.dart';
import 'package:keyva/feature/vault/model/image_item.dart';
import 'package:keyva/feature/vault/model/login_item.dart';
import 'package:keyva/feature/vault/model/vault_data.dart';
import 'package:keyva/feature/vault/repository/vault_repository.dart';
import 'package:keyva/feature/vault/repository/vault_repository_impl.dart';
import 'package:keyva/feature/vault/serialization/vault_serializer_impl.dart';
import 'package:keyva/feature/vault/service/vault_data_service_impl.dart';
import 'package:keyva/feature/vault/service/vault_operation_service_impl.dart';
import 'package:keyva/feature/vault/service/vault_unlock_service_impl.dart';
import 'package:keyva/feature/vault/session/vault_session_impl.dart';

import '../../core/security/support/fast_key_management_service.dart';

void main() {
  late Directory tempDir;
  HiveDatabase? database;
  late SessionServiceImpl session;
  late VaultSessionImpl vaultSession;
  late HiveUserDataSource users;
  late HiveVaultDataSource vaultRecords;
  late AuthRepositoryImpl auth;
  late VaultUnlockServiceImpl unlock;
  late VaultSerializerImpl serializer;
  late _InterceptingVaultRepository vaults;
  late VaultDataServiceImpl dataService;
  late EncryptedBlobStoreImpl blobs;
  late BackupServiceImpl backup;

  const oldMasterPassword = 'old-master-password';
  const backupPassword = 'backup-pass-1';
  const newMasterPassword = 'new-master-password';

  VaultData sampleVault() {
    return VaultData(
      version: VaultData.currentVersion,
      logins: [
        LoginItem(
          id: 'login-1',
          title: 'Mail',
          username: 'restored-user',
          password: 'restored-secret',
          website: null,
          notes: null,
          categoryId: null,
          createdAt: DateTime.utc(2026, 1, 1),
          updatedAt: DateTime.utc(2026, 1, 2),
        ),
      ],
      bankCards: const [],
      secureNotes: const [],
      categories: const [],
    );
  }

  const blobId = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
  const thumbId = 'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
  final photoBytes = Uint8List.fromList([7, 8, 9]);
  final thumbBytes = Uint8List.fromList([1, 2]);

  VaultData imageVault() {
    return VaultData(
      version: VaultData.currentVersion,
      logins: const [],
      bankCards: const [],
      secureNotes: const [],
      categories: const [],
      imageFolders: [
        ImageFolder(
          id: 'folder-1',
          title: 'ID photos',
          categoryId: null,
          createdAt: DateTime.utc(2026, 1, 1),
          updatedAt: DateTime.utc(2026, 1, 2),
        ),
      ],
      images: [
        ImageItem(
          id: 'photo-1',
          folderId: 'folder-1',
          note: null,
          blobId: blobId,
          thumbnailBlobId: thumbId,
          mimeType: 'image/jpeg',
          width: 12,
          height: 8,
          createdAt: DateTime.utc(2026, 1, 1),
        ),
      ],
    );
  }

  Future<Uint8List> backupBytes({VaultData? vault}) async {
    final created = _expectSuccess(
      await auth.createAccount(
        username: 'source',
        masterPassword: oldMasterPassword,
      ),
    );
    _expectSuccess(
      await unlock.unlock(
        userId: created.id,
        masterPassword: oldMasterPassword,
      ),
    );
    if (vault != null) {
      _expectSuccess(
        await blobs.writeWithId(blobId: blobId, plaintext: photoBytes),
      );
      _expectSuccess(
        await blobs.writeWithId(blobId: thumbId, plaintext: thumbBytes),
      );
    }
    _expectSuccess(await dataService.replaceVault(vault ?? sampleVault()));
    final bytes = _expectSuccess(
      await backup.createBackup(backupPassword: backupPassword),
    );
    final sourceId = created.id;
    _expectSuccess(await unlock.lock());
    _expectSuccess(await vaultRecords.delete(sourceId));
    _expectSuccess(await users.delete(sourceId));
    return bytes;
  }

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('keyva_backup_new_');
    database = await HiveDatabase.initialize(testDatabasePath: tempDir.path);
    final crypto = CryptoServiceImpl();
    final keys = FastKeyManagementService(KeyManagementServiceImpl(crypto));
    session = SessionServiceImpl();
    vaultSession = VaultSessionImpl();
    users = HiveUserDataSource(database!);
    vaultRecords = HiveVaultDataSource(database!);
    auth = AuthRepositoryImpl(
      users: users,
      crypto: crypto,
      keys: keys,
      session: session,
      database: database!,
      vaults: vaultRecords,
    );
    serializer = VaultSerializerImpl();
    blobs = EncryptedBlobStoreImpl(
      crypto: crypto,
      session: session,
      supportDirectory: () async => tempDir,
    );
    vaults = _InterceptingVaultRepository(
      VaultRepositoryImpl(
        vaults: vaultRecords,
        crypto: crypto,
        session: session,
      ),
    );
    dataService = VaultDataServiceImpl(
      serializer: serializer,
      vaults: vaults,
      vaultSession: vaultSession,
    );
    unlock = VaultUnlockServiceImpl(
      auth: auth,
      vaults: vaults,
      serializer: serializer,
      vaultSession: vaultSession,
      blobs: blobs,
    );
    backup = BackupServiceImpl(
      operations: VaultOperationServiceImpl(
        vaultData: dataService,
        vaultSession: vaultSession,
        blobs: blobs,
      ),
      vaultData: dataService,
      serializer: serializer,
      crypto: crypto,
      keys: keys,
      auth: auth,
      unlock: unlock,
      users: users,
      vaults: vaultRecords,
      blobs: blobs,
    );
  });

  tearDown(() async {
    await database?.close();
    database = null;
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('restore into a new account does not require a session or old master',
      () async {
    final bytes = await backupBytes();
    expect(_expectSuccess(await users.listIds()), isEmpty);

    _expectSuccess(await auth.logout());
    expect(session.isAuthenticated, isFalse);
    expect(vaultSession.isUnlocked, isFalse);

    final wrong = await backup.decryptBackup(
      bytes: bytes,
      backupPassword: 'wrong-backup',
    );
    expect(wrong, isA<FailureResult<BackupRestorePlan>>());
    expect(
      (wrong as FailureResult<BackupRestorePlan>).failure,
      isA<WrongBackupPasswordFailure>(),
    );
    expect(_expectSuccess(await users.listIds()), isEmpty);

    final plan = _expectSuccess(
      await backup.decryptBackup(bytes: bytes, backupPassword: backupPassword),
    );
    expect(plan.vault, sampleVault());

    final commitReports = <RestoreProgress>[];
    _expectSuccess(
      await backup.restoreIntoNewAccount(
        username: 'restored',
        masterPassword: newMasterPassword,
        vault: plan.vault,
        imageBlobs: plan.imageBlobs,
        onProgress: commitReports.add,
      ),
    );
    expect(
      commitReports.map((report) => report.stage),
      containsAll(<RestoreProgressStage>[
        RestoreProgressStage.preparingAccount,
        RestoreProgressStage.creatingAccount,
        RestoreProgressStage.unlocking,
        RestoreProgressStage.persisting,
        RestoreProgressStage.completed,
      ]),
    );
    expect(commitReports.last.percent, 100);
    expect(commitReports.last.stage, RestoreProgressStage.completed);
    expect(
      commitReports.every((report) => report.percent <= 100),
      isTrue,
    );

    expect(session.isAuthenticated, isTrue);
    expect(vaultSession.vaultData, sampleVault());
    final restoredId = session.current!.userId;
    expect(_expectSuccess(await users.listIds()), [restoredId]);

    _expectSuccess(await unlock.lock());
    expect(
      await unlock.unlock(
        userId: restoredId,
        masterPassword: backupPassword,
      ),
      isA<FailureResult<void>>(),
    );
    expect(
      await unlock.unlock(
        userId: restoredId,
        masterPassword: oldMasterPassword,
      ),
      isA<FailureResult<void>>(),
    );
    _expectSuccess(
      await unlock.unlock(
        userId: restoredId,
        masterPassword: newMasterPassword,
      ),
    );
    expect(vaultSession.vaultData, sampleVault());
  });

  test('restore into a new account rewrites image blobs with the new key',
      () async {
    final bytes = await backupBytes(vault: imageVault());
    _expectSuccess(await auth.logout());

    final plan = _expectSuccess(
      await backup.decryptBackup(bytes: bytes, backupPassword: backupPassword),
    );
    expect(plan.imageBlobs[blobId], photoBytes);

    _expectSuccess(
      await backup.restoreIntoNewAccount(
        username: 'restored',
        masterPassword: newMasterPassword,
        vault: plan.vault,
        imageBlobs: plan.imageBlobs,
      ),
    );

    blobs.clearCache();
    expect(_expectSuccess(await blobs.read(blobId)), photoBytes);
    expect(_expectSuccess(await blobs.read(thumbId)), thumbBytes);
    expect(vaultSession.vaultData!.imageFolders.single.title, 'ID photos');
  });

  test('persist failure rolls back the new account and image blobs', () async {
    final bytes = await backupBytes(vault: imageVault());
    _expectSuccess(await auth.logout());
    final before = _expectSuccess(await users.listIds());
    final blobRoot = Directory(
      '${tempDir.path}${Platform.pathSeparator}vault_blobs',
    );
    final beforeBlobDirs = blobRoot.existsSync()
        ? blobRoot.listSync().map((entity) => entity.path).toSet()
        : <String>{};

    final plan = _expectSuccess(
      await backup.decryptBackup(bytes: bytes, backupPassword: backupPassword),
    );
    vaults.nextSaveFailure = const DatabaseFailure();

    final reports = <RestoreProgress>[];
    final restored = await backup.restoreIntoNewAccount(
      username: 'restored',
      masterPassword: newMasterPassword,
      vault: plan.vault,
      imageBlobs: plan.imageBlobs,
      onProgress: reports.add,
    );
    expect(restored, isA<FailureResult<void>>());
    expect(reports.any((report) => report.isCompleted), isFalse);
    expect(reports.any((report) => report.percent >= 100), isFalse);
    expect(
      (restored as FailureResult<void>).failure,
      isA<BackupRestorePersistenceFailure>(),
    );
    expect(session.isAuthenticated, isFalse);
    expect(vaultSession.isUnlocked, isFalse);
    expect(_expectSuccess(await users.listIds()), before);
    final afterBlobDirs = blobRoot.existsSync()
        ? blobRoot.listSync().map((entity) => entity.path).toSet()
        : <String>{};
    expect(afterBlobDirs, beforeBlobDirs);
  });
}

class _InterceptingVaultRepository implements VaultRepository {
  _InterceptingVaultRepository(this._inner);

  final VaultRepository _inner;
  AppFailure? nextSaveFailure;

  @override
  Future<Result<Uint8List?>> loadVaultData() => _inner.loadVaultData();

  @override
  Future<Result<void>> saveVaultData(Uint8List plaintext) async {
    final failure = nextSaveFailure;
    if (failure != null) {
      nextSaveFailure = null;
      return FailureResult(failure);
    }
    return _inner.saveVaultData(plaintext);
  }

  @override
  Future<Result<void>> deleteVault() => _inner.deleteVault();
}

T _expectSuccess<T>(Result<T> result) {
  expect(result, isA<Success<T>>());
  return (result as Success<T>).data;
}
