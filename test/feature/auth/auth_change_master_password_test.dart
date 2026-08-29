import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:keyva/core/constants/security_constants.dart';
import 'package:keyva/core/crypto/crypto_service.dart';
import 'package:keyva/core/crypto/crypto_service_impl.dart';
import 'package:keyva/core/crypto/key_management_service.dart';
import 'package:keyva/core/crypto/key_management_service_impl.dart';
import 'package:keyva/core/database/hive_database.dart';
import 'package:keyva/core/database/hive_user_data_source.dart';
import 'package:keyva/core/database/hive_vault_data_source.dart';
import 'package:keyva/core/database/models/kdf_parameters.dart';
import 'package:keyva/core/database/models/user_record.dart';
import 'package:keyva/core/database/models/wrapped_vault_key.dart';
import 'package:keyva/core/database/user_data_source.dart';
import 'package:keyva/core/exceptions/app_failure.dart';
import 'package:keyva/core/exceptions/result.dart';
import 'package:keyva/core/security/fast_unlock_storage_keys.dart';
import 'package:keyva/core/security/pin_service_impl.dart';
import 'package:keyva/core/security/unlock_attempt_limiter.dart';
import 'package:keyva/core/session/session_service_impl.dart';
import 'package:keyva/feature/auth/repository/auth_repository_impl.dart';
import 'package:keyva/feature/vault/repository/vault_repository_impl.dart';

import '../../core/security/support/fast_key_management_service.dart';
import '../../core/security/support/memory_secure_storage.dart';

