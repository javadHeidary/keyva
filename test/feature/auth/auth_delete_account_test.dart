import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:keyva/core/constants/database_constants.dart';
import 'package:keyva/core/constants/security_constants.dart';
import 'package:keyva/core/crypto/crypto_service_impl.dart';
import 'package:keyva/core/crypto/key_management_service_impl.dart';
import 'package:keyva/core/database/hive_database.dart';
import 'package:keyva/core/database/hive_user_data_source.dart';
import 'package:keyva/core/database/hive_vault_data_source.dart';
import 'package:keyva/core/database/models/user_record.dart';
import 'package:keyva/core/database/models/vault_record.dart';
import 'package:keyva/core/database/user_data_source.dart';
import 'package:keyva/core/exceptions/app_failure.dart';
import 'package:keyva/core/exceptions/result.dart';
import 'package:keyva/core/security/fast_unlock_storage_keys.dart';
import 'package:keyva/core/security/unlock_attempt_limiter.dart';
import 'package:keyva/core/session/session_service_impl.dart';
import 'package:keyva/feature/auth/model/account_deletion_outcome.dart';
import 'package:keyva/feature/auth/repository/auth_repository_impl.dart';

import '../../core/security/support/fast_key_management_service.dart';
import '../../core/security/support/memory_secure_storage.dart';

