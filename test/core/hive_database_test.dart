import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:keyva/core/constants/database_constants.dart';
import 'package:keyva/core/crypto/crypto_service.dart';
import 'package:keyva/core/crypto/key_management_service.dart';
import 'package:keyva/core/database/hive_database.dart';
import 'package:keyva/core/database/user_data_source.dart';
import 'package:keyva/core/database/vault_data_source.dart';
import 'package:keyva/core/di/injection_container.dart';
import 'package:keyva/core/exceptions/app_failure.dart';
import 'package:keyva/core/session/session_service.dart';
import 'package:keyva/feature/auth/repository/auth_repository.dart';
import 'package:keyva/feature/vault/repository/vault_repository.dart';
import 'package:keyva/feature/vault/serialization/vault_serializer.dart';
import 'package:keyva/feature/vault/service/vault_data_service.dart';
import 'package:keyva/feature/vault/service/vault_unlock_service.dart';
import 'package:keyva/feature/vault/session/vault_session.dart';

void main() {
  late Directory tempDir;
  HiveDatabase? database;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('keyva_hive_');
  });

  tearDown(() async {
    await database?.close();
    database = null;
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test(
    'initialize with testDatabasePath opens boxes and writes version 1',
    () async {
      database = await HiveDatabase.initialize(testDatabasePath: tempDir.path);

      expect(database!.users.isOpen, isTrue);
      expect(database!.vaults.isOpen, isTrue);
      expect(database!.appSettings.isOpen, isTrue);
      expect(
        database!.appSettings.get(HiveSettingsKeys.databaseVersion),
        DatabaseConfig.currentVersion,
      );
    },
  );

  test(
    'initialize fails closed when the schema version is unsupported',
    () async {
      database = await HiveDatabase.initialize(testDatabasePath: tempDir.path);
      await database!.appSettings.put(HiveSettingsKeys.databaseVersion, 99);
      await database!.close();
      database = null;

      await expectLater(
        HiveDatabase.initialize(testDatabasePath: tempDir.path),
        throwsA(isA<DatabaseFailure>()),
      );
    },
  );

  test(
    'initDependencies registers HiveDatabase, crypto, session, auth, and vault',
    () async {
      database = await HiveDatabase.initialize(testDatabasePath: tempDir.path);
      await getIt.reset();
      initDependencies(database!);

      expect(getIt<HiveDatabase>(), same(database));
      expect(getIt.isRegistered<UserDataSource>(), isTrue);
      expect(getIt.isRegistered<VaultDataSource>(), isTrue);
      expect(getIt.isRegistered<CryptoService>(), isTrue);
      expect(getIt.isRegistered<KeyManagementService>(), isTrue);
      expect(getIt.isRegistered<SessionService>(), isTrue);
      expect(getIt.isRegistered<VaultSerializer>(), isTrue);
      expect(getIt.isRegistered<AuthRepository>(), isTrue);
      expect(getIt.isRegistered<VaultRepository>(), isTrue);
      expect(getIt.isRegistered<VaultSession>(), isTrue);
      expect(getIt.isRegistered<VaultUnlockService>(), isTrue);
      expect(getIt.isRegistered<VaultDataService>(), isTrue);
      await getIt.reset();
    },
  );
}
