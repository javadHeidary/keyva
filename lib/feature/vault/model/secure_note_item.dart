class SecureNoteItem {
  const SecureNoteItem({
    required this.id,
    required this.title,
    required this.content,
    required this.categoryId,
    required this.createdAt,
    required this.updatedAt,
    this.isPinned = false,
  });

  final String id;
  final String title;
  final String content;
  final String? categoryId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPinned;

  SecureNoteItem copyWith({
    String? id,
    String? title,
    String? content,
    String? categoryId,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isPinned,
  }) {
    return SecureNoteItem(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      categoryId: categoryId ?? this.categoryId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPinned: isPinned ?? this.isPinned,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is SecureNoteItem &&
        id == other.id &&
        title == other.title &&
        content == other.content &&
        categoryId == other.categoryId &&
        createdAt == other.createdAt &&
        updatedAt == other.updatedAt &&
        isPinned == other.isPinned;
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    content,
    categoryId,
    createdAt,
    updatedAt,
    isPinned,
  );
}
