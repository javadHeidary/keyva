import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keyva/core/routes/app_routing.dart';
import 'package:keyva/feature/home/viewmodel/home_viewmodel.dart';
import 'package:keyva/feature/settings/model/app_info.dart';
import 'package:keyva/feature/settings/model/security_settings_ui_state.dart';
import 'package:keyva/feature/settings/model/settings_repository.dart';
import 'package:keyva/feature/settings/model/theme_preference.dart';
import 'package:keyva/feature/settings/model/user_profile.dart';
import 'package:keyva/shared/widget/toast_widget.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsViewModel extends GetxController {
  SettingsViewModel({SettingsRepository? repository})
    : _repository = repository;

  final SettingsRepository? _repository;

  SettingsRepository? get repository => _repository;

  final profile = const UserProfile(name: UserProfile.defaultName).obs;
  final themePreference = ThemePreference.system.obs;
  final security = const SecuritySettingsUiState().obs;

  /// Phase 1: mock device support until repository is wired.
  final showBiometricSetting = true.obs;

  @override
  void onInit() {
    super.onInit();
    _syncProfileFromHome();
  }

  void _syncProfileFromHome() {
    if (Get.isRegistered<HomeController>()) {
      final home = Get.find<HomeController>();
      profile.value = profile.value.copyWith(name: home.accountOwnerName.value);
      if (home.accountAvatarId.value.isNotEmpty) {
        profile.value = profile.value.copyWith(
          avatarId: home.accountAvatarId.value,
        );
      }
    }
  }

  void updateProfile(UserProfile value) {
    profile.value = value;
    if (Get.isRegistered<HomeController>()) {
      final home = Get.find<HomeController>();
      home.updateAccountProfile(name: value.name, avatarId: value.avatarId);
    }
    // TODO: delegate to _repository?.saveProfile(value)
  }

  void setThemePreference(ThemePreference? value) {
    if (value == null) return;
    themePreference.value = value;
    Get.changeThemeMode(value.themeMode);
    // TODO: delegate to _repository?.saveThemePreference(value)
  }

  void setBiometricEnabled(bool value) {
    security.value = security.value.copyWith(biometricEnabled: value);
    // TODO: authenticate + _repository?.saveSecuritySettings
  }

  void setPinEnabled(bool value) {
    security.value = security.value.copyWith(pinEnabled: value);
    // TODO: delegate to repository when PIN is saved
  }

  void onPinToggle(bool enabled, BuildContext context) {
    if (!enabled) {
      setPinEnabled(false);
      return;
    }
    // Dialog flow sets pinEnabled on successful submit.
  }

  Future<void> openFeedback(BuildContext context) async {
    final uri = Uri(
      scheme: 'mailto',
      path: AppInfo.feedbackEmail,
      queryParameters: {'subject': 'نقد و پیشنهادات — کیوا'},
    );
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) {
        AppToast.info(context, title: 'ایمیل: ${AppInfo.feedbackEmail}');
      }
    } catch (_) {
      if (!context.mounted) return;
      AppToast.info(context, title: 'ایمیل: ${AppInfo.feedbackEmail}');
    }
  }

  void onOpenOtherApps(BuildContext context) {
    AppToast.info(context, title: 'لیست اپلیکیشن‌ها به‌زودی');
  }

  void onRateApp(BuildContext context) {
    AppToast.info(context, title: 'امتیازدهی در فاز بعد فعال می‌شود');
  }

  void onShareApp(BuildContext context) {
    AppToast.info(context, title: 'اشتراک‌گذاری در فاز بعد فعال می‌شود');
  }

  void setPreventScreenshot(bool value) {
    security.value = security.value.copyWith(preventScreenshot: value);
    // TODO: ScreenshotGuardService via repository
  }

  void setLockOnAppExit(bool value) {
    security.value = security.value.copyWith(lockOnAppExit: value);
    // TODO: AppLockService via repository
  }

  Future<void> onChangeMasterPasswordSubmitted({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
    required BuildContext context,
  }) async {
    if (newPassword != confirmPassword) {
      AppToast.error(context, title: 'تکرار رمز با رمز جدید یکسان نیست');
      return;
    }
    if (newPassword.length < 8) {
      AppToast.error(context, title: 'رمز جدید باید حداقل ۸ کاراکتر باشد');
      return;
    }
    // TODO: _repository?.changeMasterPassword(...)
    Get.back();
    if (!context.mounted) return;
    // AppToast.success(context, title: 'در فاز بعد ذخیره می‌شود');
  }

  Future<void> onPinSubmitted({
    required String pin,
    required String confirmPin,
    required BuildContext context,
  }) async {
    if (pin.length < 4) {
      AppToast.error(context, title: 'کد PIN باید حداقل ۴ رقم باشد');
      return;
    }
    if (pin != confirmPin) {
      AppToast.error(context, title: 'تکرار PIN یکسان نیست');
      return;
    }
    setPinEnabled(true);
    // TODO: _repository?.savePin(pin)
    Get.back();
    if (!context.mounted) return;
    // AppToast.success(context, title: 'در فاز بعد ذخیره می‌شود');
  }

  void onBackupExportTap(BuildContext context) {
    // TODO: _repository?.exportBackup()
    // AppToast.success(context, title: 'در فاز بعد ذخیره می‌شود');
  }

  void onBackupImportTap(BuildContext context) {
    // TODO: _repository?.importBackup()
    // AppToast.success(context, title: 'در فاز بعد ذخیره می‌شود');
  }

  Future<void> onLogoutConfirmed() async {
    // TODO: _repository?.logout()
    Get.offAllNamed(AppRoutes.authLogin);
  }
}
