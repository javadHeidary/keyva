import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iranian_banks/iranian_banks.dart';
import 'package:keyva/feature/category/controller/category_catalog_controller.dart';
import 'package:keyva/feature/category/viewmodel/category_inline_create_mixin.dart';
import 'package:keyva/feature/home/model/vault_models.dart';
import 'package:keyva/feature/type/bank_card/util/bank_card_util.dart';

abstract class BankCardFormViewModel extends GetxController
    with CategoryInlineCreateMixin {
  final formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final cardNumberController = TextEditingController();
  final cardHolderController = TextEditingController();
  final bankController = TextEditingController();
  final expiryController = TextEditingController();
  final cvvController = TextEditingController();
  final notesController = TextEditingController();

  final detectedBank = Rxn<BankInfoView>();
  final isCvvVisible = false.obs;
  @override
  final selectedCategoryId = Rxn<String>();
  final isSubmitting = false.obs;
  final submitError = Rxn<String>();
  final bankFieldError = Rxn<String>();

  String get headerTitle;
  String get submitLabel;
  bool get showDeleteAction => false;

  List<VaultCategory> get selectableCategories {
    if (!Get.isRegistered<CategoryCatalogController>()) return const [];
    return Get.find<CategoryCatalogController>().vaultCategories;
  }

  void initFormFields({
    String? categoryId,
    String? title,
    String? cardNumberDigits,
    String? cardHolder,
    String? bankTitle,
    String? expiry,
    String? cvv,
    String? notes,
  }) {
    selectedCategoryId.value = categoryId;
    titleController.text = title ?? '';
    cardNumberController.text = formatCardNumberForDisplay(cardNumberDigits ?? '');
    cardHolderController.text = cardHolder ?? '';
    bankController.text = bankTitle ?? '';
    expiryController.text = expiry ?? '';
    cvvController.text = cvv ?? '';
    notesController.text = notes ?? '';
    _refreshDetectedBank();
  }

  @override
  void onInit() {
    super.onInit();
    cardNumberController.addListener(_onCardNumberChanged);
  }

  void _onCardNumberChanged() {
    bankFieldError.value = null;
    _refreshDetectedBank();
  }

  void _refreshDetectedBank() {
    final digits = extractCardDigits(cardNumberController.text);
    final bank = resolveBankInfoFromCard(digits);
    detectedBank.value = bank;
    bankController.text = bank?.title ?? '';
  }

  void toggleCvvVisibility() {
    isCvvVisible.value = !isCvvVisible.value;
  }

  void onCategoryChanged(String? categoryId) {
    selectedCategoryId.value = categoryId;
  }

  String? validateTitle(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'عنوان الزامی است';
    }
    if (value.trim().length < 2) {
      return 'عنوان باید حداقل ۲ کاراکتر باشد';
    }
    return null;
  }

  String? validateCardHolder(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'نام دارنده کارت الزامی است';
    }
    return null;
  }

  String? validateCardNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'شماره کارت الزامی است';
    }
    final digits = extractCardDigits(value);
    if (!isValidBankCardDigits(digits)) {
      return 'شماره کارت معتبر نیست';
    }
    if (!verifyCardWithLuhn(digits)) {
      return 'شماره کارت معتبر نیست';
    }
    return null;
  }

  String? validateBankDisplay(String? value) {
    final digits = extractCardDigits(cardNumberController.text);
    if (digits.length >= 6 && detectedBank.value == null) {
      return 'بانک شناسایی نشد';
    }
    return null;
  }

  String? validateExpiry(String? value) => validateExpiryInput(value);

  String? validateCvv(String? value) => validateCvvInput(value);

  bool validateForm() {
    bankFieldError.value = null;
    final formValid = formKey.currentState?.validate() ?? false;
    if (!formValid) return false;

    final digits = extractCardDigits(cardNumberController.text);
    if (digits.length >= 6 && detectedBank.value == null) {
      bankFieldError.value = 'بانک شناسایی نشد';
      return false;
    }

    return true;
  }

  String collectCardDigits() => extractCardDigits(cardNumberController.text);

  String collectBankTitle() {
    final bank = detectedBank.value;
    if (bank != null) return bank.title;
    return bankController.text.trim();
  }

  Future<void> submit();

  void handleDelete();

  @override
  void onClose() {
    cardNumberController.removeListener(_onCardNumberChanged);
    titleController.dispose();
    cardNumberController.dispose();
    cardHolderController.dispose();
    bankController.dispose();
    expiryController.dispose();
    cvvController.dispose();
    notesController.dispose();
    super.onClose();
  }
}
