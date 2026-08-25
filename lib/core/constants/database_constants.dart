abstract final class HiveBoxNames {
  static const users = 'users';
  static const vaults = 'vaults';
  static const appSettings = 'app_settings';
}

abstract final class HiveSettingsKeys {
  static const databaseVersion = 'databaseVersion';
  static const activeUserId = 'activeUserId';
  static const themePreference = 'themePreference';
  static const lastBackgroundedAt = 'lastBackgroundedAt';
  static const onboardingCompleted = 'onboardingCompleted';

  static String pinFailedAttempts(String userId) => 'pinFailedAttempts:$userId';

  static String pinLockoutStartedAt(String userId) =>
      'pinLockoutStartedAt:$userId';

  static String biometricFailedAttempts(String userId) =>
      'biometricFailedAttempts:$userId';

  static String biometricLockoutStartedAt(String userId) =>
      'biometricLockoutStartedAt:$userId';
}

abstract final class DatabaseConfig {
  static const currentVersion = 1;
}
