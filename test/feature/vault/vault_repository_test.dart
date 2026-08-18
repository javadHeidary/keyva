import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:keyva/core/constants/security_constants.dart';
import 'package:keyva/core/crypto/crypto_service.dart';
import 'package:keyva/core/crypto/crypto_service_impl.dart';
import 'package:keyva/core/crypto/encrypted_payload.dart';
import 'package:keyva/core/database/hive_database.dart';
import 'package:keyva/core/database/hive_user_data_source.dart';
import 'package:keyva/core/database/hive_vault_data_source.dart';
import 'package:keyva/core/database/models/kdf_parameters.dart';
import 'package:keyva/core/database/models/security_settings.dart';
import 'package:keyva/core/database/models/user_record.dart';
import 'package:keyva/core/database/models/vault_record.dart';
import 'package:keyva/core/database/models/wrapped_vault_key.dart';
import 'package:keyva/core/database/vault_data_source.dart';
import 'package:keyva/core/exceptions/app_failure.dart';
import 'package:keyva/core/exceptions/result.dart';
import 'package:keyva/core/session/session_service.dart';
import 'package:keyva/core/session/session_service_impl.dart';
import 'package:keyva/feature/vault/repository/vault_repository.dart';
import 'package:keyva/feature/vault/repository/vault_repository_impl.dart';

