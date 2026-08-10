import 'package:get/get.dart';
import 'package:keyva/feature/category/controller/category_catalog_controller.dart';
import 'package:keyva/feature/category/viewmodel/category_form_viewmodel.dart';
import 'package:keyva/feature/category/viewmodel/category_list_viewmodel.dart';

class CategoryBindings extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<CategoryCatalogController>()) {
      Get.put(CategoryCatalogController(), permanent: true);
    }
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
    Get.lazyPut(
      () => CategoryFormViewModel(mode: CategoryFormMode.create),
    );
  }
}

class CategoryEditBindings extends Bindings {
  @override
  void dependencies() {
    CategoryBindings().dependencies();
    final id = Get.arguments;
    Get.lazyPut(
      () => CategoryFormViewModel(
        mode: CategoryFormMode.edit,
        categoryId: id is String ? id : null,
      ),
    );
  }
}
