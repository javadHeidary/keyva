class SecureNoteItem {
  const SecureNoteItem({
    required this.id,
    required this.title,
    required this.content,
    required this.categoryId,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String content;
  final String? categoryId;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  bool operator ==(Object other) {
    return other is SecureNoteItem &&
        id == other.id &&
        title == other.title &&
        content == other.content &&
        categoryId == other.categoryId &&
        createdAt == other.createdAt &&
        updatedAt == other.updatedAt;
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    content,
    categoryId,
    createdAt,
    updatedAt,
  );
}
