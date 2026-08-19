import 'package:keyva/core/security/auto_lock_policy.dart';

class SecuritySettingsUiState {
  const SecuritySettingsUiState({
    this.biometricEnabled = false,
    this.pinEnabled = false,
    this.preventScreenshot = false,
    this.autoLockTimeout = AutoLockPolicy.oneMinute,
  });

  final bool biometricEnabled;
  final bool pinEnabled;
  final bool preventScreenshot;
  final Duration autoLockTimeout;

  SecuritySettingsUiState copyWith({
    bool? biometricEnabled,
    bool? pinEnabled,
    bool? preventScreenshot,
    Duration? autoLockTimeout,
  }) {
    return SecuritySettingsUiState(
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      pinEnabled: pinEnabled ?? this.pinEnabled,
      preventScreenshot: preventScreenshot ?? this.preventScreenshot,
      autoLockTimeout: autoLockTimeout ?? this.autoLockTimeout,
    );
  }
}
