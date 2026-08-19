class SecuritySettings {
  const SecuritySettings({
    required this.biometricEnabled,
    required this.pinEnabled,
    required this.autoLockTimeout,
    required this.preventScreenshots,
  });

  factory SecuritySettings.initial() {
    return const SecuritySettings(
      biometricEnabled: false,
      pinEnabled: false,
      autoLockTimeout: Duration(minutes: 1),
      preventScreenshots: false,
    );
  }

  final bool biometricEnabled;
  final bool pinEnabled;
  final Duration autoLockTimeout;
  final bool preventScreenshots;

  SecuritySettings copyWith({
    bool? biometricEnabled,
    bool? pinEnabled,
    Duration? autoLockTimeout,
    bool? preventScreenshots,
  }) {
    return SecuritySettings(
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      pinEnabled: pinEnabled ?? this.pinEnabled,
      autoLockTimeout: autoLockTimeout ?? this.autoLockTimeout,
      preventScreenshots: preventScreenshots ?? this.preventScreenshots,
    );
  }
}
