import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keyva/feature/home/viewmodel/home_viewmodel.dart';
import 'package:keyva/feature/type/login/viewmodel/login_form_viewmodel.dart';
import 'package:keyva/feature/vault/model/login_item.dart';
import 'package:keyva/feature/vault/view/vault_form_submit.dart';
import 'package:keyva/feature/vault/view/vault_list_item_mapper.dart';
import 'package:keyva/feature/vault/viewmodel/vault_home_viewmodel.dart';
import 'package:keyva/feature/vault/viewmodel/vault_item_viewmodel.dart';
import 'package:keyva/shared/widget/app_dialog_widget.dart';

class LoginEditViewModel extends LoginFormViewModel {
  LoginEditViewModel({
    required this.loginId,
    required VaultItemViewModel items,
  }) : _items = items;

  final String loginId;
  final VaultItemViewModel _items;

  LoginItem? _original;

  @override
  String get headerTitle => 'ویرایش اکانت';

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
      loginId,
    );
    if (found is! LoginItem) {
      Get.back();
      return;
    }
    _original = found;
    initFormFields(
      categoryId: found.categoryId,
      title: found.title,
      username: found.username,
      password: found.password,
      websites: found.website == null || found.website!.isEmpty
          ? const []
          : [found.website!],
      notes: found.notes,
    );
  }

  @override
  Future<void> submit() async {
    final original = _original;
    if (original == null || !validateForm()) return;

    final websites = collectNormalizedWebsites();
    final notes = notesController.text.trim();
    final now = DateTime.now();

    final updated = LoginItem(
      id: original.id,
      title: titleController.text.trim(),
      username: usernameController.text.trim(),
      password: passwordController.text,
      website: websites.isEmpty ? null : websites.first,
      notes: notes.isEmpty ? null : notes,
      categoryId: selectedCategoryId.value,
      createdAt: original.createdAt,
      updatedAt: now,
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

  void confirmDeleteFromHeader(BuildContext context) => handleDelete();
}
