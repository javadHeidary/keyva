import 'package:keyva/feature/settings/model/security_settings_ui_state.dart';
import 'package:keyva/feature/settings/model/settings_repository.dart';
import 'package:keyva/feature/settings/model/theme_preference.dart';
import 'package:keyva/feature/settings/model/user_profile.dart';

class FakeSettingsRepository implements SettingsRepository {
  ThemePreference stored = ThemePreference.system;
  bool onboardingCompleted = false;

  @override
  Future<ThemePreference> loadThemePreference() async => stored;

  @override
  Future<void> saveThemePreference(ThemePreference preference) async {
    stored = preference;
  }

  @override
  Future<bool> loadOnboardingCompleted() async => onboardingCompleted;

  @override
  Future<void> saveOnboardingCompleted(bool completed) async {
    onboardingCompleted = completed;
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
