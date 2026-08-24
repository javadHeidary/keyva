import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:keyva/core/routes/app_routing.dart';
import 'package:keyva/feature/home/viewmodel/home_viewmodel.dart';
import 'package:keyva/feature/type/login/util/login_password_util.dart';
import 'package:keyva/feature/vault/model/login_item.dart';
import 'package:keyva/feature/vault/share/share_confirm_dialog.dart';
import 'package:keyva/feature/vault/share/share_sheet_service.dart';
import 'package:keyva/feature/vault/share/share_vault_item.dart';
import 'package:keyva/feature/vault/share/vault_item_share_formatter.dart';
import 'package:keyva/feature/vault/view/vault_list_item_mapper.dart';
import 'package:keyva/feature/vault/viewmodel/vault_home_viewmodel.dart';
import 'package:keyva/shared/utils/jalali_date_formatter.dart';
import 'package:keyva/shared/widget/toast_widget.dart';
import 'package:url_launcher/url_launcher.dart';

class LoginDetailsViewModel extends GetxController {
  LoginDetailsViewModel({
    required this.loginId,
    required this.shareSheet,
    this.formatter = const VaultItemShareFormatter(),
    this.confirmShare,
  });

  final String loginId;
  final ShareSheetService shareSheet;
  final VaultItemShareFormatter formatter;
  final Future<bool> Function(BuildContext context)? confirmShare;

  final isPasswordVisible = false.obs;

  VaultHomeViewModel? get _vaultHome => Get.isRegistered<VaultHomeViewModel>()
      ? Get.find<VaultHomeViewModel>()
      : null;

  LoginItem? get item {
    final data = _vaultHome?.vault.value;
    final found = findVaultItemById(data, loginId);
    return found is LoginItem ? found : null;
  }

  String get headerTitle => item?.title ?? 'جزئیات ورود';

  String get categoryLabel => vaultCategoryLabel(
    _vaultHome?.vault.value,
    item?.categoryId,
  );

  String get updatedAtLabel {
    final login = item;
    if (login == null) return '';
    return formatJalaliDate(login.updatedAt);
  }

  double get passwordStrength {
    final login = item;
    if (login == null) return 0;
    return calculateLoginPasswordStrength(login.password);
  }

  String get passwordStrengthLabel =>
      loginPasswordStrengthLabel(passwordStrength);

  @override
  void onInit() {
    super.onInit();
    if (item == null) {
      Get.back();
    }
  }

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  void copyValue(BuildContext context, String value, String successMessage) {
    if (value.isEmpty) return;
    Clipboard.setData(ClipboardData(text: value));
    AppToast.success(context, title: 'کپی', message: successMessage);
  }

  Future<void> openWebsite(BuildContext context, String website) async {
    final normalized = normalizeWebsiteUrl(website);
    if (normalized == null) {
      AppToast.error(context, title: 'آدرس وب‌سایت معتبر نیست');
      return;
    }

    final uri = Uri.parse(normalized);
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!context.mounted) return;
    if (!launched) {
      AppToast.error(context, title: 'باز کردن وب‌سایت انجام نشد');
    }
  }

  void navigateToEdit() {
    Get.toNamed(AppRoutes.loginEdit, arguments: loginId);
  }

  void confirmDelete(BuildContext context) {
    final login = item;
    if (login == null || !Get.isRegistered<HomeController>()) return;
    final listItem = mapVaultListItem(login);
    if (listItem == null) return;
    Get.find<HomeController>().confirmDelete(
      context,
      listItem,
      onDeleted: Get.back,
    );
  }

  Future<void> togglePin(BuildContext context) async {
    final login = item;
    if (login == null || !Get.isRegistered<HomeController>()) return;
    final listItem = mapVaultListItem(login);
    if (listItem == null) return;
    await Get.find<HomeController>().toggleItemPin(context, listItem);
  }

  Future<void> shareItem(BuildContext context) async {
    final login = item;
    if (login == null) return;
    await shareVaultItem(
      context: context,
      shareSheet: shareSheet,
      text: formatter.formatLogin(login, categoryName: categoryLabel),
      subject: VaultItemShareFormatter.loginSubject,
      confirmShare: confirmShare ?? showShareConfirmDialog,
    );
  }
}
