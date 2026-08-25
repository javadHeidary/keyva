import 'package:get/get.dart';
import 'package:keyva/feature/home/viewmodel/home_viewmodel.dart';
import 'package:keyva/feature/type/image/viewmodel/image_folder_form_viewmodel.dart';
import 'package:keyva/feature/vault/model/image_folder.dart';
import 'package:keyva/feature/vault/view/vault_form_submit.dart';
import 'package:keyva/feature/vault/view/vault_list_item_mapper.dart';
import 'package:keyva/feature/vault/viewmodel/vault_home_viewmodel.dart';
import 'package:keyva/feature/vault/viewmodel/vault_item_viewmodel.dart';

class ImageFolderEditViewModel extends ImageFolderFormViewModel {
  ImageFolderEditViewModel({
    required this.folderId,
    required VaultItemViewModel items,
  }) : _items = items;

  final String folderId;
  final VaultItemViewModel _items;

  ImageFolder? _original;

  @override
  String get headerTitle => 'ویرایش پوشه';

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
      folderId,
    );
    if (found is! ImageFolder) {
      Get.back();
      return;
    }
    _original = found;
    initFormFields(categoryId: found.categoryId, title: found.title);
  }

  @override
  Future<void> submit() async {
    final original = _original;
    if (original == null || !validateForm()) return;

    final updated = ImageFolder(
      id: original.id,
      title: titleController.text.trim(),
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
    final listItem = mapVaultListItem(
      original,
      vault: Get.find<VaultHomeViewModel>().vault.value,
    );
    if (listItem == null) return;
    Get.find<HomeController>().confirmDelete(
      context,
      listItem,
      onDeleted: Get.back,
    );
  }
}
