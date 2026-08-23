import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:keyva/core/crypto/crypto_service_impl.dart';
import 'package:keyva/core/crypto/key_management_service_impl.dart';
import 'package:keyva/core/database/hive_database.dart';
import 'package:keyva/core/database/hive_user_data_source.dart';
import 'package:keyva/core/database/hive_vault_data_source.dart';
import 'package:keyva/core/exceptions/result.dart';
import 'package:keyva/core/session/session_service_impl.dart';
import 'package:keyva/feature/auth/repository/auth_repository_impl.dart';
import 'package:keyva/feature/backup/service/backup_service_impl.dart';
import 'package:keyva/feature/vault/model/login_item.dart';
import 'package:keyva/feature/vault/model/vault_data.dart';
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
  late AuthRepositoryImpl auth;
  late VaultUnlockServiceImpl unlock;
  late VaultDataServiceImpl dataService;
  late BackupServiceImpl backup;

  const masterA = 'master-password-a';
  const masterB = 'master-password-b';

  VaultData vaultWithTitle(String title) {
    return VaultData(
      version: VaultData.currentVersion,
      logins: [
        LoginItem(
          id: 'login-$title',
          title: title,
          username: title,
          password: 'secret-$title',
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

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('keyva_backup_multi_');
    database = await HiveDatabase.initialize(testDatabasePath: tempDir.path);
    final crypto = CryptoServiceImpl();
    final keys = FastKeyManagementService(KeyManagementServiceImpl(crypto));
    session = SessionServiceImpl();
    vaultSession = VaultSessionImpl();
    final users = HiveUserDataSource(database!);
    final vaultRecords = HiveVaultDataSource(database!);
    auth = AuthRepositoryImpl(
      users: users,
      crypto: crypto,
      keys: keys,
      session: session,
      database: database!,
    );
    final serializer = VaultSerializerImpl();
    final repository = VaultRepositoryImpl(
      vaults: vaultRecords,
      crypto: crypto,
      session: session,
    );
    dataService = VaultDataServiceImpl(
      serializer: serializer,
      vaults: repository,
      vaultSession: vaultSession,
    );
    unlock = VaultUnlockServiceImpl(
      auth: auth,
      vaults: repository,
      serializer: serializer,
      vaultSession: vaultSession,
    );
    backup = BackupServiceImpl(
      operations: VaultOperationServiceImpl(
        vaultData: dataService,
        vaultSession: vaultSession,
      ),
      vaultData: dataService,
      serializer: serializer,
      crypto: crypto,
      keys: keys,
      auth: auth,
      unlock: unlock,
      users: users,
      vaults: vaultRecords,
    );
  });

  tearDown(() async {
    await database?.close();
    database = null;
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('restoring into account A does not change account B', () async {
    final accountA = _expectSuccess(
      await auth.createAccount(username: 'alpha', masterPassword: masterA),
    );
    _expectSuccess(
      await unlock.unlock(userId: accountA.id, masterPassword: masterA),
    );
    final vaultA = vaultWithTitle('Alpha');
    _expectSuccess(await dataService.replaceVault(vaultA));
    _expectSuccess(await unlock.lock());

    final accountB = _expectSuccess(
      await auth.createAccount(username: 'beta', masterPassword: masterB),
    );
    _expectSuccess(
      await unlock.unlock(userId: accountB.id, masterPassword: masterB),
    );
    final vaultB = vaultWithTitle('Beta');
    _expectSuccess(await dataService.replaceVault(vaultB));

    final restored = vaultWithTitle('Restored');
    _expectSuccess(await backup.restoreVault(restored));
    expect(vaultSession.vaultData, restored);
    expect(session.current!.userId, accountB.id);

    _expectSuccess(await unlock.lock());
    _expectSuccess(
      await unlock.unlock(userId: accountA.id, masterPassword: masterA),
    );
    expect(session.current!.userId, accountA.id);
    expect(vaultSession.vaultData, vaultA);

    _expectSuccess(await unlock.lock());
    _expectSuccess(
      await unlock.unlock(userId: accountB.id, masterPassword: masterB),
    );
    expect(session.current!.userId, accountB.id);
    expect(vaultSession.vaultData, restored);
  });
}

T _expectSuccess<T>(Result<T> result) {
  expect(result, isA<Success<T>>());
  return (result as Success<T>).data;
}
