import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:keyva/core/database/hive_database.dart';
import 'package:keyva/feature/settings/model/theme_preference.dart';
import 'package:keyva/feature/settings/repository/settings_repository_impl.dart';

void main() {
  late Directory tempDir;
  HiveDatabase? database;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('keyva_theme_');
  });

  tearDown(() async {
    await database?.close();
    database = null;
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('missing preference loads as system', () async {
    database = await HiveDatabase.initialize(testDatabasePath: tempDir.path);
    final repository = SettingsRepositoryImpl(database!);

    expect(await repository.loadThemePreference(), ThemePreference.system);
  });

  test('saved theme preference is restored after restart', () async {
    database = await HiveDatabase.initialize(testDatabasePath: tempDir.path);
    final first = SettingsRepositoryImpl(database!);
    await first.saveThemePreference(ThemePreference.dark);
    expect(await first.loadThemePreference(), ThemePreference.dark);

    await database!.close();
    database = null;

    database = await HiveDatabase.initialize(testDatabasePath: tempDir.path);
    final second = SettingsRepositoryImpl(database!);
    expect(await second.loadThemePreference(), ThemePreference.dark);
    expect(
      (await second.loadThemePreference()).themeMode,
      ThemePreference.dark.themeMode,
    );
  });
}