void main() {
  late Directory tempDir;
  HiveDatabase? database;
  late HiveUserDataSource users;
  late HiveVaultDataSource vaults;
  late CryptoService crypto;
  late KeyManagementService keys;
  late SessionServiceImpl session;
  late AuthRepositoryImpl auth;

  const kdfTimeout = Timeout(Duration(minutes: 2));
  const currentPassword = 'correct-master-password';
  const nextPassword = 'replacement-master-password';

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('keyva_change_mp_');
    database = await HiveDatabase.initialize(testDatabasePath: tempDir.path);
    users = HiveUserDataSource(database!);
    vaults = HiveVaultDataSource(database!);
    crypto = CryptoServiceImpl();
    keys = FastKeyManagementService(KeyManagementServiceImpl(crypto));
    session = SessionServiceImpl();
    auth = AuthRepositoryImpl(
      users: users,
      crypto: crypto,
      keys: keys,
      session: session,
      database: database!,
      vaults: HiveVaultDataSource(database!),
      attempts: UnlockAttemptLimiter(database: database!),
    );
  });

  tearDown(() async {
    await database?.close();
    database = null;
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  Future<UserRecord> unlockAccount() async {
    final created = _expectSuccess(
      await auth.createAccount(
        username: 'علی',
        masterPassword: currentPassword,
      ),
    );
    return _expectSuccess(
      await auth.authenticate(
        userId: created.id,
        masterPassword: currentPassword,
      ),
    );
  }

  test('requires an unlocked session', () async {
    final result = await auth.changeMasterPassword(
      currentPassword: currentPassword,
      newPassword: nextPassword,
    );
    expect(result, isA<FailureResult<void>>());
    expect((result as FailureResult<void>).failure, isA<AuthenticationFailure>());
  }, timeout: kdfTimeout);

  test('wrong current password does not change wrap, vault, or session', () async {
    final user = await unlockAccount();
    final vaultKey = Uint8List.fromList(session.vaultKey!);
    final before = _expectSuccess(await users.findById(user.id))!;
    final repository = VaultRepositoryImpl(
      vaults: vaults,
      crypto: crypto,
      session: session,
    );
    _expectSuccess(
      await repository.saveVaultData(Uint8List.fromList([9, 8, 7, 6])),
    );
    final vaultBefore = _expectSuccess(await vaults.findByUserId(user.id))!;

    final result = await auth.changeMasterPassword(
      currentPassword: 'wrong-master-password',
      newPassword: nextPassword,
    );

    expect(result, isA<FailureResult<void>>());
    expect((result as FailureResult<void>).failure, isA<AuthenticationFailure>());
    expect(session.isAuthenticated, isTrue);
    expect(session.vaultKey, vaultKey);

    final after = _expectSuccess(await users.findById(user.id))!;
    expect(after.kdfSalt, before.kdfSalt);
    expect(after.wrappedVaultKey.ciphertext, before.wrappedVaultKey.ciphertext);
    final vaultAfter = _expectSuccess(await vaults.findByUserId(user.id))!;
    expect(vaultAfter.ciphertext, vaultBefore.ciphertext);
  }, timeout: kdfTimeout);

  test(
    'sixth wrong current password locks later Master Password authentication',
    () async {
      final user = await unlockAccount();
      for (var i = 0; i < SecurityConstants.masterPasswordMaxFailedAttempts - 1; i++) {
        final result = await auth.changeMasterPassword(
          currentPassword: 'wrong-master-password',
          newPassword: nextPassword,
        );
        expect((result as FailureResult<void>).failure, isA<AuthenticationFailure>());
      }
      final locked = await auth.changeMasterPassword(
        currentPassword: 'wrong-master-password',
        newPassword: nextPassword,
      );
      expect(
        (locked as FailureResult<void>).failure,
        isA<MasterPasswordLockedOutFailure>(),
      );
      expect(session.isAuthenticated, isTrue);

      _expectSuccess(await auth.logout());
      final login = await auth.authenticate(
        userId: user.id,
        masterPassword: currentPassword,
      );
      expect(
        (login as FailureResult<UserRecord>).failure,
        isA<MasterPasswordLockedOutFailure>(),
      );
    },
    timeout: kdfTimeout,
  );

  test('re-wraps the same Vault Key and leaves vault ciphertext unchanged', () async {
    final user = await unlockAccount();
    final vaultKey = Uint8List.fromList(session.vaultKey!);
    final plaintext = Uint8List.fromList([1, 2, 3, 4, 5]);
    final repository = VaultRepositoryImpl(
      vaults: vaults,
      crypto: crypto,
      session: session,
    );
    _expectSuccess(await repository.saveVaultData(plaintext));
    final vaultBefore = _expectSuccess(await vaults.findByUserId(user.id))!;

    _expectSuccess(
      await auth.changeMasterPassword(
        currentPassword: currentPassword,
        newPassword: nextPassword,
      ),
    );

    expect(session.isAuthenticated, isTrue);
    expect(session.vaultKey, vaultKey);
    final vaultAfter = _expectSuccess(await vaults.findByUserId(user.id))!;
    expect(vaultAfter.ciphertext, vaultBefore.ciphertext);
    expect(vaultAfter.nonce, vaultBefore.nonce);

    _expectSuccess(await auth.logout());
    expect(
      await auth.authenticate(userId: user.id, masterPassword: currentPassword),
      isA<FailureResult<UserRecord>>(),
    );
    _expectSuccess(
      await auth.authenticate(userId: user.id, masterPassword: nextPassword),
    );
    expect(
      _expectSuccess(await repository.loadVaultData()),
      plaintext,
    );
  }, timeout: kdfTimeout);

  test('PIN unwrap still works after a Master Password change', () async {
    final user = await unlockAccount();
    final vaultKey = Uint8List.fromList(session.vaultKey!);
    final storage = MemorySecureStorageService();
    final pin = PinServiceImpl(
      crypto: crypto,
      keys: keys,
      storage: storage,
      users: users,
      session: session,
      attempts: UnlockAttemptLimiter(database: database!),
    );
    _expectSuccess(await pin.enable('123456'));
    _expectSuccess(
      await auth.changeMasterPassword(
        currentPassword: currentPassword,
        newPassword: nextPassword,
      ),
    );

    expect(
      storage.values[FastUnlockStorageKeys.pinMaterial(user.id)],
      isNotNull,
    );
    session.clear();
    expect(
      _expectSuccess(await pin.unwrapVaultKey(userId: user.id, pin: '123456')),
      vaultKey,
    );
  }, timeout: kdfTimeout);

  test('persist failure keeps the old wrap valid', () async {
    await unlockAccount();
    final failingAuth = AuthRepositoryImpl(
      users: _RejectingUpdateUsers(users),
      crypto: crypto,
      keys: keys,
      session: session,
      database: database!,
      vaults: HiveVaultDataSource(database!),
    );

    final result = await failingAuth.changeMasterPassword(
      currentPassword: currentPassword,
      newPassword: nextPassword,
    );
    expect(result, isA<FailureResult<void>>());
    expect((result as FailureResult<void>).failure, isA<DatabaseFailure>());
    expect(session.isAuthenticated, isTrue);

    final userId = session.current!.userId;
    _expectSuccess(await auth.logout());
    _expectSuccess(
      await auth.authenticate(userId: userId, masterPassword: currentPassword),
    );
  }, timeout: kdfTimeout);

  test('wrap failure keeps the old wrap valid', () async {
    await unlockAccount();
    final failingAuth = AuthRepositoryImpl(
      users: users,
      crypto: crypto,
      keys: _FailingWrapKeys(keys),
      session: session,
      database: database!,
      vaults: HiveVaultDataSource(database!),
    );

    final result = await failingAuth.changeMasterPassword(
      currentPassword: currentPassword,
      newPassword: nextPassword,
    );
    expect(result, isA<FailureResult<void>>());
    expect((result as FailureResult<void>).failure, isA<CryptoFailure>());
    expect(session.isAuthenticated, isTrue);

    final userId = session.current!.userId;
    _expectSuccess(await auth.logout());
    _expectSuccess(
      await auth.authenticate(userId: userId, masterPassword: currentPassword),
    );
  }, timeout: kdfTimeout);
}

T _expectSuccess<T>(Result<T> result) {
  expect(result, isA<Success<T>>());
  return (result as Success<T>).data;
}

class _RejectingUpdateUsers implements UserDataSource {
  _RejectingUpdateUsers(this._inner);

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
  Future<Result<void>> update(UserRecord user) async {
    return const FailureResult(DatabaseFailure());
  }

  @override
  Future<Result<void>> delete(String id) => _inner.delete(id);
}

class _FailingWrapKeys implements KeyManagementService {
  _FailingWrapKeys(this._inner);

  final KeyManagementService _inner;

  @override
  KdfParameters defaultKdfParameters() => _inner.defaultKdfParameters();

  @override
  Uint8List generateSalt() => _inner.generateSalt();

  @override
  Uint8List generateVaultKey() => _inner.generateVaultKey();

  @override
  Future<Result<WrappedVaultKey>> wrapVaultKey({
    required Uint8List vaultKey,
    required Uint8List derivedKey,
  }) {
    return Future.value(const FailureResult(CryptoFailure()));
  }

  @override
  Future<Result<Uint8List>> unwrapVaultKey({
    required WrappedVaultKey wrappedVaultKey,
    required Uint8List derivedKey,
  }) {
    return _inner.unwrapVaultKey(
      wrappedVaultKey: wrappedVaultKey,
      derivedKey: derivedKey,
    );
  }
}
