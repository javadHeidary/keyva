import 'package:get/get.dart';
import 'package:keyva/feature/category/model/category_constants.dart';
import 'package:keyva/feature/category/model/category_model.dart';
import 'package:keyva/feature/category/model/category_repository.dart';
import 'package:keyva/feature/home/model/vault_models.dart';
import 'package:keyva/feature/home/viewmodel/home_viewmodel.dart';
import 'package:keyva/feature/type/bank_card/data/bank_card_vault_store.dart';
import 'package:keyva/feature/type/login/data/login_vault_store.dart';
import 'package:keyva/feature/type/note/data/note_vault_store.dart';

class CategoryCatalogController extends GetxService {
  CategoryCatalogController({CategoryRepository? repository})
    : _repository = repository;

  final CategoryRepository? _repository;

  CategoryRepository? get repository => _repository;

  final RxList<CategoryModel> categories = <CategoryModel>[
    const CategoryModel(id: 'work', name: 'کاری', iconId: 'work'),
    const CategoryModel(id: 'personal', name: 'شخصی', iconId: 'person'),
    const CategoryModel(id: 'finance', name: 'مالی', iconId: 'finance'),
    const CategoryModel(id: 'network', name: 'شرکت', iconId: 'business'),
  ].obs;

  List<CategoryModel> get userCategories => categories.toList();

  List<VaultCategory> get vaultCategories => categories
      .map(
        (c) => VaultCategory(id: c.id, name: c.name, iconId: c.iconId),
      )
      .toList();

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

  void createCategory({required String name, required String iconId}) {
    final id = 'cat_${DateTime.now().microsecondsSinceEpoch}';
    categories.add(CategoryModel(id: id, name: name.trim(), iconId: iconId));
    // TODO: delegate to _repository
  }

  void updateCategory(CategoryModel updated) {
    final index = categories.indexWhere((c) => c.id == updated.id);
    if (index == -1) return;
    categories[index] = updated;
    // TODO: delegate to _repository
  }

  void deleteCategory(String id) {
    categories.removeWhere((c) => c.id == id);
    _clearCategoryOnVaultItems(id);
    // TODO: delegate to _repository
  }

  void _clearCategoryOnVaultItems(String categoryId) {
    if (Get.isRegistered<LoginVaultStore>()) {
      Get.find<LoginVaultStore>().clearCategoryId(categoryId);
    }
    if (Get.isRegistered<BankCardVaultStore>()) {
      Get.find<BankCardVaultStore>().clearCategoryId(categoryId);
    }
    if (Get.isRegistered<NoteVaultStore>()) {
      Get.find<NoteVaultStore>().clearCategoryId(categoryId);
    }
  }
}
