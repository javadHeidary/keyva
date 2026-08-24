import 'package:keyva/core/constants/database_constants.dart';
import 'package:keyva/core/database/hive_database.dart';

abstract interface class AutoLockPauseStore {
  DateTime? readPausedAt();

  Future<void> writePausedAt(DateTime pausedAt);

  Future<void> clearPausedAt();
}

class HiveAutoLockPauseStore implements AutoLockPauseStore {
  HiveAutoLockPauseStore(this._database);

  final HiveDatabase _database;

  @override
  DateTime? readPausedAt() {
    try {
      final stored = _database.appSettings.get(
        HiveSettingsKeys.lastBackgroundedAt,
      );
      if (stored is int) {
        return DateTime.fromMillisecondsSinceEpoch(stored, isUtc: true);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> writePausedAt(DateTime pausedAt) async {
    try {
      await _database.appSettings.put(
        HiveSettingsKeys.lastBackgroundedAt,
        pausedAt.toUtc().millisecondsSinceEpoch,
      );
    } catch (_) {}
  }

  @override
  Future<void> clearPausedAt() async {
    try {
      await _database.appSettings.delete(HiveSettingsKeys.lastBackgroundedAt);
    } catch (_) {}
  }
}
