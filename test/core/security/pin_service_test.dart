import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:keyva/core/constants/security_constants.dart';
import 'package:keyva/core/crypto/crypto_service_impl.dart';
import 'package:keyva/core/crypto/key_management_service_impl.dart';
import 'package:keyva/core/database/hive_database.dart';
import 'package:keyva/core/database/hive_user_data_source.dart';
import 'package:keyva/core/database/hive_vault_data_source.dart';
import 'package:keyva/core/exceptions/app_failure.dart';
import 'package:keyva/core/exceptions/result.dart';
import 'package:keyva/core/security/fast_unlock_storage_keys.dart';
import 'package:keyva/core/security/pin_service_impl.dart';
import 'package:keyva/core/security/unlock_attempt_limiter.dart';
import 'package:keyva/core/session/session_service_impl.dart';
import 'package:keyva/feature/auth/repository/auth_repository_impl.dart';

import 'support/fast_key_management_service.dart';
import 'support/memory_secure_storage.dart';

void main() {
  late Directory tempDir;
  HiveDatabase? database;
  late SessionServiceImpl session;
  late MemorySecureStorageService storage;
  late AuthRepositoryImpl auth;
  late PinServiceImpl pin;
  late HiveUserDataSource users;
  late DateTime now;

  const kdfTimeout = Timeout(Duration(minutes: 2));
  const masterPassword = 'correct-master-password';
  const pinCode = '123456';

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('keyva_pin_');
    database = await HiveDatabase.initialize(testDatabasePath: tempDir.path);
    users = HiveUserDataSource(database!);
    final crypto = CryptoServiceImpl();
    final keys = FastKeyManagementService(KeyManagementServiceImpl(crypto));
    session = SessionServiceImpl();
    storage = MemorySecureStorageService();
    auth = AuthRepositoryImpl(
      users: users,
      crypto: crypto,
      keys: keys,
      session: session,
      database: database!,
      vaults: HiveVaultDataSource(database!),
    );
    now = DateTime.utc(2026, 8, 23, 12);
    pin = PinServiceImpl(
      crypto: crypto,
      keys: keys,
      storage: storage,
      users: users,
      session: session,
      attempts: UnlockAttemptLimiter(database: database!, clock: () => now),
    );
  });

  tearDown(() async {
    await database?.close();
    database = null;
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  Future<(String userId, Uint8List vaultKey)> unlockAccount() async {
    final created = _expectSuccess(
      await auth.createAccount(
        username: 'علی',
        masterPassword: masterPassword,
      ),
    );
    _expectSuccess(
      await auth.authenticate(
        userId: created.id,
        masterPassword: masterPassword,
      ),
    );
    return (created.id, Uint8List.fromList(session.vaultKey!));
  }

  test('enable requires an unlocked session', () async {
    final result = await pin.enable(pinCode);
    expect(result, isA<FailureResult<void>>());
    expect((result as FailureResult<void>).failure, isA<AuthenticationFailure>());
    expect(storage.values, isEmpty);
  }, timeout: kdfTimeout);

  test('enable rejects PINs that are not exactly 6 digits', () async {
    await unlockAccount();
    final tooShort = await pin.enable('1234');
    expect(tooShort, isA<FailureResult<void>>());
    expect((tooShort as FailureResult<void>).failure, isA<ValidationFailure>());
    expect(_expectSuccess(await pin.isEnabled(session.current!.userId)), isFalse);
  }, timeout: kdfTimeout);

  test('enable stores a wrapped copy and never writes the plaintext PIN', () async {
    final (userId, vaultKey) = await unlockAccount();
    _expectSuccess(await pin.enable(pinCode));

    expect(_expectSuccess(await pin.isEnabled(userId)), isTrue);
    final user = _expectSuccess(await users.findById(userId))!;
    expect(user.securitySettings.pinEnabled, isTrue);
    expect(
      storage.values[FastUnlockStorageKeys.pinMaterial(userId)],
      isNotNull,
    );
    expect(
      storage.values.values.any((value) => value.contains(pinCode)),
      isFalse,
    );
    expect(session.vaultKey, vaultKey);
  }, timeout: kdfTimeout);

  test('correct PIN unwraps the same VaultKey', () async {
    final (userId, vaultKey) = await unlockAccount();
    _expectSuccess(await pin.enable(pinCode));
    session.clear();

    final unwrapped = _expectSuccess(
      await pin.unwrapVaultKey(userId: userId, pin: pinCode),
    );
    expect(unwrapped, vaultKey);
  }, timeout: kdfTimeout);

  test('wrong PIN fails closed, increments, and locks after 3 attempts', () async {
    final (userId, _) = await unlockAccount();
    _expectSuccess(await pin.enable(pinCode));
    session.clear();

    expect(_expectSuccess(await pin.remainingAttempts(userId)), 3);

    final first = await pin.unwrapVaultKey(userId: userId, pin: '000000');
    expect(first, isA<FailureResult<Uint8List>>());
    expect(_expectSuccess(await pin.remainingAttempts(userId)), 2);
    expect(_expectSuccess(await pin.isLockedOut(userId)), isFalse);

    final second = await pin.unwrapVaultKey(userId: userId, pin: '000000');
    expect(second, isA<FailureResult<Uint8List>>());
    expect(_expectSuccess(await pin.remainingAttempts(userId)), 1);

    final third = await pin.unwrapVaultKey(userId: userId, pin: '000000');
    expect(third, isA<FailureResult<Uint8List>>());
    expect(
      (third as FailureResult<Uint8List>).failure,
      isA<AuthenticationFailure>(),
    );
    expect(third.failure.message, isNot(contains('000000')));
    expect(third.failure.message, isNot(contains(pinCode)));
    expect(_expectSuccess(await pin.isLockedOut(userId)), isTrue);
    expect(_expectSuccess(await pin.remainingAttempts(userId)), 0);

    final locked = await pin.unwrapVaultKey(userId: userId, pin: pinCode);
    expect(locked, isA<FailureResult<Uint8List>>());
    expect(_expectSuccess(await pin.isLockedOut(userId)), isTrue);
  }, timeout: kdfTimeout);

  test('PIN lockout persists across a new PinService on the same database', () async {
    final (userId, _) = await unlockAccount();
    _expectSuccess(await pin.enable(pinCode));
    session.clear();
    for (var i = 0; i < SecurityConstants.pinMaxFailedAttempts; i++) {
      await pin.unwrapVaultKey(userId: userId, pin: '000000');
    }

    final restored = PinServiceImpl(
      crypto: CryptoServiceImpl(),
      keys: FastKeyManagementService(
        KeyManagementServiceImpl(CryptoServiceImpl()),
      ),
      storage: storage,
      users: users,
      session: session,
      attempts: UnlockAttemptLimiter(database: database!, clock: () => now),
    );
    expect(_expectSuccess(await restored.isLockedOut(userId)), isTrue);
    expect(
      await restored.unwrapVaultKey(userId: userId, pin: pinCode),
      isA<FailureResult<Uint8List>>(),
    );
  }, timeout: kdfTimeout);

  test('PIN attempts reset after 15 minutes without Master Password', () async {
    final (userId, vaultKey) = await unlockAccount();
    _expectSuccess(await pin.enable(pinCode));
    session.clear();
    for (var i = 0; i < SecurityConstants.pinMaxFailedAttempts; i++) {
      await pin.unwrapVaultKey(userId: userId, pin: '000000');
    }
    expect(_expectSuccess(await pin.isLockedOut(userId)), isTrue);

    now = now.add(SecurityConstants.unlockAttemptLockout);
    expect(_expectSuccess(await pin.isLockedOut(userId)), isFalse);
    final unwrapped = _expectSuccess(
      await pin.unwrapVaultKey(userId: userId, pin: pinCode),
    );
    expect(unwrapped, vaultKey);
  }, timeout: kdfTimeout);

  test('resetFailedAttempts after Master Password unlock restores PIN', () async {
    final (userId, vaultKey) = await unlockAccount();
    _expectSuccess(await pin.enable(pinCode));
    session.clear();
    for (var i = 0; i < SecurityConstants.pinMaxFailedAttempts; i++) {
      await pin.unwrapVaultKey(userId: userId, pin: '000000');
    }
    expect(_expectSuccess(await pin.isLockedOut(userId)), isTrue);

    _expectSuccess(await pin.resetFailedAttempts(userId));
    expect(_expectSuccess(await pin.isLockedOut(userId)), isFalse);
    final unwrapped = _expectSuccess(
      await pin.unwrapVaultKey(userId: userId, pin: pinCode),
    );
    expect(unwrapped, vaultKey);
  }, timeout: kdfTimeout);

  test('change re-wraps without touching the Hive wrapped VaultKey', () async {
    final (userId, vaultKey) = await unlockAccount();
    _expectSuccess(await pin.enable(pinCode));
    final before = _expectSuccess(await users.findById(userId))!;
    _expectSuccess(
      await pin.change(currentPin: pinCode, newPin: '135790'),
    );
    final after = _expectSuccess(await users.findById(userId))!;
    expect(after.wrappedVaultKey.ciphertext, before.wrappedVaultKey.ciphertext);
    expect(after.wrappedVaultKey.nonce, before.wrappedVaultKey.nonce);
    session.clear();

    expect(
      await pin.unwrapVaultKey(userId: userId, pin: pinCode),
      isA<FailureResult<Uint8List>>(),
    );
    final unwrapped = _expectSuccess(
      await pin.unwrapVaultKey(userId: userId, pin: '135790'),
    );
    expect(unwrapped, vaultKey);
  }, timeout: kdfTimeout);

  test('disable deletes wrapping material and clears the flag', () async {
    final (userId, _) = await unlockAccount();
    _expectSuccess(await pin.enable(pinCode));
    _expectSuccess(await pin.disable());

    expect(_expectSuccess(await pin.isEnabled(userId)), isFalse);
    expect(storage.values[FastUnlockStorageKeys.pinMaterial(userId)], isNull);
    session.clear();
    expect(
      await pin.unwrapVaultKey(userId: userId, pin: pinCode),
      isA<FailureResult<Uint8List>>(),
    );
  }, timeout: kdfTimeout);
}

T _expectSuccess<T>(Result<T> result) {
  expect(result, isA<Success<T>>());
  return (result as Success<T>).data;
}
