class NoteItem {
  const NoteItem({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    this.categoryId,
  });

  final String id;
  final String? categoryId;
  final String title;
  final String body;
  final DateTime createdAt;

  NoteItem copyWith({
    String? id,
    String? categoryId,
    bool clearCategoryId = false,
    String? title,
    String? body,
    DateTime? createdAt,
  }) {
    return NoteItem(
      id: id ?? this.id,
      categoryId: clearCategoryId ? null : (categoryId ?? this.categoryId),
      title: title ?? this.title,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
