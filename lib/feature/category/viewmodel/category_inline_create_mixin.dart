import 'package:get/get.dart';
import 'package:keyva/feature/category/controller/category_catalog_controller.dart';
import 'package:keyva/feature/category/model/category_model.dart';
import 'package:keyva/feature/category/util/category_name_validator.dart';
import 'package:keyva/feature/vault/model/category_item.dart';
import 'package:keyva/feature/vault/view/vault_form_submit.dart';
import 'package:keyva/feature/vault/viewmodel/vault_item_viewmodel.dart';

mixin CategoryInlineCreateMixin on GetxController {
  Rxn<String> get selectedCategoryId;

  Iterable<String> get existingCategoryNames {
    if (!Get.isRegistered<CategoryCatalogController>()) {
      return const <String>[];
    }
    return Get.find<CategoryCatalogController>().categories.map(
      (category) => category.name,
    );
  }

  Future<String?> createInlineCategory(String rawName) async {
    final error = CategoryNameValidator.validate(
      rawName,
      existingNames: existingCategoryNames,
    );
    if (error != null) {
      return error;
    }
    if (!Get.isRegistered<VaultItemViewModel>()) {
      return 'ذخیره‌سازی انجام نشد.';
    }

    final items = Get.find<VaultItemViewModel>();
    final now = DateTime.now();
    final item = CategoryItem(
      id: 'cat_${now.microsecondsSinceEpoch}',
      name: rawName.trim(),
      icon: CategoryIconPresets.defaultId,
      createdAt: now,
    );
    final isSubmitting = false.obs;
    final submitError = Rxn<String>();
    await submitVaultItem(
      items: items,
      isSubmitting: isSubmitting,
      submitError: submitError,
      run: () => items.create(item),
      onSuccess: () {
        selectedCategoryId.value = item.id;
      },
    );
    return submitError.value;
  }
}
