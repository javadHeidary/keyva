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
