import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:keyva/core/constants/database_constants.dart';
import 'package:keyva/core/constants/security_constants.dart';
import 'package:keyva/core/database/hive_database.dart';
import 'package:keyva/core/database/hive_user_data_source.dart';
import 'package:keyva/core/database/models/kdf_parameters.dart';
import 'package:keyva/core/database/models/security_settings.dart';
import 'package:keyva/core/database/models/user_record.dart';
import 'package:keyva/core/database/models/wrapped_vault_key.dart';
import 'package:keyva/core/exceptions/app_failure.dart';
import 'package:keyva/core/exceptions/result.dart';
import 'package:keyva/core/security/screen_protection_service_impl.dart';
import 'package:keyva/core/session/session_service_impl.dart';

import 'support/fake_screen_protection_gateway.dart';

void main() {
  late Directory tempDir;
  HiveDatabase? database;
  late HiveUserDataSource users;
  late SessionServiceImpl session;
  late FakeScreenProtectionGateway gateway;
  late ScreenProtectionServiceImpl service;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('keyva_screen_protection_');
    database = await HiveDatabase.initialize(testDatabasePath: tempDir.path);
    users = HiveUserDataSource(database!);
    session = SessionServiceImpl();
    gateway = FakeScreenProtectionGateway();
    service = ScreenProtectionServiceImpl(
      gateway: gateway,
      users: users,
      session: session,
      database: database!,
    );
  });

  tearDown(() async {
    try {
      await database?.close();
    } catch (_) {}
    database = null;
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('default preventScreenshots setting is off', () {
    expect(SecuritySettings.initial().preventScreenshots, isFalse);
  });

  test('applyPersisted is off when no accounts exist', () async {
    final result = await service.applyPersisted();
    expect(result, isA<Success<void>>());
    expect(service.isEnabled, isFalse);
    expect(gateway.lastEnabled, isFalse);
  });

  test('setEnabled applies and tracks runtime protection', () async {
    expect(service.isEnabled, isFalse);

    expect(await service.setEnabled(true), isA<Success<void>>());
    expect(service.isEnabled, isTrue);
    expect(gateway.lastEnabled, isTrue);

    expect(await service.setEnabled(false), isA<Success<void>>());
    expect(service.isEnabled, isFalse);
    expect(gateway.lastEnabled, isFalse);
  });

  test('platform failure does not update runtime protection', () async {
    gateway.failure = const ScreenProtectionFailure();

    final result = await service.setEnabled(true);
    expect(result, isA<FailureResult<void>>());
    expect((result as FailureResult<void>).failure, isA<ScreenProtectionFailure>());
    expect(service.isEnabled, isFalse);
  });

  test('applyPersisted follows the authenticated user setting', () async {
    await users.create(_user(id: 'user-1', preventScreenshots: true));
    session.setAuthenticated(
      userId: 'user-1',
      username: 'علی',
      vaultKey: Uint8List(32),
    );

    expect(await service.applyPersisted(), isA<Success<void>>());
    expect(service.isEnabled, isTrue);
    expect(gateway.lastEnabled, isTrue);
  });

  test('runtime protection follows a persisted setting change', () async {
    final created = _user(id: 'user-1', preventScreenshots: true);
    await users.create(created);
    session.setAuthenticated(
      userId: 'user-1',
      username: 'علی',
      vaultKey: Uint8List(32),
    );

    expect(await service.applyPersisted(), isA<Success<void>>());
    expect(service.isEnabled, isTrue);

    await users.update(
      created.copyWith(
        securitySettings: created.securitySettings.copyWith(
          preventScreenshots: false,
        ),
      ),
    );

    expect(await service.applyPersisted(), isA<Success<void>>());
    expect(service.isEnabled, isFalse);
    expect(gateway.lastEnabled, isFalse);
  });

  test('applyPersisted uses the remembered active user when locked', () async {
    await users.create(_user(id: 'user-1', preventScreenshots: false));
    await users.create(_user(id: 'user-2', preventScreenshots: true));
    await database!.appSettings.put(HiveSettingsKeys.activeUserId, 'user-2');

    expect(await service.applyPersisted(), isA<Success<void>>());
    expect(service.isEnabled, isTrue);
    expect(gateway.lastEnabled, isTrue);
  });

  test('applyPersisted enables if any account is protected when none is active', () async {
    await users.create(_user(id: 'user-1', preventScreenshots: false));
    await users.create(_user(id: 'user-2', preventScreenshots: true));

    expect(await service.applyPersisted(), isA<Success<void>>());
    expect(service.isEnabled, isTrue);
  });

  test('Hive lookup failure does not clear FLAG_SECURE', () async {
    await users.create(_user(id: 'user-1', preventScreenshots: true));
    session.setAuthenticated(
      userId: 'user-1',
      username: 'علی',
      vaultKey: Uint8List(32),
    );
    expect(await service.setEnabled(true), isA<Success<void>>());
    expect(gateway.calls, [true]);

    await database!.close();
    database = null;

    final result = await service.applyPersisted();
    expect(result, isA<FailureResult<void>>());
    expect(service.isEnabled, isTrue);
    expect(gateway.calls, [true]);
  });
}

UserRecord _user({required String id, required bool preventScreenshots}) {
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
    securitySettings: SecuritySettings.initial().copyWith(
      preventScreenshots: preventScreenshots,
    ),
  );
}
