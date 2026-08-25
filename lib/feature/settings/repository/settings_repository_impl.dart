import 'package:keyva/core/constants/database_constants.dart';
import 'package:keyva/core/database/hive_database.dart';
import 'package:keyva/feature/settings/model/security_settings_ui_state.dart';
import 'package:keyva/feature/settings/model/settings_repository.dart';
import 'package:keyva/feature/settings/model/theme_preference.dart';
import 'package:keyva/feature/settings/model/user_profile.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl(this._database);

  final HiveDatabase _database;

  @override
  Future<ThemePreference> loadThemePreference() async {
    final stored = _database.appSettings.get(HiveSettingsKeys.themePreference);
    return ThemePreference.fromStorage(stored);
  }

  @override
  Future<void> saveThemePreference(ThemePreference preference) {
    return _database.appSettings.put(
      HiveSettingsKeys.themePreference,
      preference.name,
    );
  }

  @override
  Future<bool> loadOnboardingCompleted() async {
    return _database.appSettings.get(HiveSettingsKeys.onboardingCompleted) ==
        true;
  }

  @override
  Future<void> saveOnboardingCompleted(bool completed) {
    return _database.appSettings.put(
      HiveSettingsKeys.onboardingCompleted,
      completed,
    );
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
