import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:keyva/core/constants/security_constants.dart';
import 'package:keyva/core/database/hive_database.dart';
import 'package:keyva/core/database/hive_user_data_source.dart';
import 'package:keyva/core/database/hive_vault_data_source.dart';
import 'package:keyva/core/database/models/kdf_parameters.dart';
import 'package:keyva/core/database/models/security_settings.dart';
import 'package:keyva/core/database/models/user_record.dart';
import 'package:keyva/core/database/models/vault_record.dart';
import 'package:keyva/core/database/models/wrapped_vault_key.dart';
import 'package:keyva/core/exceptions/app_failure.dart';
import 'package:keyva/core/exceptions/result.dart';

void main() {
  late Directory tempDir;
  HiveDatabase? database;
  late HiveVaultDataSource vaults;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('keyva_vaults_');
    database = await HiveDatabase.initialize(testDatabasePath: tempDir.path);
    vaults = HiveVaultDataSource(database!);
  });

  tearDown(() async {
    await database?.close();
    database = null;
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('create then findByUserId returns the persisted vault', () async {
    final record = _vault(userId: 'user-1');

    final created = await vaults.create(record);
    expect(created, isA<Success<void>>());

    final loaded = _expectSuccess(await vaults.findByUserId('user-1'));
    expect(loaded, isNotNull);
    expect(loaded!.userId, 'user-1');
    expect(loaded.formatVersion, SecurityConstants.vaultEncryptionVersion);
    expect(loaded.nonce, record.nonce);
    expect(loaded.ciphertext, record.ciphertext);
    expect(loaded.updatedAt, record.updatedAt);
  });

  test('findByUserId returns null for an unknown user', () async {
    final loaded = _expectSuccess(await vaults.findByUserId('missing'));
    expect(loaded, isNull);
  });

  test('update replaces stored ciphertext for an existing vault', () async {
    await vaults.create(_vault(userId: 'user-1'));

    final updated = _vault(
      userId: 'user-1',
      ciphertext: Uint8List.fromList(List<int>.filled(32, 9)),
      updatedAt: DateTime.utc(2026, 3, 1),
    );
    final result = await vaults.update(updated);
    expect(result, isA<Success<void>>());

    final loaded = _expectSuccess(await vaults.findByUserId('user-1'));
    expect(loaded!.ciphertext, updated.ciphertext);
    expect(loaded.updatedAt, DateTime.utc(2026, 3, 1));
  });

  test('create fails closed when the userId already exists', () async {
    await vaults.create(_vault(userId: 'user-1'));

    final result = await vaults.create(
      _vault(
        userId: 'user-1',
        ciphertext: Uint8List.fromList(List<int>.filled(32, 9)),
      ),
    );
    expect(result, isA<FailureResult<void>>());
    expect((result as FailureResult<void>).failure, isA<DatabaseFailure>());

    final loaded = _expectSuccess(await vaults.findByUserId('user-1'));
    expect(loaded!.ciphertext, _vault(userId: 'user-1').ciphertext);
  });

  test('update fails closed when the vault does not exist', () async {
    final result = await vaults.update(_vault(userId: 'missing'));
    expect(result, isA<FailureResult<void>>());
    expect((result as FailureResult<void>).failure, isA<DatabaseFailure>());
  });

  test('delete removes only the specified vault', () async {
    await vaults.create(_vault(userId: 'user-1'));
    await vaults.create(_vault(userId: 'user-2'));

    final deleted = await vaults.delete('user-1');
    expect(deleted, isA<Success<void>>());

    expect(_expectSuccess(await vaults.findByUserId('user-1')), isNull);
    expect(_expectSuccess(await vaults.findByUserId('user-2')), isNotNull);
  });

  test('delete does not remove an associated UserRecord', () async {
    final users = HiveUserDataSource(database!);
    await users.create(_user(id: 'user-1'));
    await vaults.create(_vault(userId: 'user-1'));

    await vaults.delete('user-1');

    expect(_expectSuccess(await vaults.findByUserId('user-1')), isNull);
    expect(_expectSuccess(await users.findById('user-1')), isNotNull);
  });

  test('maps Hive errors to DatabaseFailure without leaking details', () async {
    await vaults.create(_vault(userId: 'user-1'));
    await database!.close();
    database = null;

    final result = await vaults.create(_vault(userId: 'user-2'));
    expect(result, isA<FailureResult<void>>());
    final failure = (result as FailureResult<void>).failure;
    expect(failure, isA<DatabaseFailure>());
    expect(failure.message, 'Database operation failed');
    expect(failure.message, isNot(contains('HiveError')));
    expect(failure.message, isNot(contains(tempDir.path)));
  });
}

VaultRecord _vault({
  required String userId,
  Uint8List? ciphertext,
  DateTime? updatedAt,
}) {
  return VaultRecord(
    userId: userId,
    formatVersion: SecurityConstants.vaultEncryptionVersion,
    nonce: Uint8List.fromList(List<int>.filled(12, 2)),
    ciphertext: ciphertext ?? Uint8List.fromList(List<int>.filled(32, 3)),
    updatedAt: updatedAt ?? DateTime.utc(2026, 2, 1),
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

T _expectSuccess<T>(Result<T> result) {
  expect(result, isA<Success<T>>());
  return (result as Success<T>).data;
}
