import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:keyva/core/constants/database_constants.dart';
import 'package:keyva/core/database/hive_database.dart';
import 'package:keyva/core/session/auto_lock_pause_store.dart';

void main() {
  late Directory tempDir;
  HiveDatabase? database;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('keyva_auto_lock_pause_');
    database = await HiveDatabase.initialize(testDatabasePath: tempDir.path);
  });

  tearDown(() async {
    await database?.close();
    database = null;
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('round-trips lastBackgroundedAt through app_settings', () async {
    final store = HiveAutoLockPauseStore(database!);
    final pausedAt = DateTime.utc(2026, 8, 23, 12, 30, 15);

    expect(store.readPausedAt(), isNull);

    await store.writePausedAt(pausedAt);

    expect(
      database!.appSettings.get(HiveSettingsKeys.lastBackgroundedAt),
      pausedAt.millisecondsSinceEpoch,
    );
    expect(store.readPausedAt(), pausedAt);

    await store.clearPausedAt();

    expect(store.readPausedAt(), isNull);
    expect(
      database!.appSettings.get(HiveSettingsKeys.lastBackgroundedAt),
      isNull,
    );
  });
}
