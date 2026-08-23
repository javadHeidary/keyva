import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:keyva/feature/settings/model/security_settings_ui_state.dart';
import 'package:keyva/feature/settings/model/settings_repository.dart';
import 'package:keyva/feature/settings/model/theme_preference.dart';
import 'package:keyva/feature/settings/model/user_profile.dart';
import 'package:keyva/feature/settings/viewmodel/settings_viewmodel.dart';
import 'package:keyva/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeSettingsRepository repository;

  setUp(() {
    Get.testMode = true;
    repository = FakeSettingsRepository();
  });

  tearDown(Get.reset);

  test('setThemePreference persists and a new ViewModel restores it', () async {
    final first = SettingsViewModel(repository: repository);
    await first.setThemePreference(ThemePreference.dark);

    expect(first.themePreference.value, ThemePreference.dark);
    expect(repository.stored, ThemePreference.dark);

    final second = SettingsViewModel(repository: repository);
    await second.loadThemePreference();
    expect(second.themePreference.value, ThemePreference.dark);
  });

  test('KeyvaApp uses the provided themeMode instead of system', () {
    const app = KeyvaApp(themeMode: ThemeMode.dark);
    expect(app.themeMode, ThemeMode.dark);
  });
}

class FakeSettingsRepository implements SettingsRepository {
  ThemePreference stored = ThemePreference.system;

  @override
  Future<ThemePreference> loadThemePreference() async => stored;

  @override
  Future<void> saveThemePreference(ThemePreference preference) async {
    stored = preference;
  }

  @override
  Future<UserProfile> loadProfile() {
    throw UnimplementedError();
  }

  @override
  Future<void> saveProfile(UserProfile profile) {
    throw UnimplementedError();
  }

  @override
  Future<SecuritySettingsUiState> loadSecuritySettings() {
    throw UnimplementedError();
  }

  @override
  Future<void> saveSecuritySettings(SecuritySettingsUiState state) {
    throw UnimplementedError();
  }

  @override
  Future<bool> isBiometricAvailable() {
    throw UnimplementedError();
  }

  @override
  Future<void> changeMasterPassword({
    required String currentPassword,
    required String newPassword,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> savePin(String pin) {
    throw UnimplementedError();
  }

  @override
  Future<void> logout() {
    throw UnimplementedError();
  }
}
