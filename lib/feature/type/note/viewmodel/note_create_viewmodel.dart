import 'package:keyva/feature/home/model/vault_models.dart';
import 'package:keyva/feature/type/note/viewmodel/note_form_viewmodel.dart';
import 'package:keyva/feature/vault/model/secure_note_item.dart';
import 'package:keyva/feature/vault/view/vault_form_submit.dart';
import 'package:keyva/feature/vault/view/vault_item_navigation.dart';
import 'package:keyva/feature/vault/viewmodel/vault_item_viewmodel.dart';

class NoteCreateViewModel extends NoteFormViewModel {
  NoteCreateViewModel({required VaultItemViewModel items}) : _items = items;

  final VaultItemViewModel _items;

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

    final now = DateTime.now();
    final item = SecureNoteItem(
      id: now.millisecondsSinceEpoch.toString(),
      title: titleController.text.trim(),
      content: notesController.text.trim(),
      categoryId: selectedCategoryId.value,
      createdAt: now,
      updatedAt: now,
    );

    await submitVaultItem(
      items: _items,
      isSubmitting: isSubmitting,
      submitError: submitError,
      run: () => _items.create(item),
      onSuccess: () => openCreatedVaultItem(
        type: VaultItemType.secureNote,
        id: item.id,
      ),
    );
  }

  @override
  void handleDelete() {}
}
