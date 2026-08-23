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
import 'package:keyva/core/security/biometric_gateway.dart';
import 'package:keyva/core/security/biometric_service_impl.dart';
import 'package:keyva/core/security/fast_unlock_storage_keys.dart';
import 'package:keyva/core/security/pin_service_impl.dart';
import 'package:keyva/core/security/unlock_attempt_limiter.dart';
import 'package:keyva/core/session/session_service_impl.dart';
import 'package:keyva/feature/auth/repository/auth_repository_impl.dart';
import 'package:keyva/feature/vault/repository/vault_repository_impl.dart';
import 'package:keyva/feature/vault/serialization/vault_serializer_impl.dart';
import 'package:keyva/feature/vault/service/vault_unlock_service_impl.dart';
import 'package:keyva/feature/vault/session/vault_session_impl.dart';

import '../../core/security/support/fake_biometric_gateway.dart';
import '../../core/security/support/fast_key_management_service.dart';
import '../../core/security/support/memory_secure_storage.dart';

void main() {
  late Directory tempDir;
  HiveDatabase? database;
  late SessionServiceImpl session;
  late MemorySecureStorageService storage;
  late AuthRepositoryImpl auth;
  late PinServiceImpl pin;
  late BiometricServiceImpl biometric;
  late VaultUnlockServiceImpl unlock;
  late VaultSessionImpl vaultSession;
  late FakeBiometricGateway gateway;

  const kdfTimeout = Timeout(Duration(minutes: 2));
  const masterPassword = 'correct-master-password';
  const pinCode = '123456';

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('keyva_unlock_pin_');
    database = await HiveDatabase.initialize(testDatabasePath: tempDir.path);
    final users = HiveUserDataSource(database!);
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
    );
    pin = PinServiceImpl(
      crypto: crypto,
      keys: keys,
      storage: storage,
      users: users,
      session: session,
      attempts: UnlockAttemptLimiter(database: database!),
    );
    gateway = FakeBiometricGateway();
    biometric = BiometricServiceImpl(
      gateway: gateway,
      keys: keys,
      storage: storage,
      users: users,
      session: session,
      attempts: UnlockAttemptLimiter(database: database!),
    );
    vaultSession = VaultSessionImpl();
    unlock = VaultUnlockServiceImpl(
      auth: auth,
      vaults: VaultRepositoryImpl(
        vaults: HiveVaultDataSource(database!),
        crypto: crypto,
        session: session,
      ),
      serializer: VaultSerializerImpl(),
      vaultSession: vaultSession,
      pin: pin,
      biometric: biometric,
    );
  });

  tearDown(() async {
    await database?.close();
    database = null;
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  Future<String> seedUnlockedVault() async {
    final user = _expectSuccess(
      await auth.createAccount(
        username: 'علی',
        masterPassword: masterPassword,
      ),
    );
    _expectSuccess(
      await unlock.unlock(userId: user.id, masterPassword: masterPassword),
    );
    return user.id;
  }

  test('unlockWithPin establishes the same Unlocked session', () async {
    final userId = await seedUnlockedVault();
    _expectSuccess(await pin.enable(pinCode));
    _expectSuccess(await unlock.lock());

    _expectSuccess(await unlock.unlockWithPin(userId: userId, pin: pinCode));
    expect(session.isAuthenticated, isTrue);
    expect(session.vaultKey, isNotNull);
    expect(vaultSession.isUnlocked, isTrue);
    expect(vaultSession.vaultData?.logins, isEmpty);
  }, timeout: kdfTimeout);

  test('unlockWithBiometric establishes the Unlocked session', () async {
    final userId = await seedUnlockedVault();
    _expectSuccess(await biometric.enable(localizedReason: 'enable'));
    _expectSuccess(await unlock.lock());

    _expectSuccess(await unlock.unlockWithBiometric(userId: userId));
    expect(session.isAuthenticated, isTrue);
    expect(session.current!.userId, userId);
    expect(vaultSession.isUnlocked, isTrue);
  }, timeout: kdfTimeout);

  test('unlockWithBiometric unavailable stays locked', () async {
    final userId = await seedUnlockedVault();
    _expectSuccess(await biometric.enable(localizedReason: 'enable'));
    _expectSuccess(await unlock.lock());
    gateway.available = false;

    final result = await unlock.unlockWithBiometric(userId: userId);
    expect(result, isA<FailureResult<void>>());
    expect(
      (result as FailureResult<void>).failure,
      isA<BiometricUnavailableFailure>(),
    );
    expect(session.isAuthenticated, isFalse);
    expect(vaultSession.isUnlocked, isFalse);
  }, timeout: kdfTimeout);

  test('unlockWithBiometric failed stays locked', () async {
    final userId = await seedUnlockedVault();
    _expectSuccess(await biometric.enable(localizedReason: 'enable'));
    _expectSuccess(await unlock.lock());
    gateway.result = BiometricPromptResult.failed;

    final result = await unlock.unlockWithBiometric(userId: userId);
    expect(result, isA<FailureResult<void>>());
    expect(
      (result as FailureResult<void>).failure,
      isA<BiometricAuthFailedFailure>(),
    );
    expect(session.isAuthenticated, isFalse);
  }, timeout: kdfTimeout);

  test('unlockWithBiometric without wrap material is not configured', () async {
    final userId = await seedUnlockedVault();
    _expectSuccess(await unlock.lock());

    final result = await unlock.unlockWithBiometric(userId: userId);
    expect(result, isA<FailureResult<void>>());
    expect(
      (result as FailureResult<void>).failure,
      isA<BiometricNotConfiguredFailure>(),
    );
    expect(session.isAuthenticated, isFalse);
  }, timeout: kdfTimeout);

  test('biometric success with unwrap failure fails closed', () async {
    final userId = await seedUnlockedVault();
    _expectSuccess(await biometric.enable(localizedReason: 'enable'));
    storage.values[FastUnlockStorageKeys.biometricMaterial(userId)] =
        '{"wrapKey":"AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=","wrapped":{"version":1,"nonce":"AAAAAAAAAAAAAAAA","ciphertext":"AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=","authenticationTag":"AAAAAAAAAAAAAAAAAAAAAA=="}}';
    _expectSuccess(await unlock.lock());

    final result = await unlock.unlockWithBiometric(userId: userId);
    expect(result, isA<FailureResult<void>>());
    expect(
      (result as FailureResult<void>).failure,
      isA<AuthenticationFailure>(),
    );
    expect(session.isAuthenticated, isFalse);
    expect(vaultSession.isUnlocked, isFalse);
  }, timeout: kdfTimeout);

  test('lock zeros the VaultKey and keeps PIN material', () async {
    final userId = await seedUnlockedVault();
    _expectSuccess(await pin.enable(pinCode));
    final vaultKey = session.vaultKey!;
    _expectSuccess(await unlock.lock());

    expect(session.isAuthenticated, isFalse);
    expect(session.vaultKey, isNull);
    expect(vaultKey, Uint8List(vaultKey.length));
    expect(storage.values[FastUnlockStorageKeys.pinMaterial(userId)], isNotNull);
    expect(vaultSession.isUnlocked, isFalse);
  }, timeout: kdfTimeout);

  test('wrong PIN unlock fails closed', () async {
    final userId = await seedUnlockedVault();
    _expectSuccess(await pin.enable(pinCode));
    _expectSuccess(await unlock.lock());

    final result = await unlock.unlockWithPin(userId: userId, pin: '000000');
    expect(result, isA<FailureResult<void>>());
    expect(
      (result as FailureResult<void>).failure,
      isA<AuthenticationFailure>(),
    );
    expect(session.isAuthenticated, isFalse);
    expect(vaultSession.isUnlocked, isFalse);
  }, timeout: kdfTimeout);

  test('Master Password unlock resets PIN and biometric attempts', () async {
    final userId = await seedUnlockedVault();
    _expectSuccess(await pin.enable(pinCode));
    _expectSuccess(await biometric.enable(localizedReason: 'enable'));
    _expectSuccess(await unlock.lock());

    for (var i = 0; i < SecurityConstants.pinMaxFailedAttempts; i++) {
      await unlock.unlockWithPin(userId: userId, pin: '000000');
    }
    gateway.result = BiometricPromptResult.failed;
    for (var i = 0; i < SecurityConstants.biometricMaxFailedAttempts; i++) {
      await unlock.unlockWithBiometric(userId: userId);
    }
    expect(_expectSuccess(await pin.isLockedOut(userId)), isTrue);
    expect(_expectSuccess(await biometric.isLockedOut(userId)), isTrue);

    gateway.result = BiometricPromptResult.success;
    _expectSuccess(
      await unlock.unlock(userId: userId, masterPassword: masterPassword),
    );
    expect(_expectSuccess(await pin.isLockedOut(userId)), isFalse);
    expect(_expectSuccess(await biometric.isLockedOut(userId)), isFalse);
  }, timeout: kdfTimeout);
}

T _expectSuccess<T>(Result<T> result) {
  expect(result, isA<Success<T>>());
  return (result as Success<T>).data;
}
