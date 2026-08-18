class LoginItem {
  const LoginItem({
    required this.id,
    required this.title,
    required this.username,
    required this.password,
    required this.website,
    required this.notes,
    required this.categoryId,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String username;
  final String password;
  final String? website;
  final String? notes;
  final String? categoryId;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  bool operator ==(Object other) {
    return other is LoginItem &&
        id == other.id &&
        title == other.title &&
        username == other.username &&
        password == other.password &&
        website == other.website &&
        notes == other.notes &&
        categoryId == other.categoryId &&
        createdAt == other.createdAt &&
        updatedAt == other.updatedAt;
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    username,
    password,
    website,
    notes,
    categoryId,
    createdAt,
    updatedAt,
  );
}
