import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keyva/feature/category/controller/category_catalog_controller.dart';
import 'package:keyva/feature/category/model/category_model.dart';
import 'package:keyva/feature/category/util/category_name_validator.dart';
import 'package:keyva/feature/category/util/category_vault_mapper.dart';
import 'package:keyva/feature/vault/model/category_item.dart';
import 'package:keyva/feature/vault/view/vault_form_submit.dart';
import 'package:keyva/feature/vault/view/vault_list_item_mapper.dart';
import 'package:keyva/feature/vault/viewmodel/vault_home_viewmodel.dart';
import 'package:keyva/feature/vault/viewmodel/vault_item_viewmodel.dart';

enum CategoryFormMode { create, edit }

class CategoryFormViewModel extends GetxController {
  CategoryFormViewModel({
    required this.mode,
    required VaultItemViewModel items,
    this.categoryId,
  }) : _items = items;

  final CategoryFormMode mode;
  final String? categoryId;
  final VaultItemViewModel _items;

  final nameController = TextEditingController();
  final selectedIconId = CategoryIconPresets.defaultId.obs;
  final formKey = GlobalKey<FormState>();
  final isSubmitting = false.obs;
  final submitError = Rxn<String>();

  CategoryItem? _original;

  String get headerTitle => mode == CategoryFormMode.create
      ? 'ایجاد دسته‌بندی'
      : 'ویرایش دسته‌بندی';

  String get submitLabel =>
      mode == CategoryFormMode.create ? 'ایجاد دسته‌بندی' : 'ذخیره تغییرات';

  @override
  void onInit() {
    super.onInit();
    if (mode != CategoryFormMode.edit || categoryId == null) {
      return;
    }
    final found = findVaultItemById(
      Get.isRegistered<VaultHomeViewModel>()
          ? Get.find<VaultHomeViewModel>().vault.value
          : null,
      categoryId!,
    );
    if (found is! CategoryItem) {
      Get.back();
      return;
    }
    _original = found;
    nameController.text = found.name;
    selectedIconId.value = found.icon ?? CategoryIconPresets.defaultId;
  }

  String? validateName(String? value) {
    return CategoryNameValidator.validate(
      value,
      existingNames: _existingNames(),
      currentName: _original?.name,
    );
  }

  Iterable<String> _existingNames() {
    if (!Get.isRegistered<CategoryCatalogController>()) {
      return const <String>[];
    }
    return Get.find<CategoryCatalogController>().categories.map(
      (category) => category.name,
    );
  }

  void selectIcon(String iconId) {
    selectedIconId.value = iconId;
  }

  Future<void> submit() async {
    final name = nameController.text.trim();
    if (validateName(name) != null) {
      formKey.currentState?.validate();
      return;
    }
    if (formKey.currentState != null && !formKey.currentState!.validate()) {
      return;
    }

    final iconId = selectedIconId.value;
    if (mode == CategoryFormMode.create) {
      final now = DateTime.now();
      final item = CategoryItem(
        id: 'cat_${now.microsecondsSinceEpoch}',
        name: name,
        icon: iconId,
        createdAt: now,
      );
      await submitVaultItem(
        items: _items,
        isSubmitting: isSubmitting,
        submitError: submitError,
        run: () => _items.create(item),
      );
      return;
    }

    final original = _original;
    if (original == null || categoryId == null) {
      return;
    }
    final updated = categoryItemFromModel(
      CategoryModel(id: original.id, name: name, iconId: iconId),
      createdAt: original.createdAt,
    );
    await submitVaultItem(
      items: _items,
      isSubmitting: isSubmitting,
      submitError: submitError,
      run: () => _items.updateItem(updated),
    );
  }

  @override
  void onClose() {
    nameController.dispose();
    super.onClose();
  }
}
