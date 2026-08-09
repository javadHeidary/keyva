import 'package:get/get.dart';
import 'package:keyva/core/routes/app_routing.dart';
import 'package:keyva/feature/type/note/data/note_vault_store.dart';
import 'package:keyva/feature/type/note/model/note_item_model.dart';
import 'package:keyva/feature/type/note/viewmodel/note_form_viewmodel.dart';

class NoteCreateViewModel extends NoteFormViewModel {
  NoteVaultStore get _store => Get.find<NoteVaultStore>();

  @override
  String get headerTitle => 'ایجاد یادداشت';

  @override
  String get submitLabel => 'ایجاد یادداشت';

  @override
  void onInit() {
    super.onInit();
    initFormFields();
  }

  @override
  Future<void> submit() async {
    if (!validateForm()) return;

    isSubmitting.value = true;
    try {
      final item = NoteItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        categoryId: selectedCategoryId.value,
        title: titleController.text.trim(),
        body: notesController.text.trim(),
        createdAt: DateTime.now(),
      );

      _store.add(item);
      Get.offNamed(AppRoutes.noteDetails, arguments: item.id);
    } finally {
      isSubmitting.value = false;
    }
  }

  @override
  void handleDelete() {}
}
