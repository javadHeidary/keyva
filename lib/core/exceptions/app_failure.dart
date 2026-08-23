sealed class AppFailure {
  const AppFailure({required this.message});

  final String message;
}

final class DatabaseFailure extends AppFailure {
  const DatabaseFailure({
    super.message = 'Database operation failed',
  });
}

final class CryptoFailure extends AppFailure {
  const CryptoFailure({
    super.message = 'Cryptographic operation failed',
  });
}

final class VaultDecryptionFailure extends AppFailure {
  const VaultDecryptionFailure({
    super.message = 'Unable to decrypt vault data',
  });
}

final class AuthenticationFailure extends AppFailure {
  const AuthenticationFailure({
    super.message = 'Unable to unlock your vault.',
  });
}

final class BiometricCancelledFailure extends AppFailure {
  const BiometricCancelledFailure({
    super.message = 'Biometric authentication cancelled',
  });
}

final class BiometricUnavailableFailure extends AppFailure {
  const BiometricUnavailableFailure({
    super.message = 'Biometric authentication is unavailable.',
  });
}

final class BiometricAuthFailedFailure extends AppFailure {
  const BiometricAuthFailedFailure({
    super.message = 'Biometric authentication failed.',
  });
}

final class BiometricNotConfiguredFailure extends AppFailure {
  const BiometricNotConfiguredFailure({
    super.message = 'Biometric unlock is not set up for this account.',
  });
}

final class BiometricLockedOutFailure extends AppFailure {
  const BiometricLockedOutFailure({
    super.message = 'Biometric unlock is locked. Use your master password.',
  });
}

final class ValidationFailure extends AppFailure {
  const ValidationFailure({
    super.message = 'Vault data is invalid',
  });
}

final class UnknownFailure extends AppFailure {
  const UnknownFailure({
    super.message = 'An unexpected error occurred',
  });
}

final class InvalidBackupFormatFailure extends AppFailure {
  const InvalidBackupFormatFailure({
    super.message = 'Backup file format is invalid',
  });
}

final class UnsupportedBackupVersionFailure extends AppFailure {
  const UnsupportedBackupVersionFailure({
    super.message = 'Backup version is not supported',
  });
}

final class WrongBackupPasswordFailure extends AppFailure {
  const WrongBackupPasswordFailure({
    super.message = 'Backup password is incorrect',
  });
}

final class BackupIntegrityFailure extends AppFailure {
  const BackupIntegrityFailure({
    super.message = 'Backup file is invalid or corrupted',
  });
}

final class BackupPayloadValidationFailure extends AppFailure {
  const BackupPayloadValidationFailure({
    super.message = 'Backup file is invalid or corrupted',
  });
}

final class BackupExportFailure extends AppFailure {
  const BackupExportFailure({
    super.message = 'Unable to save backup file',
  });
}

final class BackupRestorePersistenceFailure extends AppFailure {
  const BackupRestorePersistenceFailure({
    super.message = 'Unable to restore vault data',
  });
}

final class ScreenProtectionFailure extends AppFailure {
  const ScreenProtectionFailure({
    super.message = 'Unable to update screen capture protection',
  });
}