void main() {
  late Directory tempDir;
  HiveDatabase? database;
  late HiveUserDataSource users;
  late HiveVaultDataSource vaults;
  late SessionServiceImpl session;
  late MemorySecureStorageService storage;
  late UnlockAttemptLimiter attempts;
  late CryptoServiceImpl crypto;
  late FastKeyManagementService keys;
  late AuthRepositoryImpl auth;

  const kdfTimeout = Timeout(Duration(minutes: 2));
  const password = 'correct-master-password';
  const otherPassword = 'other-master-password';

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('keyva_delete_account_');
    database = await HiveDatabase.initialize(testDatabasePath: tempDir.path);
    users = HiveUserDataSource(database!);
    vaults = HiveVaultDataSource(database!);
    crypto = CryptoServiceImpl();
    keys = FastKeyManagementService(KeyManagementServiceImpl(crypto));
    session = SessionServiceImpl();
    storage = MemorySecureStorageService();
    attempts = UnlockAttemptLimiter(database: database!);
    auth = AuthRepositoryImpl(
      users: users,
      crypto: crypto,
      keys: keys,
      session: session,
      database: database!,
      vaults: vaults,
      secureStorage: storage,
      attempts: attempts,
    );
  });

  tearDown(() async {
    await database?.close();
    database = null;
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  Future<UserRecord> createUnlocked({
    required String username,
    required String masterPassword,
  }) async {
    final created = _expectSuccess(
      await auth.createAccount(
        username: username,
        masterPassword: masterPassword,
      ),
    );
    return _expectSuccess(
      await auth.authenticate(
        userId: created.id,
        masterPassword: masterPassword,
      ),
    );
  }

  Future<void> persistVault(String userId) async {
    _expectSuccess(
      await vaults.create(
        VaultRecord(
          userId: userId,
          formatVersion: SecurityConstants.vaultEncryptionVersion,
          nonce: Uint8List(SecurityConstants.nonceLength),
          ciphertext: Uint8List(48),
          updatedAt: DateTime.utc(2026, 1, 1),
        ),
      ),
    );
  }

  test('deleteAccount requires an authenticated session', () async {
    final result = await auth.deleteAccount(masterPassword: password);
    expect(result, isA<FailureResult<AccountDeletionOutcome>>());
    expect(
      (result as FailureResult<AccountDeletionOutcome>).failure,
      isA<AuthenticationFailure>(),
    );
  });

  test('wrong password does not wipe data or clear the session', () async {
    final user = await createUnlocked(username: 'علی', masterPassword: password);
    await persistVault(user.id);

    final result = await auth.deleteAccount(masterPassword: 'wrong-password-1');
    expect(result, isA<FailureResult<AccountDeletionOutcome>>());
    expect(
      (result as FailureResult<AccountDeletionOutcome>).failure,
      isA<AuthenticationFailure>(),
    );
    expect(session.isAuthenticated, isTrue);
    expect(_expectSuccess(await users.findById(user.id)), isNotNull);
    expect(_expectSuccess(await vaults.findByUserId(user.id)), isNotNull);
  }, timeout: kdfTimeout);

  test('deleting the last account wipes records, credentials, and session',
      () async {
    final user = await createUnlocked(username: 'علی', masterPassword: password);
    await persistVault(user.id);
    await storage.write(FastUnlockStorageKeys.pinMaterial(user.id), 'pin');
    await storage.write(
      FastUnlockStorageKeys.biometricMaterial(user.id),
      'bio',
    );
    await database!.appSettings.put(
      HiveSettingsKeys.pinFailedAttempts(user.id),
      2,
    );
    await database!.appSettings.put(
      HiveSettingsKeys.pinLockoutStartedAt(user.id),
      1,
    );
    await database!.appSettings.put(
      HiveSettingsKeys.biometricFailedAttempts(user.id),
      1,
    );
    await database!.appSettings.put(
      HiveSettingsKeys.biometricLockoutStartedAt(user.id),
      1,
    );

    final result = await auth.deleteAccount(masterPassword: password);
    final outcome = _expectSuccess(result);
    expect(outcome.hasRemainingAccounts, isFalse);
    expect(session.isAuthenticated, isFalse);
    expect(session.vaultKey, isNull);
    expect(_expectSuccess(await users.findById(user.id)), isNull);
    expect(_expectSuccess(await vaults.findByUserId(user.id)), isNull);
    expect(_expectSuccess(await users.listIds()), isEmpty);
    expect(storage.values[FastUnlockStorageKeys.pinMaterial(user.id)], isNull);
    expect(
      storage.values[FastUnlockStorageKeys.biometricMaterial(user.id)],
      isNull,
    );
    expect(
      database!.appSettings.get(HiveSettingsKeys.pinFailedAttempts(user.id)),
      isNull,
    );
    expect(
      database!.appSettings.get(HiveSettingsKeys.pinLockoutStartedAt(user.id)),
      isNull,
    );
    expect(
      database!.appSettings.get(
        HiveSettingsKeys.biometricFailedAttempts(user.id),
      ),
      isNull,
    );
    expect(
      database!.appSettings.get(
        HiveSettingsKeys.biometricLockoutStartedAt(user.id),
      ),
      isNull,
    );
    expect(
      database!.appSettings.get(HiveSettingsKeys.activeUserId),
      isNull,
    );
  }, timeout: kdfTimeout);

  test('deleting one of several accounts leaves the others intact', () async {
    final first = await createUnlocked(
      username: 'علی',
      masterPassword: password,
    );
    await persistVault(first.id);
    await storage.write(FastUnlockStorageKeys.pinMaterial(first.id), 'pin-a');
    _expectSuccess(await auth.logout());

    final second = await createUnlocked(
      username: 'رضا',
      masterPassword: otherPassword,
    );
    await persistVault(second.id);
    await storage.write(FastUnlockStorageKeys.pinMaterial(second.id), 'pin-b');

    final result = await auth.deleteAccount(masterPassword: otherPassword);
    expect(_expectSuccess(result).hasRemainingAccounts, isTrue);
    expect(session.isAuthenticated, isFalse);
    expect(_expectSuccess(await users.findById(second.id)), isNull);
    expect(_expectSuccess(await vaults.findByUserId(second.id)), isNull);
    expect(_expectSuccess(await users.findById(first.id)), isNotNull);
    expect(_expectSuccess(await vaults.findByUserId(first.id)), isNotNull);
    expect(
      storage.values[FastUnlockStorageKeys.pinMaterial(first.id)],
      'pin-a',
    );
    expect(
      storage.values[FastUnlockStorageKeys.pinMaterial(second.id)],
      isNull,
    );
    expect(
      database!.appSettings.get(HiveSettingsKeys.activeUserId),
      isNull,
    );
  }, timeout: kdfTimeout);

  test('incomplete delete does not clear the session or report success',
      () async {
    final user = await createUnlocked(username: 'علی', masterPassword: password);
    await persistVault(user.id);
    final failingAuth = AuthRepositoryImpl(
      users: _RejectingDeleteUsers(users),
      crypto: crypto,
      keys: keys,
      session: session,
      database: database!,
      vaults: vaults,
      secureStorage: storage,
      attempts: attempts,
    );

    final result = await failingAuth.deleteAccount(masterPassword: password);
    expect(result, isA<FailureResult<AccountDeletionOutcome>>());
    expect(
      (result as FailureResult<AccountDeletionOutcome>).failure,
      isA<DatabaseFailure>(),
    );
    expect(session.isAuthenticated, isTrue);
    expect(_expectSuccess(await users.findById(user.id)), isNotNull);
  }, timeout: kdfTimeout);
}

class _RejectingDeleteUsers implements UserDataSource {
  _RejectingDeleteUsers(this._inner);

  final UserDataSource _inner;

  @override
  Future<Result<void>> create(UserRecord user) => _inner.create(user);

  @override
  Future<Result<UserRecord?>> findById(String id) => _inner.findById(id);

  @override
  Future<Result<bool>> exists(String id) => _inner.exists(id);

  @override
  Future<Result<List<String>>> listIds() => _inner.listIds();

  @override
  Future<Result<List<UserRecord>>> list() => _inner.list();

  @override
  Future<Result<void>> update(UserRecord user) => _inner.update(user);

  @override
  Future<Result<void>> delete(String id) async {
    return const FailureResult(DatabaseFailure());
  }
}

T _expectSuccess<T>(Result<T> result) {
  expect(result, isA<Success<T>>());
  return (result as Success<T>).data;
}
