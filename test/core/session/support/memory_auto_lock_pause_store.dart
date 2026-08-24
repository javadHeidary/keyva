import 'package:keyva/core/session/auto_lock_pause_store.dart';

class MemoryAutoLockPauseStore implements AutoLockPauseStore {
  DateTime? pausedAt;

  @override
  DateTime? readPausedAt() => pausedAt;

  @override
  Future<void> writePausedAt(DateTime value) async {
    pausedAt = value;
  }

  @override
  Future<void> clearPausedAt() async {
    pausedAt = null;
  }
}
