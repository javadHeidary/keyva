import 'dart:convert';

import 'package:get/get.dart';
import 'package:keyva/feature/password_generator/model/password_history_entry.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PasswordHistoryStore extends GetxService {
  static const _historyKey = 'password_generator_history';
  static const _retentionDays = 7;

  final RxList<PasswordHistoryEntry> entries = <PasswordHistoryEntry>[].obs;

  SharedPreferences? _prefs;

  Future<PasswordHistoryStore> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _load();
    _purgeExpired();
    return this;
  }

  Future<void> _load() async {
    final prefs = _prefs;
    if (prefs == null) return;

    final raw = prefs.getString(_historyKey);
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
    await prefs.setString(_historyKey, jsonEncode(json));
  }

  void _purgeExpired() {
    final cutoff = DateTime.now().subtract(const Duration(days: _retentionDays));
    entries.removeWhere((entry) => entry.copiedAt.isBefore(cutoff));
    _persist();
  }

  Future<void> addFromCopy(String password) async {
    if (password.isEmpty) return;
    _purgeExpired();
    entries.insert(
      0,
      PasswordHistoryEntry(password: password, copiedAt: DateTime.now()),
    );
    await _persist();
  }
}
