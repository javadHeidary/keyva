import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:keyva/core/constants/database_constants.dart';
import 'package:keyva/core/database/hive_database.dart';
import 'package:keyva/core/di/injection_container.dart';
import 'package:keyva/core/exceptions/app_failure.dart';

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

  test('initialize with testDatabasePath opens boxes and writes version 1', () async {
    database = await HiveDatabase.initialize(testDatabasePath: tempDir.path);

    expect(database!.users.isOpen, isTrue);
    expect(database!.vaults.isOpen, isTrue);
    expect(database!.appSettings.isOpen, isTrue);
    expect(
      database!.appSettings.get(HiveSettingsKeys.databaseVersion),
      DatabaseConfig.currentVersion,
    );
  });

  test('initialize fails closed when the schema version is unsupported', () async {
    database = await HiveDatabase.initialize(testDatabasePath: tempDir.path);
    await database!.appSettings.put(HiveSettingsKeys.databaseVersion, 99);
    await database!.close();
    database = null;

    await expectLater(
      HiveDatabase.initialize(testDatabasePath: tempDir.path),
      throwsA(isA<DatabaseFailure>()),
    );
  });

  test('initDependencies registers HiveDatabase', () async {
    database = await HiveDatabase.initialize(testDatabasePath: tempDir.path);
    await getIt.reset();
    initDependencies(database!);

    expect(getIt<HiveDatabase>(), same(database));
    await getIt.reset();
  });
}
