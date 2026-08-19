import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:keyva/core/crypto/crypto_service_impl.dart';
import 'package:keyva/core/crypto/key_management_service_impl.dart';
import 'package:keyva/core/database/hive_database.dart';
import 'package:keyva/core/database/hive_user_data_source.dart';
import 'package:keyva/core/exceptions/app_failure.dart';
import 'package:keyva/core/exceptions/result.dart';
import 'package:keyva/core/security/biometric_gateway.dart';
import 'package:keyva/core/security/biometric_service_impl.dart';
import 'package:keyva/core/security/fast_unlock_storage_keys.dart';
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
    auth = AuthRepositoryImpl(
      users: users,
      crypto: crypto,
      keys: keys,
      session: session,
      database: database!,
    );
    biometric = BiometricServiceImpl(
      gateway: gateway,
      keys: keys,
      storage: storage,
      users: users,
      session: session,
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
    expect(_expectSuccess(await biometric.isEnabled(userId)), isFalse);
    expect(storage.values, isEmpty);
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
