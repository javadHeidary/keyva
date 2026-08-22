import 'package:get/get.dart';
import 'package:keyva/feature/category/model/category_constants.dart';
import 'package:keyva/feature/category/model/category_model.dart';
import 'package:keyva/feature/category/util/category_vault_mapper.dart';
import 'package:keyva/feature/home/model/vault_models.dart';
import 'package:keyva/feature/home/viewmodel/home_viewmodel.dart';
import 'package:keyva/feature/vault/model/category_item.dart';

class CategoryCatalogController extends GetxService {
  final RxList<CategoryModel> categories = <CategoryModel>[].obs;

  List<CategoryModel> get userCategories => categories.toList();

  List<VaultCategory> get vaultCategories => [
    for (final category in categories)
      VaultCategory(id: category.id, name: category.name, iconId: category.iconId),
  ];

  void replaceFromVault(Iterable<CategoryItem> items) {
    categories.assignAll([
      for (final item in items) categoryModelFromVaultItem(item),
    ]);
  }

  CategoryModel? findById(String? id) {
    if (id == null || id.isEmpty) return null;
    for (final category in categories) {
      if (category.id == id) return category;
    }
    return null;
  }

  String labelForCategoryId(String? categoryId) {
    if (categoryId == null || categoryId.isEmpty) {
      return CategoryConstants.withoutCategoryLabel;
    }
    return findById(categoryId)?.name ?? CategoryConstants.withoutCategoryLabel;
  }

  int itemCountFor(String categoryId) {
    if (!Get.isRegistered<HomeController>()) return 0;
    final items = Get.find<HomeController>().vaultItems;
    return items.where((item) => item.categoryId == categoryId).length;
  }
}
