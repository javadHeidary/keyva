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
    this.isPinned = false,
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
  final bool isPinned;

  LoginItem copyWith({
    String? id,
    String? title,
    String? username,
    String? password,
    String? website,
    String? notes,
    String? categoryId,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isPinned,
  }) {
    return LoginItem(
      id: id ?? this.id,
      title: title ?? this.title,
      username: username ?? this.username,
      password: password ?? this.password,
      website: website ?? this.website,
      notes: notes ?? this.notes,
      categoryId: categoryId ?? this.categoryId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPinned: isPinned ?? this.isPinned,
    );
  }

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
        updatedAt == other.updatedAt &&
        isPinned == other.isPinned;
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
    isPinned,
  );
}
