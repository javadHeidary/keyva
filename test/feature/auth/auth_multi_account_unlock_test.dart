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
import 'package:keyva/core/security/biometric_gateway.dart';
import 'package:keyva/core/security/biometric_service_impl.dart';
import 'package:keyva/core/security/pin_service_impl.dart';
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
  late AuthRepositoryImpl auth;
  late PinServiceImpl pin;
  late BiometricServiceImpl biometric;
  late VaultUnlockServiceImpl unlock;
  late FakeBiometricGateway gateway;

  const kdfTimeout = Timeout(Duration(minutes: 2));
  const sharedPassword = 'correct-master-password';
  const otherPassword = 'other-master-password';
  const sharedPin = '123456';

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('keyva_multi_account_');
    database = await HiveDatabase.initialize(testDatabasePath: tempDir.path);
    final users = HiveUserDataSource(database!);
    final crypto = CryptoServiceImpl();
    final keys = FastKeyManagementService(KeyManagementServiceImpl(crypto));
    session = SessionServiceImpl();
    final storage = MemorySecureStorageService();
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
      database: database!,
    );
    gateway = FakeBiometricGateway();
    biometric = BiometricServiceImpl(
      gateway: gateway,
      keys: keys,
      storage: storage,
      users: users,
      session: session,
    );
    unlock = VaultUnlockServiceImpl(
      auth: auth,
      vaults: VaultRepositoryImpl(
        vaults: HiveVaultDataSource(database!),
        crypto: crypto,
        session: session,
      ),
      serializer: VaultSerializerImpl(),
      vaultSession: VaultSessionImpl(),
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

  test('same master password still unlocks only the selected account', () async {
    final first = _expectSuccess(
      await auth.createAccount(username: 'علی', masterPassword: sharedPassword),
    );
    final second = _expectSuccess(
      await auth.createAccount(username: 'رضا', masterPassword: sharedPassword),
    );

    _expectSuccess(
      await unlock.unlock(userId: first.id, masterPassword: sharedPassword),
    );
    expect(session.current!.userId, first.id);
    final firstKey = Uint8List.fromList(session.vaultKey!);
    _expectSuccess(await unlock.lock());

    _expectSuccess(
      await unlock.unlock(userId: second.id, masterPassword: sharedPassword),
    );
    expect(session.current!.userId, second.id);
    expect(session.vaultKey, isNot(firstKey));
  }, timeout: kdfTimeout);

  test('selected account rejects another account password', () async {
    final first = _expectSuccess(
      await auth.createAccount(username: 'علی', masterPassword: sharedPassword),
    );
    _expectSuccess(
      await auth.createAccount(username: 'رضا', masterPassword: otherPassword),
    );

    final result = await unlock.unlock(
      userId: first.id,
      masterPassword: otherPassword,
    );
    expect(result, isA<FailureResult<void>>());
    expect(
      (result as FailureResult<void>).failure,
      isA<AuthenticationFailure>(),
    );
    expect(session.isAuthenticated, isFalse);
  }, timeout: kdfTimeout);

  test('same PIN across accounts does not cause ambiguity', () async {
    final first = _expectSuccess(
      await auth.createAccount(username: 'علی', masterPassword: sharedPassword),
    );
    final second = _expectSuccess(
      await auth.createAccount(username: 'رضا', masterPassword: sharedPassword),
    );

    _expectSuccess(
      await unlock.unlock(userId: first.id, masterPassword: sharedPassword),
    );
    _expectSuccess(await pin.enable(sharedPin));
    _expectSuccess(await unlock.lock());

    _expectSuccess(
      await unlock.unlock(userId: second.id, masterPassword: sharedPassword),
    );
    _expectSuccess(await pin.enable(sharedPin));
    _expectSuccess(await unlock.lock());

    _expectSuccess(await unlock.unlockWithPin(userId: first.id, pin: sharedPin));
    expect(session.current!.userId, first.id);
    _expectSuccess(await unlock.lock());

    _expectSuccess(
      await unlock.unlockWithPin(userId: second.id, pin: sharedPin),
    );
    expect(session.current!.userId, second.id);
  }, timeout: kdfTimeout);

  test('biometric unlocks the selected account Vault Key', () async {
    final first = _expectSuccess(
      await auth.createAccount(username: 'علی', masterPassword: sharedPassword),
    );
    final second = _expectSuccess(
      await auth.createAccount(username: 'رضا', masterPassword: sharedPassword),
    );

    _expectSuccess(
      await unlock.unlock(userId: first.id, masterPassword: sharedPassword),
    );
    _expectSuccess(await biometric.enable(localizedReason: 'enable-a'));
    final firstKey = Uint8List.fromList(session.vaultKey!);
    _expectSuccess(await unlock.lock());

    _expectSuccess(
      await unlock.unlock(userId: second.id, masterPassword: sharedPassword),
    );
    _expectSuccess(await biometric.enable(localizedReason: 'enable-b'));
    _expectSuccess(await unlock.lock());

    _expectSuccess(await unlock.unlockWithBiometric(userId: first.id));
    expect(session.current!.userId, first.id);
    expect(session.vaultKey, firstKey);
  }, timeout: kdfTimeout);

  test('cancelled biometric does not unlock any account', () async {
    final first = _expectSuccess(
      await auth.createAccount(username: 'علی', masterPassword: sharedPassword),
    );
    _expectSuccess(
      await unlock.unlock(userId: first.id, masterPassword: sharedPassword),
    );
    _expectSuccess(await biometric.enable(localizedReason: 'enable'));
    _expectSuccess(await unlock.lock());

    gateway.result = BiometricPromptResult.cancelled;
    final result = await unlock.unlockWithBiometric(userId: first.id);
    expect(result, isA<FailureResult<void>>());
    expect(session.isAuthenticated, isFalse);
  }, timeout: kdfTimeout);
}

T _expectSuccess<T>(Result<T> result) {
  expect(result, isA<Success<T>>());
  return (result as Success<T>).data;
}
