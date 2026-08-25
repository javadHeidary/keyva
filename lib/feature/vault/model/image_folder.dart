class ImageFolder {
  const ImageFolder({
    required this.id,
    required this.title,
    required this.categoryId,
    required this.createdAt,
    required this.updatedAt,
    this.isPinned = false,
  });

  final String id;
  final String title;
  final String? categoryId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPinned;

  ImageFolder copyWith({
    String? id,
    String? title,
    String? categoryId,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isPinned,
  }) {
    return ImageFolder(
      id: id ?? this.id,
      title: title ?? this.title,
      categoryId: categoryId ?? this.categoryId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPinned: isPinned ?? this.isPinned,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ImageFolder &&
        id == other.id &&
        title == other.title &&
        categoryId == other.categoryId &&
        createdAt == other.createdAt &&
        updatedAt == other.updatedAt &&
        isPinned == other.isPinned;
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    categoryId,
    createdAt,
    updatedAt,
    isPinned,
  );
}
