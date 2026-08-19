import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:keyva/core/constants/security_constants.dart';
import 'package:keyva/core/database/hive_database.dart';
import 'package:keyva/core/database/hive_user_data_source.dart';
import 'package:keyva/core/database/models/kdf_parameters.dart';
import 'package:keyva/core/database/models/security_settings.dart';
import 'package:keyva/core/database/models/user_record.dart';
import 'package:keyva/core/database/models/wrapped_vault_key.dart';
import 'package:keyva/core/exceptions/app_failure.dart';
import 'package:keyva/core/exceptions/result.dart';

void main() {
  late Directory tempDir;
  HiveDatabase? database;
  late HiveUserDataSource users;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('keyva_users_');
    database = await HiveDatabase.initialize(testDatabasePath: tempDir.path);
    users = HiveUserDataSource(database!);
  });

  tearDown(() async {
    await database?.close();
    database = null;
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('create then findById returns the persisted user', () async {
    final record = _user(id: 'user-1');

    final created = await users.create(record);
    expect(created, isA<Success<void>>());

    final loaded = await users.findById('user-1');
    final found = _expectSuccess(loaded);
    expect(found, isNotNull);
    expect(found!.id, 'user-1');
    expect(found.username, 'علی');
    expect(found.kdfSalt, record.kdfSalt);
    expect(found.kdfParameters.algorithm, SecurityConstants.kdfAlgorithm);
    expect(found.wrappedVaultKey.version, SecurityConstants.wrappedKeyVersion);
  });

  test('exists is false until the user is created', () async {
    expect(_expectSuccess(await users.exists('user-1')), isFalse);

    await users.create(_user(id: 'user-1'));

    expect(_expectSuccess(await users.exists('user-1')), isTrue);
    expect(_expectSuccess(await users.exists('missing')), isFalse);
  });

  test('update replaces stored metadata for an existing user', () async {
    await users.create(_user(id: 'user-1', username: 'اول'));

    final updated = _user(id: 'user-1', username: 'دوم');
    final result = await users.update(updated);
    expect(result, isA<Success<void>>());

    final loaded = _expectSuccess(await users.findById('user-1'));
    expect(loaded!.username, 'دوم');
  });

  test('create fails closed when the user id already exists', () async {
    await users.create(_user(id: 'user-1'));

    final result = await users.create(_user(id: 'user-1', username: 'دیگر'));
    expect(result, isA<FailureResult<void>>());
    expect(
      (result as FailureResult<void>).failure,
      isA<DatabaseFailure>(),
    );

    final loaded = _expectSuccess(await users.findById('user-1'));
    expect(loaded!.username, 'علی');
  });

  test('update fails closed when the user does not exist', () async {
    final result = await users.update(_user(id: 'missing'));
    expect(result, isA<FailureResult<void>>());
    expect(
      (result as FailureResult<void>).failure,
      isA<DatabaseFailure>(),
    );
  });

  test('findById returns null for an unknown id', () async {
    final loaded = _expectSuccess(await users.findById('missing'));
    expect(loaded, isNull);
  });

  test('listIds returns persisted user ids', () async {
    expect(_expectSuccess(await users.listIds()), isEmpty);

    await users.create(_user(id: 'user-1'));
    await users.create(_user(id: 'user-2'));

    final ids = _expectSuccess(await users.listIds());
    expect(ids, containsAll(<String>['user-1', 'user-2']));
    expect(ids, hasLength(2));
  });
}

UserRecord _user({required String id, String username = 'علی'}) {
  return UserRecord(
    id: id,
    username: username,
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
