import 'dart:convert';

import 'package:get/get.dart';
import 'package:keyva/feature/password_generator/model/password_generator_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PasswordGeneratorSettingsStore extends GetxService {
  static const _settingsKey = 'password_generator_settings';

  final Rx<PasswordGeneratorSettings> settings =
      const PasswordGeneratorSettings().obs;

  SharedPreferences? _prefs;

  Future<PasswordGeneratorSettingsStore> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _load();
    return this;
  }

  Future<void> _load() async {
    final prefs = _prefs;
    if (prefs == null) return;

    final raw = prefs.getString(_settingsKey);
    if (raw == null) return;

    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      settings.value = PasswordGeneratorSettings.fromJson(json);
    } catch (_) {}
  }

  Future<void> update(PasswordGeneratorSettings value) async {
    settings.value = value;
    final prefs = _prefs;
    if (prefs == null) return;
    await prefs.setString(_settingsKey, jsonEncode(value.toJson()));
  }
}
