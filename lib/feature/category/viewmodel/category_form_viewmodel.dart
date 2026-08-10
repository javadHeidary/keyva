import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keyva/feature/category/controller/category_catalog_controller.dart';
import 'package:keyva/feature/category/model/category_model.dart';

enum CategoryFormMode { create, edit }

class CategoryFormViewModel extends GetxController {
  CategoryFormViewModel({required this.mode, this.categoryId});

  final CategoryFormMode mode;
  final String? categoryId;

  final nameController = TextEditingController();
  final selectedIconId = CategoryIconPresets.defaultId.obs;
  final formKey = GlobalKey<FormState>();

  CategoryCatalogController get _catalog =>
      Get.find<CategoryCatalogController>();

  String get headerTitle => mode == CategoryFormMode.create
      ? 'ایجاد دسته‌بندی'
      : 'ویرایش دسته‌بندی';

  String get submitLabel =>
      mode == CategoryFormMode.create ? 'ایجاد دسته‌بندی' : 'ذخیره تغییرات';

  @override
  void onInit() {
    super.onInit();
    if (mode == CategoryFormMode.edit && categoryId != null) {
      final category = _catalog.findById(categoryId);
      if (category != null) {
        nameController.text = category.name;
        selectedIconId.value = category.iconId;
      }
    }
  }

  String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'نام دسته‌بندی را وارد کنید';
    }
    return null;
  }

  void selectIcon(String iconId) {
    selectedIconId.value = iconId;
  }

  void submit() {
    if (!(formKey.currentState?.validate() ?? false)) return;
    final name = nameController.text.trim();
    final iconId = selectedIconId.value;

    if (mode == CategoryFormMode.create) {
      _catalog.createCategory(name: name, iconId: iconId);
    } else if (categoryId != null) {
      _catalog.updateCategory(
        CategoryModel(id: categoryId!, name: name, iconId: iconId),
      );
    }
    Get.back();
  }

  @override
  void onClose() {
    nameController.dispose();
    super.onClose();
  }
}
