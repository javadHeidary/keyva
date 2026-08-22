class AccountSummary {
  const AccountSummary({
    required this.id,
    required this.username,
  });

  final String id;
  final String username;

  String get initial {
    final trimmed = username.trim();
    if (trimmed.isEmpty) {
      return '?';
    }
    return String.fromCharCodes(trimmed.runes.take(1));
  }
}
