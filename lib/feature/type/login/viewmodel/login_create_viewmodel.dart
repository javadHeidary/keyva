import 'package:get/get.dart';
import 'package:keyva/core/routes/app_routing.dart';
import 'package:keyva/feature/type/login/data/login_vault_store.dart';
import 'package:keyva/feature/type/login/model/login_item_model.dart';
import 'package:keyva/feature/type/login/viewmodel/login_form_viewmodel.dart';

class LoginCreateViewModel extends LoginFormViewModel {
  LoginVaultStore get _store => Get.find<LoginVaultStore>();

  @override
  String get headerTitle => 'ایجاد ورود';

  @override
  String get submitLabel => 'ایجاد ورود';

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
      final websites = collectNormalizedWebsites();
      final notes = notesController.text.trim();

      final item = LoginItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        categoryId: selectedCategoryId.value,
        title: titleController.text.trim(),
        username: usernameController.text.trim(),
        password: passwordController.text,
        websites: websites,
        notes: notes.isEmpty ? null : notes,
        createdAt: DateTime.now(),
      );

      _store.add(item);
      Get.offNamed(AppRoutes.loginDetails, arguments: item.id);
    } finally {
      isSubmitting.value = false;
    }
  }

  @override
  void handleDelete() {}
}
