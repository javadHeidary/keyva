import 'package:get/get.dart';
import 'package:keyva/feature/type/note/data/note_vault_store.dart';
import 'package:keyva/feature/type/note/model/note_item_model.dart';
import 'package:keyva/feature/type/note/viewmodel/note_form_viewmodel.dart';
import 'package:keyva/shared/widget/app_dialog_widget.dart';

class NoteEditViewModel extends NoteFormViewModel {
  NoteEditViewModel({required this.noteId});

  final String noteId;

  NoteVaultStore get _store => Get.find<NoteVaultStore>();

  NoteItem? _original;

  @override
  String get headerTitle => 'ویرایش یادداشت';

  @override
  String get submitLabel => 'ذخیره تغییرات';

  @override
  bool get showDeleteAction => true;

  @override
  void onInit() {
    super.onInit();
    _original = _store.findById(noteId);
    final item = _original;
    if (item == null) {
      Get.back();
      return;
    }
    initFormFields(
      categoryId: item.categoryId,
      title: item.title,
      body: item.body,
    );
  }

  @override
  Future<void> submit() async {
    final original = _original;
    if (original == null || !validateForm()) return;

    isSubmitting.value = true;
    try {
      final updated = original.copyWith(
        categoryId: selectedCategoryId.value,
        clearCategoryId: selectedCategoryId.value == null,
        title: titleController.text.trim(),
        body: notesController.text.trim(),
      );

      _store.update(updated);
      Get.back(result: true);
    } finally {
      isSubmitting.value = false;
    }
  }

  @override
  void handleDelete() {
    final context = Get.context;
    if (context == null) return;

    AppDialogWidget.show(
      context,
      type: AppDialogType.warning,
      title: 'انتقال به سطل زباله',
      description:
          'این یادداشت به سطل زباله منتقل می‌شود و می‌توانید بعداً آن را بازگردانی کنید.',
      buttonText: 'انتقال به سطل زباله',
      onConfirm: () {
        _store.moveToTrash(noteId);
        Get.back();
        Get.back();
      },
    );
  }
}
