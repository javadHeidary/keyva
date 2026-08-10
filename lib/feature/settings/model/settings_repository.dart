import 'package:keyva/feature/settings/model/security_settings_ui_state.dart';
import 'package:keyva/feature/settings/model/theme_preference.dart';
import 'package:keyva/feature/settings/model/user_profile.dart';

abstract class SettingsRepository {
  Future<UserProfile> loadProfile();

  Future<void> saveProfile(UserProfile profile);

  Future<ThemePreference> loadThemePreference();

  Future<void> saveThemePreference(ThemePreference preference);

  Future<SecuritySettingsUiState> loadSecuritySettings();

  Future<void> saveSecuritySettings(SecuritySettingsUiState state);

  Future<bool> isBiometricAvailable();

  Future<void> changeMasterPassword({
    required String currentPassword,
    required String newPassword,
  });

  Future<void> savePin(String pin);

  Future<void> logout();

  Future<void> exportBackup();

  Future<void> importBackup();
}
