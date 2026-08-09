import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keyva/feature/type/login/data/login_vault_store.dart';
import 'package:keyva/feature/type/login/model/login_item_model.dart';
import 'package:keyva/feature/type/login/viewmodel/login_form_viewmodel.dart';
import 'package:keyva/shared/widget/app_dialog_widget.dart';

class LoginEditViewModel extends LoginFormViewModel {
  LoginEditViewModel({required this.loginId});

  final String loginId;

  LoginVaultStore get _store => Get.find<LoginVaultStore>();

  LoginItem? _original;

  @override
  String get headerTitle => 'ویرایش ورود';

  @override
  String get submitLabel => 'ذخیره تغییرات';

  @override
  bool get showDeleteAction => true;

  @override
  void onInit() {
    super.onInit();
    _original = _store.findById(loginId);
    final item = _original;
    if (item == null) {
      Get.back();
      return;
    }
    initFormFields(
      categoryId: item.categoryId,
      title: item.title,
      username: item.username,
      password: item.password,
      websites: item.websites,
      notes: item.notes,
    );
  }

  @override
  Future<void> submit() async {
    final original = _original;
    if (original == null || !validateForm()) return;

    isSubmitting.value = true;
    try {
      final websites = collectNormalizedWebsites();
      final notes = notesController.text.trim();

      final updated = original.copyWith(
        categoryId: selectedCategoryId.value,
        clearCategoryId: selectedCategoryId.value == null,
        title: titleController.text.trim(),
        username: usernameController.text.trim(),
        password: passwordController.text,
        websites: websites,
        clearWebsites: websites.isEmpty,
        notes: notes.isEmpty ? null : notes,
        clearNotes: notes.isEmpty,
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
          'این ورود به سطل زباله منتقل می‌شود و می‌توانید بعداً آن را بازگردانی کنید.',
      buttonText: 'انتقال به سطل زباله',
      onConfirm: () {
        _store.moveToTrash(loginId);
        Get.back();
        Get.back();
      },
    );
  }

  void confirmDeleteFromHeader(BuildContext context) => handleDelete();
}
