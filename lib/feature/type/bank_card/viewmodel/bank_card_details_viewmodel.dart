import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iranian_banks/iranian_banks.dart';
import 'package:keyva/core/routes/app_routing.dart';
import 'package:keyva/feature/home/viewmodel/home_viewmodel.dart';
import 'package:keyva/feature/type/bank_card/util/bank_card_util.dart';
import 'package:keyva/feature/vault/model/bank_card_item.dart';
import 'package:keyva/feature/vault/share/share_confirm_dialog.dart';
import 'package:keyva/feature/vault/share/share_sheet_service.dart';
import 'package:keyva/feature/vault/share/share_vault_item.dart';
import 'package:keyva/feature/vault/share/vault_item_share_formatter.dart';
import 'package:keyva/feature/vault/view/vault_list_item_mapper.dart';
import 'package:keyva/feature/vault/viewmodel/vault_home_viewmodel.dart';
import 'package:keyva/shared/utils/jalali_date_formatter.dart';
import 'package:keyva/shared/widget/toast_widget.dart';

class BankCardDetailsViewModel extends GetxController {
  BankCardDetailsViewModel({
    required this.cardId,
    required this.shareSheet,
    this.formatter = const VaultItemShareFormatter(),
    this.confirmShare,
    this.openedAfterCreate = false,
  });

  final String cardId;
  final bool openedAfterCreate;
  final ShareSheetService shareSheet;
  final VaultItemShareFormatter formatter;
  final Future<bool> Function(BuildContext context)? confirmShare;

  final isCvvVisible = false.obs;

  VaultHomeViewModel? get _vaultHome => Get.isRegistered<VaultHomeViewModel>()
      ? Get.find<VaultHomeViewModel>()
      : null;

  BankCardItem? get item {
    final data = _vaultHome?.vault.value;
    final found = findVaultItemById(data, cardId);
    return found is BankCardItem ? found : null;
  }

  String get headerTitle => item?.title ?? 'جزئیات کارت';

  String get categoryLabel => vaultCategoryLabel(
    _vaultHome?.vault.value,
    item?.categoryId,
  );

  String get createdAtLabel {
    final card = item;
    if (card == null) return '';
    return formatJalaliDate(card.createdAt);
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
    return item?.bankName ?? '';
  }

  String get expiryMonth => splitBankCardExpiry(item?.expiryDate ?? '').month;

  String get expiryYear => splitBankCardExpiry(item?.expiryDate ?? '').year;

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

  void copyValue(
    BuildContext context,
    String value,
    String title,
    String successMessage,
  ) {
    if (value.isEmpty) return;
    Clipboard.setData(ClipboardData(text: value));
    AppToast.success(context, title: title, message: successMessage);
  }

  void navigateToEdit() {
    Get.toNamed(AppRoutes.bankCardEdit, arguments: cardId);
  }

  void confirmDelete(BuildContext context) {
    final card = item;
    if (card == null || !Get.isRegistered<HomeController>()) return;
    final listItem = mapVaultListItem(card);
    if (listItem == null) return;
    Get.find<HomeController>().confirmDelete(
      context,
      listItem,
      onDeleted: Get.back,
    );
  }

  Future<void> togglePin(BuildContext context) async {
    final card = item;
    if (card == null || !Get.isRegistered<HomeController>()) return;
    final listItem = mapVaultListItem(card);
    if (listItem == null) return;
    await Get.find<HomeController>().toggleItemPin(context, listItem);
  }

  Future<void> shareItem(BuildContext context) async {
    final card = item;
    if (card == null) return;
    await shareVaultItem(
      context: context,
      shareSheet: shareSheet,
      text: formatter.formatBankCard(
        card,
        categoryName: categoryLabel,
        bankTitle: displayBankTitle,
      ),
      subject: VaultItemShareFormatter.cardSubject,
      confirmShare: confirmShare ?? showShareConfirmDialog,
    );
  }
}
