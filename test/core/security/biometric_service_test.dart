import 'dart:convert';
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
import 'package:keyva/core/security/unlock_attempt_limiter.dart';
import 'package:keyva/core/session/session_service_impl.dart';
import 'package:keyva/feature/auth/repository/auth_repository_impl.dart';

import 'support/fake_biometric_gateway.dart';
import 'support/fast_key_management_service.dart';
import 'support/memory_secure_storage.dart';

void main() {
  late Directory tempDir;
  HiveDatabase? database;
  late SessionServiceImpl session;
  late MemorySecureStorageService storage;
  late FakeBiometricGateway gateway;
  late AuthRepositoryImpl auth;
  late BiometricServiceImpl biometric;
  late HiveUserDataSource users;
  late List<String> diagnosticLogs;
  late DateTime now;

  const kdfTimeout = Timeout(Duration(minutes: 2));
  const masterPassword = 'correct-master-password';
  const reason = 'unlock';

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('keyva_bio_');
    database = await HiveDatabase.initialize(testDatabasePath: tempDir.path);
    users = HiveUserDataSource(database!);
    final crypto = CryptoServiceImpl();
    final keys = FastKeyManagementService(KeyManagementServiceImpl(crypto));
    session = SessionServiceImpl();
    storage = MemorySecureStorageService();
    gateway = FakeBiometricGateway();
    diagnosticLogs = <String>[];
    auth = AuthRepositoryImpl(
      users: users,
      crypto: crypto,
      keys: keys,
      session: session,
      database: database!,
      vaults: HiveVaultDataSource(database!),
    );
    now = DateTime.utc(2026, 8, 23, 12);
    biometric = BiometricServiceImpl(
      gateway: gateway,
      keys: keys,
      storage: storage,
      users: users,
      session: session,
      attempts: UnlockAttemptLimiter(database: database!, clock: () => now),
      diagnosticLog: diagnosticLogs.add,
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

  test('cannot enable when biometrics are unavailable', () async {
    gateway.available = false;
    final (userId, _) = await unlockAccount();
    final result = await biometric.enable(localizedReason: reason);
    expect(result, isA<FailureResult<void>>());
    expect(
      (result as FailureResult<void>).failure,
      isA<BiometricUnavailableFailure>(),
    );
    expect(_expectSuccess(await biometric.isEnabled(userId)), isFalse);
    expect(storage.values, isEmpty);
  }, timeout: kdfTimeout);

  test('unwrap is unavailable when device biometrics are missing', () async {
    gateway.available = false;
    final (userId, _) = await unlockAccount();
    final result = await biometric.unwrapVaultKey(
      userId: userId,
      localizedReason: reason,
    );
    expect(result, isA<FailureResult<Uint8List>>());
    expect(
      (result as FailureResult<Uint8List>).failure,
      isA<BiometricUnavailableFailure>(),
    );
    expect(session.isAuthenticated, isTrue);
  }, timeout: kdfTimeout);

  test('enable stores wrap material after OS authentication', () async {
    final (userId, vaultKey) = await unlockAccount();
    _expectSuccess(await biometric.enable(localizedReason: reason));
    expect(_expectSuccess(await biometric.isEnabled(userId)), isTrue);
    expect(
      storage.values[FastUnlockStorageKeys.biometricMaterial(userId)],
      isNotNull,
    );
    expect(session.vaultKey, vaultKey);
  }, timeout: kdfTimeout);

  test('successful OS auth unwraps the VaultKey', () async {
    final (userId, vaultKey) = await unlockAccount();
    _expectSuccess(await biometric.enable(localizedReason: reason));
    session.clear();

    final unwrapped = _expectSuccess(
      await biometric.unwrapVaultKey(userId: userId, localizedReason: reason),
    );
    expect(unwrapped, vaultKey);
    expect(gateway.authenticateCount, 2);
  }, timeout: kdfTimeout);

  test('cancelled OS auth fails closed without unlocking', () async {
    final (userId, _) = await unlockAccount();
    _expectSuccess(await biometric.enable(localizedReason: reason));
    session.clear();
    gateway.result = BiometricPromptResult.cancelled;

    final result = await biometric.unwrapVaultKey(
      userId: userId,
      localizedReason: reason,
    );
    expect(result, isA<FailureResult<Uint8List>>());
    expect(
      (result as FailureResult<Uint8List>).failure,
      isA<BiometricCancelledFailure>(),
    );
    expect(session.isAuthenticated, isFalse);
  }, timeout: kdfTimeout);

  test('failed OS auth does not unwrap the VaultKey', () async {
    final (userId, _) = await unlockAccount();
    _expectSuccess(await biometric.enable(localizedReason: reason));
    session.clear();
    gateway.result = BiometricPromptResult.failed;

    final result = await biometric.unwrapVaultKey(
      userId: userId,
      localizedReason: reason,
    );
    expect(result, isA<FailureResult<Uint8List>>());
    expect(
      (result as FailureResult<Uint8List>).failure,
      isA<BiometricAuthFailedFailure>(),
    );
    expect(session.isAuthenticated, isFalse);
    expect(_expectSuccess(await biometric.remainingAttempts(userId)), 2);
  }, timeout: kdfTimeout);

  test('biometric locks after 3 failed authentications', () async {
    final (userId, _) = await unlockAccount();
    _expectSuccess(await biometric.enable(localizedReason: reason));
    session.clear();
    gateway.result = BiometricPromptResult.failed;
    final promptsBefore = gateway.authenticateCount;

    for (var i = 0; i < SecurityConstants.biometricMaxFailedAttempts; i++) {
      final result = await biometric.unwrapVaultKey(
        userId: userId,
        localizedReason: reason,
      );
      expect(
        (result as FailureResult<Uint8List>).failure,
        isA<BiometricAuthFailedFailure>(),
      );
    }

    expect(_expectSuccess(await biometric.isLockedOut(userId)), isTrue);
    expect(_expectSuccess(await biometric.remainingAttempts(userId)), 0);

    final locked = await biometric.unwrapVaultKey(
      userId: userId,
      localizedReason: reason,
    );
    expect(
      (locked as FailureResult<Uint8List>).failure,
      isA<BiometricLockedOutFailure>(),
    );
    expect(
      gateway.authenticateCount,
      promptsBefore + SecurityConstants.biometricMaxFailedAttempts,
    );
  }, timeout: kdfTimeout);

  test('cancelled biometric does not increment failed attempts', () async {
    final (userId, _) = await unlockAccount();
    _expectSuccess(await biometric.enable(localizedReason: reason));
    session.clear();
    gateway.result = BiometricPromptResult.failed;
    await biometric.unwrapVaultKey(userId: userId, localizedReason: reason);
    expect(_expectSuccess(await biometric.remainingAttempts(userId)), 2);

    gateway.result = BiometricPromptResult.cancelled;
    final result = await biometric.unwrapVaultKey(
      userId: userId,
      localizedReason: reason,
    );
    expect(
      (result as FailureResult<Uint8List>).failure,
      isA<BiometricCancelledFailure>(),
    );
    expect(_expectSuccess(await biometric.remainingAttempts(userId)), 2);
    expect(_expectSuccess(await biometric.isLockedOut(userId)), isFalse);
  }, timeout: kdfTimeout);

  test('unavailable biometric does not increment failed attempts', () async {
    final (userId, _) = await unlockAccount();
    _expectSuccess(await biometric.enable(localizedReason: reason));
    session.clear();
    gateway.result = BiometricPromptResult.failed;
    await biometric.unwrapVaultKey(userId: userId, localizedReason: reason);
    expect(_expectSuccess(await biometric.remainingAttempts(userId)), 2);

    gateway.available = false;
    final result = await biometric.unwrapVaultKey(
      userId: userId,
      localizedReason: reason,
    );
    expect(
      (result as FailureResult<Uint8List>).failure,
      isA<BiometricUnavailableFailure>(),
    );
    expect(_expectSuccess(await biometric.remainingAttempts(userId)), 2);
  }, timeout: kdfTimeout);

  test('biometric attempts reset after 15 minutes', () async {
    final (userId, vaultKey) = await unlockAccount();
    _expectSuccess(await biometric.enable(localizedReason: reason));
    session.clear();
    gateway.result = BiometricPromptResult.failed;
    for (var i = 0; i < SecurityConstants.biometricMaxFailedAttempts; i++) {
      await biometric.unwrapVaultKey(userId: userId, localizedReason: reason);
    }
    expect(_expectSuccess(await biometric.isLockedOut(userId)), isTrue);

    now = now.add(SecurityConstants.unlockAttemptLockout);
    gateway.result = BiometricPromptResult.success;
    expect(_expectSuccess(await biometric.isLockedOut(userId)), isFalse);
    final unwrapped = _expectSuccess(
      await biometric.unwrapVaultKey(userId: userId, localizedReason: reason),
    );
    expect(unwrapped, vaultKey);
  }, timeout: kdfTimeout);

  test('resetFailedAttempts restores biometric after lockout', () async {
    final (userId, vaultKey) = await unlockAccount();
    _expectSuccess(await biometric.enable(localizedReason: reason));
    session.clear();
    gateway.result = BiometricPromptResult.failed;
    for (var i = 0; i < SecurityConstants.biometricMaxFailedAttempts; i++) {
      await biometric.unwrapVaultKey(userId: userId, localizedReason: reason);
    }
    expect(_expectSuccess(await biometric.isLockedOut(userId)), isTrue);

    _expectSuccess(await biometric.resetFailedAttempts(userId));
    expect(_expectSuccess(await biometric.isLockedOut(userId)), isFalse);
    gateway.result = BiometricPromptResult.success;
    final unwrapped = _expectSuccess(
      await biometric.unwrapVaultKey(userId: userId, localizedReason: reason),
    );
    expect(unwrapped, vaultKey);
  }, timeout: kdfTimeout);

  test('prompt success without wrap material is not configured', () async {
    final (userId, _) = await unlockAccount();
    session.clear();

    final result = await biometric.unwrapVaultKey(
      userId: userId,
      localizedReason: reason,
    );
    expect(result, isA<FailureResult<Uint8List>>());
    expect(
      (result as FailureResult<Uint8List>).failure,
      isA<BiometricNotConfiguredFailure>(),
    );
  }, timeout: kdfTimeout);

  test('prompt success with corrupt wrap is not configured', () async {
    final (userId, _) = await unlockAccount();
    _expectSuccess(await biometric.enable(localizedReason: reason));
    storage.values[FastUnlockStorageKeys.biometricMaterial(userId)] = '{';
    session.clear();

    final result = await biometric.unwrapVaultKey(
      userId: userId,
      localizedReason: reason,
    );
    expect(result, isA<FailureResult<Uint8List>>());
    expect(
      (result as FailureResult<Uint8List>).failure,
      isA<BiometricNotConfiguredFailure>(),
    );
  }, timeout: kdfTimeout);

  test('prompt success with unwrap crypto failure stays locked', () async {
    final (userId, _) = await unlockAccount();
    _expectSuccess(await biometric.enable(localizedReason: reason));
    storage.values[FastUnlockStorageKeys.biometricMaterial(userId)] = jsonEncode(
      {
        'wrapKey': base64Encode(Uint8List(SecurityConstants.vaultKeyLength)),
        'wrapped': {
          'version': SecurityConstants.wrappedKeyVersion,
          'nonce': base64Encode(Uint8List(SecurityConstants.nonceLength)),
          'ciphertext': base64Encode(
            Uint8List(SecurityConstants.vaultKeyLength),
          ),
          'authenticationTag': base64Encode(
            Uint8List(SecurityConstants.authenticationTagLength),
          ),
        },
      },
    );
    session.clear();

    final result = await biometric.unwrapVaultKey(
      userId: userId,
      localizedReason: reason,
    );
    expect(result, isA<FailureResult<Uint8List>>());
    expect(
      (result as FailureResult<Uint8List>).failure,
      isA<AuthenticationFailure>(),
    );
    expect(session.isAuthenticated, isFalse);
  }, timeout: kdfTimeout);

  test('unwrap uses the selected account wrap material', () async {
    final (firstId, firstKey) = await unlockAccount();
    _expectSuccess(await biometric.enable(localizedReason: reason));
    session.clear();

    final second = _expectSuccess(
      await auth.createAccount(
        username: 'رضا',
        masterPassword: masterPassword,
      ),
    );
    _expectSuccess(
      await auth.authenticate(
        userId: second.id,
        masterPassword: masterPassword,
      ),
    );
    final otherKey = Uint8List.fromList(session.vaultKey!);
    session.clear();

    final unwrapped = _expectSuccess(
      await biometric.unwrapVaultKey(
        userId: firstId,
        localizedReason: reason,
      ),
    );
    expect(unwrapped, firstKey);
    expect(unwrapped, isNot(otherKey));
  }, timeout: kdfTimeout);

  test('diagnostic logs do not contain secrets', () async {
    final (userId, vaultKey) = await unlockAccount();
    _expectSuccess(await biometric.enable(localizedReason: reason));
    final payload =
        storage.values[FastUnlockStorageKeys.biometricMaterial(userId)]!;
    final json = jsonDecode(payload) as Map<String, dynamic>;
    session.clear();
    _expectSuccess(
      await biometric.unwrapVaultKey(userId: userId, localizedReason: reason),
    );

    final joined = diagnosticLogs.join('\n');
    expect(joined, isNot(contains(masterPassword)));
    expect(joined, isNot(contains(base64Encode(vaultKey))));
    expect(joined, isNot(contains(json['wrapKey'] as String)));
    expect(joined, isNot(contains(payload)));
    expect(joined, isNot(contains('123456')));
  }, timeout: kdfTimeout);

  test('disable deletes biometric wrap material', () async {
    final (userId, _) = await unlockAccount();
    _expectSuccess(await biometric.enable(localizedReason: reason));
    _expectSuccess(await biometric.disable());
    expect(_expectSuccess(await biometric.isEnabled(userId)), isFalse);
    expect(
      storage.values[FastUnlockStorageKeys.biometricMaterial(userId)],
      isNull,
    );
  }, timeout: kdfTimeout);
}

T _expectSuccess<T>(Result<T> result) {
  expect(result, isA<Success<T>>());
  return (result as Success<T>).data;
}
