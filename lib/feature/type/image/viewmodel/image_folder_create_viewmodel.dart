import 'package:keyva/feature/home/model/vault_models.dart';
import 'package:keyva/feature/type/image/viewmodel/image_folder_form_viewmodel.dart';
import 'package:keyva/feature/vault/model/image_folder.dart';
import 'package:keyva/feature/vault/view/vault_form_submit.dart';
import 'package:keyva/feature/vault/view/vault_item_navigation.dart';
import 'package:keyva/feature/vault/viewmodel/vault_item_viewmodel.dart';

class ImageFolderCreateViewModel extends ImageFolderFormViewModel {
  ImageFolderCreateViewModel({required VaultItemViewModel items})
    : _items = items;

  final VaultItemViewModel _items;

  @override
  String get headerTitle => 'ایجاد پوشه تصاویر';

  @override
  String get submitLabel => 'ایجاد پوشه';

  @override
  void onInit() {
    super.onInit();
    initFormFields(categoryId: vaultRouteCategoryId());
  }

  @override
  Future<void> submit() async {
    if (!validateForm()) return;

    final now = DateTime.now();
    final item = ImageFolder(
      id: now.millisecondsSinceEpoch.toString(),
      title: titleController.text.trim(),
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
        type: VaultItemType.image,
        id: item.id,
      ),
    );
  }

  @override
  void handleDelete() {}
}
