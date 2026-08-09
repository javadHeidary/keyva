import 'package:get/get.dart';
import 'package:keyva/feature/type/bank_card/data/bank_card_vault_store.dart';
import 'package:keyva/feature/type/bank_card/model/bank_card_item_model.dart';
import 'package:keyva/feature/type/bank_card/viewmodel/bank_card_form_viewmodel.dart';
import 'package:keyva/shared/widget/app_dialog_widget.dart';

class BankCardEditViewModel extends BankCardFormViewModel {
  BankCardEditViewModel({required this.cardId});

  final String cardId;

  BankCardVaultStore get _store => Get.find<BankCardVaultStore>();

  BankCardItem? _original;

  @override
  String get headerTitle => 'ویرایش کارت';

  @override
  String get submitLabel => 'ذخیره تغییرات';

  @override
  bool get showDeleteAction => true;

  @override
  void onInit() {
    super.onInit();
    _original = _store.findById(cardId);
    final item = _original;
    if (item == null) {
      Get.back();
      return;
    }
    initFormFields(
      categoryId: item.categoryId,
      title: item.title,
      cardNumberDigits: item.cardNumber,
      bankTitle: item.bankTitle,
      expiry: item.expiry,
      cvv: item.cvv,
      notes: item.notes,
    );
  }

  @override
  Future<void> submit() async {
    final original = _original;
    if (original == null || !validateForm()) return;

    isSubmitting.value = true;
    try {
      final notes = notesController.text.trim();
      final updated = original.copyWith(
        categoryId: selectedCategoryId.value,
        clearCategoryId: selectedCategoryId.value == null,
        title: titleController.text.trim(),
        cardNumber: collectCardDigits(),
        bankTitle: collectBankTitle(),
        expiry: expiryController.text.trim(),
        cvv: cvvController.text,
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
          'این کارت به سطل زباله منتقل می‌شود و می‌توانید بعداً آن را بازگردانی کنید.',
      buttonText: 'انتقال به سطل زباله',
      onConfirm: () {
        _store.moveToTrash(cardId);
        Get.back();
        Get.back();
      },
    );
  }
}
