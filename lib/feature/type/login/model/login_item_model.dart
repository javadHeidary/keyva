class LoginItem {
  const LoginItem({
    required this.id,
    required this.title,
    required this.username,
    required this.password,
    required this.createdAt,
    this.categoryId,
    this.websites = const [],
    this.notes,
  });

  final String id;
  final String? categoryId;
  final String title;
  final String username;
  final String password;
  final List<String> websites;
  final String? notes;
  final DateTime createdAt;

  String? get primaryWebsite =>
      websites.isNotEmpty ? websites.first : null;

  LoginItem copyWith({
    String? id,
    String? categoryId,
    bool clearCategoryId = false,
    String? title,
    String? username,
    String? password,
    List<String>? websites,
    bool clearWebsites = false,
    String? notes,
    bool clearNotes = false,
    DateTime? createdAt,
  }) {
    return LoginItem(
      id: id ?? this.id,
      categoryId: clearCategoryId ? null : (categoryId ?? this.categoryId),
      title: title ?? this.title,
      username: username ?? this.username,
      password: password ?? this.password,
      websites: clearWebsites ? const [] : (websites ?? this.websites),
      notes: clearNotes ? null : (notes ?? this.notes),
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
