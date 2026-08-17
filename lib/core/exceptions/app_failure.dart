sealed class AppFailure {
  const AppFailure({required this.message});

  final String message;
}

final class DatabaseFailure extends AppFailure {
  const DatabaseFailure({
    super.message = 'Database operation failed',
  });
}

final class UnknownFailure extends AppFailure {
  const UnknownFailure({
    super.message = 'An unexpected error occurred',
  });
}
