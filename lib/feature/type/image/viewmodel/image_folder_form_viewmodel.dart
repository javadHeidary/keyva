import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keyva/feature/category/controller/category_catalog_controller.dart';
import 'package:keyva/feature/category/viewmodel/category_inline_create_mixin.dart';
import 'package:keyva/feature/home/model/vault_models.dart';
import 'package:keyva/feature/type/note/util/note_util.dart';

abstract class ImageFolderFormViewModel extends GetxController
    with CategoryInlineCreateMixin {
  final formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();

  @override
  final selectedCategoryId = Rxn<String>();
  final isSubmitting = false.obs;
  final submitError = Rxn<String>();

  String get headerTitle;
  String get submitLabel;
  bool get showDeleteAction => false;

  List<VaultCategory> get selectableCategories {
    if (!Get.isRegistered<CategoryCatalogController>()) return const [];
    return Get.find<CategoryCatalogController>().vaultCategories;
  }

  void initFormFields({String? categoryId, String? title}) {
    selectedCategoryId.value = categoryId;
    titleController.text = title ?? '';
  }

  void onCategoryChanged(String? categoryId) {
    selectedCategoryId.value = categoryId;
  }

  String? validateTitle(String? value) => validateNoteTitleInput(value);

  bool validateForm() => formKey.currentState?.validate() ?? false;

  Future<void> submit();

  void handleDelete();

  @override
  void onClose() {
    titleController.dispose();
    super.onClose();
  }
}
