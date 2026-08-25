import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:keyva/core/database/hive_database.dart';
import 'package:keyva/feature/settings/repository/settings_repository_impl.dart';

void main() {
  late Directory tempDir;
  HiveDatabase? database;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('keyva_onboarding_');
  });

  tearDown(() async {
    await database?.close();
    database = null;
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('missing onboarding flag loads as not completed', () async {
    database = await HiveDatabase.initialize(testDatabasePath: tempDir.path);
    final repository = SettingsRepositoryImpl(database!);

    expect(await repository.loadOnboardingCompleted(), isFalse);
  });

  test('saved onboarding flag is restored after restart', () async {
    database = await HiveDatabase.initialize(testDatabasePath: tempDir.path);
    final first = SettingsRepositoryImpl(database!);
    await first.saveOnboardingCompleted(true);
    expect(await first.loadOnboardingCompleted(), isTrue);

    await database!.close();
    database = null;

    database = await HiveDatabase.initialize(testDatabasePath: tempDir.path);
    final second = SettingsRepositoryImpl(database!);
    expect(await second.loadOnboardingCompleted(), isTrue);
  });
}
