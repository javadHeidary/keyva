class AuthenticatedSession {
  const AuthenticatedSession({
    required this.userId,
    required this.username,
  });

  final String userId;
  final String username;
}
