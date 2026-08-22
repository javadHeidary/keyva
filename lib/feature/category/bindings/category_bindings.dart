import 'package:get/get.dart';
import 'package:keyva/core/di/injection_container.dart';
import 'package:keyva/feature/category/controller/category_catalog_controller.dart';
import 'package:keyva/feature/category/viewmodel/category_form_viewmodel.dart';
import 'package:keyva/feature/category/viewmodel/category_list_viewmodel.dart';
import 'package:keyva/feature/vault/viewmodel/vault_item_viewmodel.dart';

class CategoryBindings extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<CategoryCatalogController>()) {
      Get.put(CategoryCatalogController(), permanent: true);
    }
  }

  static VaultItemViewModel itemViewModel() {
    if (!Get.isRegistered<VaultItemViewModel>()) {
      Get.lazyPut(() => getIt<VaultItemViewModel>());
    }
    return Get.find<VaultItemViewModel>();
  }
}

class CategoryListBindings extends Bindings {
  @override
  void dependencies() {
    CategoryBindings().dependencies();
    Get.lazyPut(() => CategoryListViewModel());
  }
}

class CategoryCreateBindings extends Bindings {
  @override
  void dependencies() {
    CategoryBindings().dependencies();
    final items = CategoryBindings.itemViewModel();
    Get.lazyPut(
      () => CategoryFormViewModel(mode: CategoryFormMode.create, items: items),
    );
  }
}

class CategoryEditBindings extends Bindings {
  @override
  void dependencies() {
    CategoryBindings().dependencies();
    final items = CategoryBindings.itemViewModel();
    final id = Get.arguments;
    Get.lazyPut(
      () => CategoryFormViewModel(
        mode: CategoryFormMode.edit,
        items: items,
        categoryId: id is String ? id : null,
      ),
    );
  }
}