void main() {
  late Directory tempDir;
  HiveDatabase? database;
  late VaultDataSource vaults;
  late HiveUserDataSource users;
  late CryptoService crypto;
  late SessionService session;
  late VaultRepository repository;

  final plaintext = Uint8List.fromList('keyva-plaintext-marker-42'.codeUnits);

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('keyva_vault_repo_');
    database = await HiveDatabase.initialize(testDatabasePath: tempDir.path);
    vaults = HiveVaultDataSource(database!);
    users = HiveUserDataSource(database!);
    crypto = CryptoServiceImpl();
    session = SessionServiceImpl();
    repository = VaultRepositoryImpl(
      vaults: vaults,
      crypto: crypto,
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

  test('unauthenticated save fails closed', () async {
    _expectFailure<AuthenticationFailure>(
      await repository.saveVaultData(plaintext),
    );
  });

  test('unauthenticated load fails closed', () async {
    _expectFailure<AuthenticationFailure>(await repository.loadVaultData());
  });

  test('unauthenticated delete fails closed', () async {
    _expectFailure<AuthenticationFailure>(await repository.deleteVault());
  });

  test('save then load round-trips plaintext through Hive', () async {
    _authenticate(session, crypto);

    _expectSuccess(await repository.saveVaultData(plaintext));
    final loaded = _expectSuccess(await repository.loadVaultData());

    expect(loaded, plaintext);
  });

  test('persisted ciphertext does not contain plaintext', () async {
    _authenticate(session, crypto);

    _expectSuccess(await repository.saveVaultData(plaintext));
    final record = _expectSuccess(await vaults.findByUserId('user-1'));

    expect(record, isNotNull);
    expect(_containsSequence(record!.ciphertext, plaintext), isFalse);
    expect(_containsSequence(record.nonce, plaintext), isFalse);
  });

  test('every save uses a fresh nonce', () async {
    _authenticate(session, crypto);

    _expectSuccess(await repository.saveVaultData(plaintext));
    final first = _expectSuccess(await vaults.findByUserId('user-1'))!;

    _expectSuccess(await repository.saveVaultData(plaintext));
    final second = _expectSuccess(await vaults.findByUserId('user-1'))!;

    expect(second.nonce, isNot(first.nonce));
    expect(database!.vaults.length, 1);
  });

  test('persisted authentication tag reconstructs EncryptedPayload', () async {
    _authenticate(session, crypto);

    _expectSuccess(await repository.saveVaultData(plaintext));
    final record = _expectSuccess(await vaults.findByUserId('user-1'))!;

    expect(record.formatVersion, SecurityConstants.vaultEncryptionVersion);
    expect(record.nonce.length, SecurityConstants.nonceLength);
    expect(
      record.ciphertext.length,
      greaterThanOrEqualTo(SecurityConstants.authenticationTagLength),
    );

    final splitAt =
        record.ciphertext.length - SecurityConstants.authenticationTagLength;
    final payload = EncryptedPayload(
      version: record.formatVersion,
      nonce: record.nonce,
      ciphertext: Uint8List.sublistView(record.ciphertext, 0, splitAt),
      authenticationTag: Uint8List.sublistView(record.ciphertext, splitAt),
    );

    final decrypted = _expectSuccess(
      await crypto.decrypt(payload: payload, key: session.vaultKey!),
    );
    expect(decrypted, plaintext);
  });

  test('tampered ciphertext fails with VaultDecryptionFailure', () async {
    _authenticate(session, crypto);
    _expectSuccess(await repository.saveVaultData(plaintext));

    final stored = _expectSuccess(await vaults.findByUserId('user-1'))!;
    final tampered = Uint8List.fromList(stored.ciphertext);
    tampered[0] = tampered[0] ^ 0xFF;
    _expectSuccess(
      await vaults.update(
        VaultRecord(
          userId: stored.userId,
          formatVersion: stored.formatVersion,
          nonce: stored.nonce,
          ciphertext: tampered,
          updatedAt: stored.updatedAt,
        ),
      ),
    );

    _expectFailure<VaultDecryptionFailure>(await repository.loadVaultData());
  });

  test('tampered authentication tag fails with VaultDecryptionFailure', () async {
    _authenticate(session, crypto);
    _expectSuccess(await repository.saveVaultData(plaintext));

    final stored = _expectSuccess(await vaults.findByUserId('user-1'))!;
    final tampered = Uint8List.fromList(stored.ciphertext);
    tampered[tampered.length - 1] = tampered[tampered.length - 1] ^ 0xFF;
    _expectSuccess(
      await vaults.update(
        VaultRecord(
          userId: stored.userId,
          formatVersion: stored.formatVersion,
          nonce: stored.nonce,
          ciphertext: tampered,
          updatedAt: stored.updatedAt,
        ),
      ),
    );

    _expectFailure<VaultDecryptionFailure>(await repository.loadVaultData());
  });

  test('wrong Vault Key fails with VaultDecryptionFailure', () async {
    _authenticate(session, crypto);
    _expectSuccess(await repository.saveVaultData(plaintext));

    session.setAuthenticated(
      userId: 'user-1',
      username: 'علی',
      vaultKey: crypto.generateSecureBytes(SecurityConstants.vaultKeyLength),
    );

    _expectFailure<VaultDecryptionFailure>(await repository.loadVaultData());
  });

  test('malformed ciphertext fails closed', () async {
    _authenticate(session, crypto);
    _expectSuccess(
      await vaults.create(
        VaultRecord(
          userId: 'user-1',
          formatVersion: SecurityConstants.vaultEncryptionVersion,
          nonce: Uint8List.fromList(
            List<int>.filled(SecurityConstants.nonceLength, 1),
          ),
          ciphertext: Uint8List.fromList([1, 2, 3]),
          updatedAt: DateTime.utc(2026, 2, 1),
        ),
      ),
    );

    _expectFailure<CryptoFailure>(await repository.loadVaultData());
  });

  test('unsupported format version fails closed', () async {
    _authenticate(session, crypto);
    _expectSuccess(
      await vaults.create(
        VaultRecord(
          userId: 'user-1',
          formatVersion: 99,
          nonce: Uint8List.fromList(
            List<int>.filled(SecurityConstants.nonceLength, 1),
          ),
          ciphertext: Uint8List.fromList(List<int>.filled(32, 3)),
          updatedAt: DateTime.utc(2026, 2, 1),
        ),
      ),
    );

    _expectFailure<CryptoFailure>(await repository.loadVaultData());
  });

  test('missing VaultRecord returns Success(null)', () async {
    _authenticate(session, crypto);

    final loaded = _expectSuccess(await repository.loadVaultData());
    expect(loaded, isNull);
  });

  test('first save creates and subsequent save updates the same record', () async {
    _authenticate(session, crypto);

    _expectSuccess(await repository.saveVaultData(plaintext));
    expect(database!.vaults.length, 1);

    final otherPlaintext = Uint8List.fromList('second-payload'.codeUnits);
    _expectSuccess(await repository.saveVaultData(otherPlaintext));
    expect(database!.vaults.length, 1);

    final loaded = _expectSuccess(await repository.loadVaultData());
    expect(loaded, otherPlaintext);
  });

  test('deleteVault removes the VaultRecord and leaves UserRecord', () async {
    _authenticate(session, crypto);
    _expectSuccess(await users.create(_user(id: 'user-1')));
    _expectSuccess(await repository.saveVaultData(plaintext));

    _expectSuccess(await repository.deleteVault());

    expect(_expectSuccess(await vaults.findByUserId('user-1')), isNull);
    expect(_expectSuccess(await users.findById('user-1')), isNotNull);
    expect(session.isAuthenticated, isTrue);
    expect(session.vaultKey, isNotNull);
  });

  test('repository uses SessionService Vault Key without a Master Password', () async {
    final vaultKey = crypto.generateSecureBytes(SecurityConstants.vaultKeyLength);
    session.setAuthenticated(
      userId: 'user-1',
      username: 'علی',
      vaultKey: vaultKey,
    );

    _expectSuccess(await repository.saveVaultData(plaintext));
    final loaded = _expectSuccess(await repository.loadVaultData());
    expect(loaded, plaintext);
    expect(session.vaultKey, vaultKey);
  });
}

void _authenticate(SessionService session, CryptoService crypto) {
  session.setAuthenticated(
    userId: 'user-1',
    username: 'علی',
    vaultKey: crypto.generateSecureBytes(SecurityConstants.vaultKeyLength),
  );
}

UserRecord _user({required String id}) {
  return UserRecord(
    id: id,
    username: 'علی',
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 2),
    kdfSalt: Uint8List.fromList(List<int>.filled(16, 1)),
    kdfParameters: const KdfParameters(
      algorithm: SecurityConstants.kdfAlgorithm,
      memoryCost: SecurityConstants.kdfMemoryCost,
      timeCost: SecurityConstants.kdfTimeCost,
      parallelism: SecurityConstants.kdfParallelism,
      outputLength: SecurityConstants.kdfOutputLength,
    ),
    wrappedVaultKey: WrappedVaultKey(
      version: SecurityConstants.wrappedKeyVersion,
      nonce: Uint8List.fromList(List<int>.filled(12, 2)),
      ciphertext: Uint8List.fromList(List<int>.filled(48, 3)),
      authenticationTag: Uint8List.fromList(List<int>.filled(16, 4)),
    ),
    securitySettings: SecuritySettings.initial(),
  );
}

bool _containsSequence(Uint8List haystack, Uint8List needle) {
  if (needle.isEmpty || haystack.length < needle.length) {
    return false;
  }
  for (var i = 0; i <= haystack.length - needle.length; i++) {
    var matched = true;
    for (var j = 0; j < needle.length; j++) {
      if (haystack[i + j] != needle[j]) {
        matched = false;
        break;
      }
    }
    if (matched) {
      return true;
    }
  }
  return false;
}

T _expectSuccess<T>(Result<T> result) {
  expect(result, isA<Success<T>>());
  return (result as Success<T>).data;
}

void _expectFailure<F extends AppFailure>(Result<dynamic> result) {
  expect(result, isA<FailureResult<dynamic>>());
  final failure = (result as FailureResult<dynamic>).failure;
  expect(failure, isA<F>());
  expect(failure.message, isNot(contains('SecretBox')));
  expect(failure.message, isNot(contains('GCM')));
  expect(failure.message, isNot(contains('HiveError')));
}
