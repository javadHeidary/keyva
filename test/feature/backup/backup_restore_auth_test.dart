import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:keyva/core/crypto/crypto_service_impl.dart';
import 'package:keyva/core/crypto/key_management_service_impl.dart';
import 'package:keyva/core/database/hive_database.dart';
import 'package:keyva/core/database/hive_user_data_source.dart';
import 'package:keyva/core/database/hive_vault_data_source.dart';
import 'package:keyva/core/exceptions/result.dart';
import 'package:keyva/core/security/biometric_service_impl.dart';
import 'package:keyva/core/security/pin_service_impl.dart';
import 'package:keyva/core/security/unlock_attempt_limiter.dart';
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

import '../../core/security/support/fake_biometric_gateway.dart';
import '../../core/security/support/fast_key_management_service.dart';
import '../../core/security/support/memory_secure_storage.dart';

void main() {
  late Directory tempDir;
  HiveDatabase? database;
  late SessionServiceImpl session;
  late VaultSessionImpl vaultSession;
  late AuthRepositoryImpl auth;
  late PinServiceImpl pin;
  late BiometricServiceImpl biometric;
  late FakeBiometricGateway gateway;
  late VaultUnlockServiceImpl unlock;
  late BackupServiceImpl backup;
  late VaultDataServiceImpl dataService;

  const masterPassword = 'correct-master-password';
  const backupPassword = 'backup-pass-1';
  const pinCode = '123456';

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('keyva_backup_auth_');
    database = await HiveDatabase.initialize(testDatabasePath: tempDir.path);
    final crypto = CryptoServiceImpl();
    final keys = FastKeyManagementService(KeyManagementServiceImpl(crypto));
    session = SessionServiceImpl();
    vaultSession = VaultSessionImpl();
    final users = HiveUserDataSource(database!);
    final vaults = HiveVaultDataSource(database!);
    final storage = MemorySecureStorageService();
    gateway = FakeBiometricGateway();
    auth = AuthRepositoryImpl(
      users: users,
      crypto: crypto,
      keys: keys,
      session: session,
      database: database!,
    );
    pin = PinServiceImpl(
      crypto: crypto,
      keys: keys,
      storage: storage,
      users: users,
      session: session,
      attempts: UnlockAttemptLimiter(database: database!),
    );
    biometric = BiometricServiceImpl(
      gateway: gateway,
      keys: keys,
      storage: storage,
      users: users,
      session: session,
      attempts: UnlockAttemptLimiter(database: database!),
    );
    final serializer = VaultSerializerImpl();
    final repository = VaultRepositoryImpl(
      vaults: vaults,
      crypto: crypto,
      session: session,
    );
    dataService = VaultDataServiceImpl(
      serializer: serializer,
      vaults: repository,
      vaultSession: vaultSession,
    );
    final operations = VaultOperationServiceImpl(
      vaultData: dataService,
      vaultSession: vaultSession,
    );
    unlock = VaultUnlockServiceImpl(
      auth: auth,
      vaults: repository,
      serializer: serializer,
      vaultSession: vaultSession,
      pin: pin,
      biometric: biometric,
    );
    backup = BackupServiceImpl(
      operations: operations,
      vaultData: dataService,
      serializer: serializer,
      crypto: crypto,
      keys: keys,
    );
  });

  tearDown(() async {
    await database?.close();
    database = null;
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  Future<String> unlockAccount() async {
    final created = _expectSuccess(
      await auth.createAccount(
        username: 'علی',
        masterPassword: masterPassword,
      ),
    );
    _expectSuccess(
      await unlock.unlock(
        userId: created.id,
        masterPassword: masterPassword,
      ),
    );
    return created.id;
  }

  test('restore keeps master password, PIN, biometric, and vault key', () async {
    final userId = await unlockAccount();
    final original = VaultData(
      version: VaultData.currentVersion,
      logins: [
        LoginItem(
          id: 'login-1',
          title: 'Mail',
          username: 'user',
          password: 'secret',
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
    _expectSuccess(await dataService.replaceVault(original));
    _expectSuccess(await pin.enable(pinCode));
    _expectSuccess(await biometric.enable(localizedReason: 'enable'));

    final sessionKey = session.vaultKey!;
    final originalKey = Uint8List.fromList(sessionKey);
    final bytes = _expectSuccess(
      await backup.createBackup(backupPassword: backupPassword),
    );

    _expectSuccess(
      await dataService.replaceVault(
        VaultData(
          version: VaultData.currentVersion,
          logins: const [],
          bankCards: const [],
          secureNotes: const [],
          categories: const [],
        ),
      ),
    );

    final plan = _expectSuccess(
      await backup.decryptBackup(bytes: bytes, backupPassword: backupPassword),
    );
    _expectSuccess(await backup.restoreVault(plan.vault));

    expect(identical(session.vaultKey, sessionKey), isTrue);
    expect(session.vaultKey, originalKey);
    expect(vaultSession.vaultData, original);

    final pinKey = _expectSuccess(
      await pin.unwrapVaultKey(userId: userId, pin: pinCode),
    );
    expect(pinKey, originalKey);

    final bioKey = _expectSuccess(
      await biometric.unwrapVaultKey(userId: userId, localizedReason: 'unlock'),
    );
    expect(bioKey, originalKey);

    _expectSuccess(await unlock.lock());
    _expectSuccess(
      await unlock.unlock(userId: userId, masterPassword: masterPassword),
    );
    expect(session.vaultKey, originalKey);
    expect(vaultSession.vaultData, original);
  });
}

T _expectSuccess<T>(Result<T> result) {
  expect(result, isA<Success<T>>());
  return (result as Success<T>).data;
}
