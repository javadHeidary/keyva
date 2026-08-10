import 'package:get/get.dart';
import 'package:keyva/feature/category/controller/category_catalog_controller.dart';
import 'package:keyva/core/routes/app_routing.dart';

class CategoryListViewModel extends GetxController {
  CategoryCatalogController get catalog =>
      Get.find<CategoryCatalogController>();

  int itemCountFor(String id) => catalog.itemCountFor(id);

  void openCreate() => Get.toNamed(AppRoutes.categoryCreate);

  void openEdit(String id) => Get.toNamed(AppRoutes.categoryEdit, arguments: id);

  void deleteCategory(String id) => catalog.deleteCategory(id);
}
