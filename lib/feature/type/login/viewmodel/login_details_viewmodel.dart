import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:keyva/core/routes/app_routing.dart';
import 'package:keyva/feature/category/controller/category_catalog_controller.dart';
import 'package:keyva/feature/type/login/data/login_vault_store.dart';
import 'package:keyva/feature/type/login/model/login_item_model.dart';
import 'package:keyva/feature/type/login/util/login_password_util.dart';
import 'package:keyva/shared/widget/app_dialog_widget.dart';
import 'package:keyva/shared/widget/toast_widget.dart';
import 'package:url_launcher/url_launcher.dart';

class LoginDetailsViewModel extends GetxController {
  LoginDetailsViewModel({required this.loginId});

  final String loginId;

  final isPasswordVisible = false.obs;

  LoginVaultStore get _store => Get.find<LoginVaultStore>();

  List<LoginItem> get storeItems => _store.items;

  LoginItem? get item {
    for (final entry in _store.items) {
      if (entry.id == loginId) return entry;
    }
    return null;
  }

  String get headerTitle => item?.title ?? 'جزئیات ورود';

  String get categoryLabel {
    final login = item;
    if (login == null) return 'بدون دسته‌بندی';
    if (!Get.isRegistered<CategoryCatalogController>()) {
      return 'بدون دسته‌بندی';
    }
    return Get.find<CategoryCatalogController>().labelForCategoryId(
      login.categoryId,
    );
  }

  String get createdAtLabel {
    final login = item;
    if (login == null) return '';
    return formatLoginDetailsDate(login.createdAt);
  }

  double get passwordStrength {
    final login = item;
    if (login == null) return 0;
    return calculateLoginPasswordStrength(login.password);
  }

  String get passwordStrengthLabel =>
      loginPasswordStrengthLabel(passwordStrength);

  String? get websiteHost => websiteHostForFavicon(item?.primaryWebsite);

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
    Get.toNamed(AppRoutes.loginEdit, arguments: loginId)?.then((result) {
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
          'این ورود به سطل زباله منتقل می‌شود و می‌توانید بعداً آن را بازگردانی کنید.',
      buttonText: 'انتقال به سطل زباله',
      onConfirm: () {
        _store.moveToTrash(loginId);
        Get.back();
      },
    );
  }
}
