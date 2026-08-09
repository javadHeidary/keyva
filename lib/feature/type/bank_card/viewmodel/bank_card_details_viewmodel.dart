import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iranian_banks/iranian_banks.dart';
import 'package:keyva/core/routes/app_routing.dart';
import 'package:keyva/feature/home/viewmodel/home_viewmodel.dart';
import 'package:keyva/feature/type/bank_card/data/bank_card_vault_store.dart';
import 'package:keyva/feature/type/bank_card/model/bank_card_item_model.dart';
import 'package:keyva/feature/type/bank_card/util/bank_card_util.dart';
import 'package:keyva/shared/widget/app_dialog_widget.dart';
import 'package:keyva/shared/widget/toast_widget.dart';

class BankCardDetailsViewModel extends GetxController {
  BankCardDetailsViewModel({required this.cardId});

  final String cardId;

  final isCvvVisible = false.obs;

  BankCardVaultStore get _store => Get.find<BankCardVaultStore>();

  List<BankCardItem> get storeItems => _store.items;

  BankCardItem? get item {
    for (final entry in _store.items) {
      if (entry.id == cardId) return entry;
    }
    return null;
  }

  String get headerTitle => item?.title ?? 'جزئیات کارت';

  String get categoryLabel {
    final card = item;
    if (card == null) return 'بدون دسته‌بندی';
    if (card.categoryId == null) return 'بدون دسته‌بندی';

    if (!Get.isRegistered<HomeController>()) return 'بدون دسته‌بندی';
    final categories = Get.find<HomeController>().categories;
    for (final category in categories) {
      if (category.id == card.categoryId) return category.name;
    }
    return 'بدون دسته‌بندی';
  }

  String get createdAtLabel {
    final card = item;
    if (card == null) return '';
    return formatBankCardCreatedAt(card.createdAt);
  }

  String get formattedCardNumber {
    final card = item;
    if (card == null) return '';
    return formatCardNumberForDisplay(card.cardNumber);
  }

  BankInfoView? get bankInfo {
    final card = item;
    if (card == null) return null;
    return resolveBankInfoFromCard(card.cardNumber);
  }

  String get displayBankTitle {
    final info = bankInfo;
    if (info != null) return info.title;
    return item?.bankTitle ?? '';
  }

  @override
  void onInit() {
    super.onInit();
    if (item == null) {
      Get.back();
    }
  }

  void toggleCvvVisibility() {
    isCvvVisible.value = !isCvvVisible.value;
  }

  void copyValue(BuildContext context, String value, String successMessage) {
    if (value.isEmpty) return;
    Clipboard.setData(ClipboardData(text: value));
    AppToast.success(context, title: successMessage);
  }

  void navigateToEdit() {
    Get.toNamed(AppRoutes.bankCardEdit, arguments: cardId)?.then((result) {
      if (result == true) {
        update();
      }
    });
  }

  void confirmDelete(BuildContext context) {
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
      },
    );
  }
}
