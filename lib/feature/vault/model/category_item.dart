class CategoryItem {
  const CategoryItem({
    required this.id,
    required this.name,
    required this.icon,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String? icon;
  final DateTime createdAt;

  @override
  bool operator ==(Object other) {
    return other is CategoryItem &&
        id == other.id &&
        name == other.name &&
        icon == other.icon &&
        createdAt == other.createdAt;
  }

  @override
  int get hashCode => Object.hash(id, name, icon, createdAt);
}
