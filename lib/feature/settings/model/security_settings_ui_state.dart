class SecuritySettingsUiState {
  const SecuritySettingsUiState({
    this.biometricEnabled = false,
    this.pinEnabled = false,
    this.preventScreenshot = false,
    this.lockOnAppExit = false,
  });

  final bool biometricEnabled;
  final bool pinEnabled;
  final bool preventScreenshot;
  final bool lockOnAppExit;

  SecuritySettingsUiState copyWith({
    bool? biometricEnabled,
    bool? pinEnabled,
    bool? preventScreenshot,
    bool? lockOnAppExit,
  }) {
    return SecuritySettingsUiState(
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      pinEnabled: pinEnabled ?? this.pinEnabled,
      preventScreenshot: preventScreenshot ?? this.preventScreenshot,
      lockOnAppExit: lockOnAppExit ?? this.lockOnAppExit,
    );
  }
}
