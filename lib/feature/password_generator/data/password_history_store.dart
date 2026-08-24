import 'dart:convert';

import 'package:get/get.dart';
import 'package:keyva/feature/password_generator/model/password_history_entry.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PasswordHistoryStore extends GetxService {
  PasswordHistoryStore({DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  static const historyKey = 'password_generator_history';
  static const retentionDays = 7;

  final DateTime Function() _clock;

  final RxList<PasswordHistoryEntry> entries = <PasswordHistoryEntry>[].obs;

  SharedPreferences? _prefs;

  Future<PasswordHistoryStore> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _load();
    await purgeExpired();
    return this;
  }

  Future<void> _load() async {
    final prefs = _prefs;
    if (prefs == null) return;

    final raw = prefs.getString(historyKey);
    if (raw == null) return;

    try {
      final list = jsonDecode(raw) as List<dynamic>;
      entries.assignAll(
        list
            .map((e) => PasswordHistoryEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    } catch (_) {
      entries.clear();
    }
  }

  Future<void> _persist() async {
    final prefs = _prefs;
    if (prefs == null) return;
    final json = entries.map((e) => e.toJson()).toList();
    await prefs.setString(historyKey, jsonEncode(json));
  }

  Future<void> purgeExpired() async {
    final cutoff = _clock().subtract(const Duration(days: retentionDays));
    final beforeCount = entries.length;
    entries.removeWhere((entry) => entry.copiedAt.isBefore(cutoff));
    if (entries.length != beforeCount) {
      await _persist();
    }
  }

  Future<void> addFromCopy(String password) async {
    if (password.isEmpty) return;
    await purgeExpired();
    entries.insert(
      0,
      PasswordHistoryEntry(password: password, copiedAt: _clock()),
    );
    await _persist();
  }
}
