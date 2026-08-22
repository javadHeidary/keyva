import 'package:keyva/feature/category/model/category_model.dart';
import 'package:keyva/feature/vault/model/category_item.dart';

CategoryModel categoryModelFromVaultItem(CategoryItem item) {
  return CategoryModel(
    id: item.id,
    name: item.name,
    iconId: item.icon ?? CategoryIconPresets.defaultId,
  );
}

CategoryItem categoryItemFromModel(
  CategoryModel model, {
  required DateTime createdAt,
}) {
  return CategoryItem(
    id: model.id,
    name: model.name,
    icon: model.iconId,
    createdAt: createdAt,
  );
}
