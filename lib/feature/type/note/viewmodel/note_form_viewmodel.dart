import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keyva/feature/category/controller/category_catalog_controller.dart';
import 'package:keyva/feature/home/model/vault_models.dart';
import 'package:keyva/feature/type/note/util/note_util.dart';

abstract class NoteFormViewModel extends GetxController {
  final formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final notesController = TextEditingController();

  final selectedCategoryId = Rxn<String>();
  final isSubmitting = false.obs;

  String get headerTitle;
  String get submitLabel;
  bool get showDeleteAction => false;

  List<VaultCategory> get selectableCategories {
    if (!Get.isRegistered<CategoryCatalogController>()) return const [];
    return Get.find<CategoryCatalogController>().vaultCategories;
  }

  void initFormFields({
    String? categoryId,
    String? title,
    String? body,
  }) {
    selectedCategoryId.value = categoryId;
    titleController.text = title ?? '';
    notesController.text = body ?? '';
  }

  void onCategoryChanged(String? categoryId) {
    selectedCategoryId.value = categoryId;
  }

  String? validateTitle(String? value) => validateNoteTitleInput(value);

  String? validateNotes(String? value) => validateNoteBodyInput(value);

  bool validateForm() => formKey.currentState?.validate() ?? false;

  Future<void> submit();

  void handleDelete();

  @override
  void onClose() {
    titleController.dispose();
    notesController.dispose();
    super.onClose();
  }
}
