class CategoryModel {
  const CategoryModel({
    required this.id,
    required this.name,
    this.iconId = CategoryIconPresets.defaultId,
  });

  final String id;
  final String name;
  final String iconId;

  CategoryModel copyWith({String? id, String? name, String? iconId}) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      iconId: iconId ?? this.iconId,
    );
  }
}

class CategoryIconPresets {
  CategoryIconPresets._();

  static const defaultId = 'folder';

  static const ids = [
    'folder',
    'work',
    'person',
    'finance',
    'business',
    'lock',
    'star',
  ];
}
