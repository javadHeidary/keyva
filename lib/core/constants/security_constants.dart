abstract final class SecurityConstants {
  static const kdfAlgorithm = 'Argon2id';
  static const kdfMemoryCost = 65536;
  static const kdfTimeCost = 3;
  static const kdfParallelism = 4;
  static const kdfOutputLength = 32;
  static const saltLength = 16;
  static const vaultKeyLength = 32;
  static const nonceLength = 12;
  static const authenticationTagLength = 16;
  static const wrappedKeyVersion = 1;
  static const vaultEncryptionVersion = 1;
  static const pinMinLength = 4;
  static const pinMaxLength = 6;
  static const pinMaxFailedAttempts = 5;
  static const masterPasswordMinLength = 8;
}
