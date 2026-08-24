import 'package:keyva/feature/home/model/vault_models.dart';
import 'package:keyva/feature/type/login/viewmodel/login_form_viewmodel.dart';
import 'package:keyva/feature/vault/model/login_item.dart';
import 'package:keyva/feature/vault/view/vault_form_submit.dart';
import 'package:keyva/feature/vault/view/vault_item_navigation.dart';
import 'package:keyva/feature/vault/viewmodel/vault_item_viewmodel.dart';

class LoginCreateViewModel extends LoginFormViewModel {
  LoginCreateViewModel({required VaultItemViewModel items}) : _items = items;

  final VaultItemViewModel _items;

  @override
  String get headerTitle => 'ایجاد اکانت';

  @override
  String get submitLabel => 'ایجاد اکانت';

  @override
  void onInit() {
    super.onInit();
    initFormFields(categoryId: vaultRouteCategoryId());
  }

  @override
  Future<void> submit() async {
    if (!validateForm()) return;

    final now = DateTime.now();
    final websites = collectNormalizedWebsites();
    final notes = notesController.text.trim();

    final item = LoginItem(
      id: now.millisecondsSinceEpoch.toString(),
      title: titleController.text.trim(),
      username: usernameController.text.trim(),
      password: passwordController.text,
      website: websites.isEmpty ? null : websites.first,
      notes: notes.isEmpty ? null : notes,
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
        type: VaultItemType.login,
        id: item.id,
      ),
    );
  }

  @override
  void handleDelete() {}
}
