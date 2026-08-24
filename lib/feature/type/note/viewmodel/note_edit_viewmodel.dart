import 'package:get/get.dart';
import 'package:keyva/feature/home/viewmodel/home_viewmodel.dart';
import 'package:keyva/feature/type/note/viewmodel/note_form_viewmodel.dart';
import 'package:keyva/feature/vault/model/secure_note_item.dart';
import 'package:keyva/feature/vault/view/vault_form_submit.dart';
import 'package:keyva/feature/vault/view/vault_list_item_mapper.dart';
import 'package:keyva/feature/vault/viewmodel/vault_home_viewmodel.dart';
import 'package:keyva/feature/vault/viewmodel/vault_item_viewmodel.dart';
import 'package:keyva/shared/widget/app_dialog_widget.dart';

class NoteEditViewModel extends NoteFormViewModel {
  NoteEditViewModel({
    required this.noteId,
    required VaultItemViewModel items,
  }) : _items = items;

  final String noteId;
  final VaultItemViewModel _items;

  SecureNoteItem? _original;

  @override
  String get headerTitle => 'ویرایش یادداشت';

  @override
  String get submitLabel => 'ذخیره تغییرات';

  @override
  bool get showDeleteAction => true;

  @override
  void onInit() {
    super.onInit();
    final found = findVaultItemById(
      Get.isRegistered<VaultHomeViewModel>()
          ? Get.find<VaultHomeViewModel>().vault.value
          : null,
      noteId,
    );
    if (found is! SecureNoteItem) {
      Get.back();
      return;
    }
    _original = found;
    initFormFields(
      categoryId: found.categoryId,
      title: found.title,
      body: found.content,
    );
  }

  @override
  Future<void> submit() async {
    final original = _original;
    if (original == null || !validateForm()) return;

    final updated = SecureNoteItem(
      id: original.id,
      title: titleController.text.trim(),
      content: notesController.text.trim(),
      categoryId: selectedCategoryId.value,
      createdAt: original.createdAt,
      updatedAt: DateTime.now(),
      isPinned: original.isPinned,
    );

    await submitVaultItem(
      items: _items,
      isSubmitting: isSubmitting,
      submitError: submitError,
      run: () => _items.updateItem(updated),
    );
  }

  @override
  void handleDelete() {
    final context = Get.context;
    final original = _original;
    if (context == null || original == null) return;
    if (!Get.isRegistered<HomeController>()) return;

    AppDialogWidget.show(
      context,
      type: AppDialogType.warning,
      title: 'حذف آیتم',
      description:
          '«${original.title}» برای همیشه حذف می‌شود. این کار قابل بازگشت نیست.',
      buttonText: 'حذف',
      onConfirm: () {
        Get.find<HomeController>().vault.deleteItem(original.id);
        Get.back();
      },
    );
  }
}
