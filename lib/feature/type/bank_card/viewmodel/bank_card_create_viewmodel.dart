import 'package:keyva/feature/type/bank_card/viewmodel/bank_card_form_viewmodel.dart';
import 'package:keyva/feature/vault/model/bank_card_item.dart';
import 'package:keyva/feature/vault/view/vault_form_submit.dart';
import 'package:keyva/feature/vault/viewmodel/vault_item_viewmodel.dart';

class BankCardCreateViewModel extends BankCardFormViewModel {
  BankCardCreateViewModel({required VaultItemViewModel items}) : _items = items;

  final VaultItemViewModel _items;

  @override
  String get headerTitle => 'ایجاد کارت';

  @override
  String get submitLabel => 'ایجاد کارت';

  @override
  void onInit() {
    super.onInit();
    initFormFields();
  }

  @override
  Future<void> submit() async {
    if (!validateForm()) return;

    final now = DateTime.now();
    final notes = notesController.text.trim();
    final item = BankCardItem(
      id: now.millisecondsSinceEpoch.toString(),
      title: titleController.text.trim(),
      cardNumber: collectCardDigits(),
      cardHolder: cardHolderController.text.trim(),
      expiryDate: expiryController.text.trim(),
      cvv: cvvController.text,
      bankName: collectBankTitle(),
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
    );
  }

  @override
  void handleDelete() {}
}
