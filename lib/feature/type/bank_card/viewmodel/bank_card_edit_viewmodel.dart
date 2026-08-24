import 'package:get/get.dart';
import 'package:keyva/feature/home/viewmodel/home_viewmodel.dart';
import 'package:keyva/feature/type/bank_card/viewmodel/bank_card_form_viewmodel.dart';
import 'package:keyva/feature/vault/model/bank_card_item.dart';
import 'package:keyva/feature/vault/view/vault_form_submit.dart';
import 'package:keyva/feature/vault/view/vault_list_item_mapper.dart';
import 'package:keyva/feature/vault/viewmodel/vault_home_viewmodel.dart';
import 'package:keyva/feature/vault/viewmodel/vault_item_viewmodel.dart';
import 'package:keyva/shared/widget/app_dialog_widget.dart';

class BankCardEditViewModel extends BankCardFormViewModel {
  BankCardEditViewModel({
    required this.cardId,
    required VaultItemViewModel items,
  }) : _items = items;

  final String cardId;
  final VaultItemViewModel _items;

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
    final found = findVaultItemById(
      Get.isRegistered<VaultHomeViewModel>()
          ? Get.find<VaultHomeViewModel>().vault.value
          : null,
      cardId,
    );
    if (found is! BankCardItem) {
      Get.back();
      return;
    }
    _original = found;
    initFormFields(
      categoryId: found.categoryId,
      title: found.title,
      cardNumberDigits: found.cardNumber,
      cardHolder: found.cardHolder,
      bankTitle: found.bankName,
      expiry: found.expiryDate,
      cvv: found.cvv,
      notes: found.notes,
    );
  }

  @override
  Future<void> submit() async {
    final original = _original;
    if (original == null || !validateForm()) return;

    final notes = notesController.text.trim();
    final updated = BankCardItem(
      id: original.id,
      title: titleController.text.trim(),
      cardNumber: collectCardDigits(),
      cardHolder: cardHolderController.text.trim(),
      expiryDate: expiryController.text.trim(),
      cvv: cvvController.text,
      bankName: collectBankTitle(),
      notes: notes.isEmpty ? null : notes,
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
}
