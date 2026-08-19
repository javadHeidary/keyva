abstract final class FastUnlockStorageKeys {
  static String pinMaterial(String userId) => 'pin.material.$userId';

  static String biometricMaterial(String userId) => 'bio.material.$userId';
}
