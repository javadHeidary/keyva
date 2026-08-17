class SecuritySettings {
  const SecuritySettings({
    required this.biometricEnabled,
    required this.pinEnabled,
    required this.autoLockTimeout,
    required this.preventScreenshots,
  });

  final bool biometricEnabled;
  final bool pinEnabled;
  final Duration autoLockTimeout;
  final bool preventScreenshots;
}
