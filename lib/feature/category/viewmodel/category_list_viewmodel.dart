import 'package:get/get.dart';
import 'package:keyva/core/routes/app_routing.dart';
import 'package:keyva/feature/category/controller/category_catalog_controller.dart';
import 'package:keyva/feature/vault/viewmodel/vault_home_viewmodel.dart';

class CategoryListViewModel extends GetxController {
  CategoryCatalogController get catalog =>
      Get.find<CategoryCatalogController>();

  int itemCountFor(String id) => catalog.itemCountFor(id);

  void openCreate() => Get.toNamed(AppRoutes.categoryCreate);

  void openEdit(String id) => Get.toNamed(AppRoutes.categoryEdit, arguments: id);

  Future<void> deleteCategory(String id) async {
    if (!Get.isRegistered<VaultHomeViewModel>()) {
      return;
    }
    await Get.find<VaultHomeViewModel>().deleteItem(id);
  }
}
