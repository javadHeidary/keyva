class PasswordHistoryEntry {
  const PasswordHistoryEntry({
    required this.password,
    required this.copiedAt,
  });

  final String password;
  final DateTime copiedAt;

  Map<String, dynamic> toJson() => {
        'password': password,
        'copiedAt': copiedAt.toIso8601String(),
      };

  factory PasswordHistoryEntry.fromJson(Map<String, dynamic> json) {
    return PasswordHistoryEntry(
      password: json['password'] as String? ?? '',
      copiedAt: DateTime.tryParse(json['copiedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
