import 'package:get/get.dart';
import 'package:keyva/core/routes/app_routing.dart';
import 'package:keyva/feature/type/bank_card/data/bank_card_vault_store.dart';
import 'package:keyva/feature/type/bank_card/model/bank_card_item_model.dart';
import 'package:keyva/feature/type/bank_card/viewmodel/bank_card_form_viewmodel.dart';

class BankCardCreateViewModel extends BankCardFormViewModel {
  BankCardVaultStore get _store => Get.find<BankCardVaultStore>();

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

    isSubmitting.value = true;
    try {
      final notes = notesController.text.trim();
      final item = BankCardItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        categoryId: selectedCategoryId.value,
        title: titleController.text.trim(),
        cardNumber: collectCardDigits(),
        bankTitle: collectBankTitle(),
        expiry: expiryController.text.trim(),
        cvv: cvvController.text,
        notes: notes.isEmpty ? null : notes,
        createdAt: DateTime.now(),
      );

      _store.add(item);
      Get.offNamed(AppRoutes.bankCardDetails, arguments: item.id);
    } finally {
      isSubmitting.value = false;
    }
  }

  @override
  void handleDelete() {}
}
