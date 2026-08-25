import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:keyva/core/database/hive_database.dart';
import 'package:keyva/feature/settings/repository/settings_repository_impl.dart';

void main() {
  late Directory tempDir;
  HiveDatabase? database;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('keyva_item_type_guide_');
  });

  tearDown(() async {
    await database?.close();
    database = null;
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('missing guide flags load as unseen', () async {
    database = await HiveDatabase.initialize(testDatabasePath: tempDir.path);
    final repository = SettingsRepositoryImpl(database!);

    expect(await repository.loadItemTypeGuideStatus('login'), isNull);
    expect(await repository.loadItemTypeGuideStatus('bankCard'), isNull);
  });

  test('guide status is stored independently per item type', () async {
    database = await HiveDatabase.initialize(testDatabasePath: tempDir.path);
    final repository = SettingsRepositoryImpl(database!);

    await repository.saveItemTypeGuideStatus('login', 'dismissed');
    await repository.saveItemTypeGuideStatus('bankCard', 'acknowledged');

    expect(await repository.loadItemTypeGuideStatus('login'), 'dismissed');
    expect(
      await repository.loadItemTypeGuideStatus('bankCard'),
      'acknowledged',
    );
    expect(await repository.loadItemTypeGuideStatus('secureNote'), isNull);
  });

  test('saved guide status is restored after restart', () async {
    database = await HiveDatabase.initialize(testDatabasePath: tempDir.path);
    final first = SettingsRepositoryImpl(database!);
    await first.saveItemTypeGuideStatus('login', 'sampleCreated');
    expect(await first.loadItemTypeGuideStatus('login'), 'sampleCreated');

    await database!.close();
    database = null;

    database = await HiveDatabase.initialize(testDatabasePath: tempDir.path);
    final second = SettingsRepositoryImpl(database!);
    expect(await second.loadItemTypeGuideStatus('login'), 'sampleCreated');
    expect(await second.loadItemTypeGuideStatus('bankCard'), isNull);
  });
}
