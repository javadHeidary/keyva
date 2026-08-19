import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keyva/core/database/models/security_settings.dart';
import 'package:keyva/core/di/injection_container.dart';
import 'package:keyva/core/exceptions/app_failure.dart';
import 'package:keyva/core/exceptions/result.dart';
import 'package:keyva/core/routes/app_routing.dart';
import 'package:keyva/core/security/biometric_service.dart';
import 'package:keyva/core/security/master_password_policy.dart';
import 'package:keyva/core/security/pin_policy.dart';
import 'package:keyva/core/security/pin_service.dart';
import 'package:keyva/core/session/session_service.dart';
import 'package:keyva/feature/auth/repository/auth_repository.dart';
import 'package:keyva/feature/home/viewmodel/home_viewmodel.dart';
import 'package:keyva/feature/settings/model/app_info.dart';
import 'package:keyva/feature/settings/model/security_settings_ui_state.dart';
import 'package:keyva/feature/settings/model/settings_repository.dart';
import 'package:keyva/feature/settings/model/theme_preference.dart';
import 'package:keyva/feature/settings/model/user_profile.dart';
import 'package:keyva/feature/vault/service/vault_unlock_service.dart';
import 'package:keyva/feature/vault/view/vault_user_message.dart';
import 'package:keyva/shared/widget/toast_widget.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsViewModel extends GetxController {
  SettingsViewModel({
    SettingsRepository? repository,
    VaultUnlockService? unlock,
    PinService? pin,
    BiometricService? biometric,
    SessionService? session,
    AuthRepository? auth,
  }) : _repository = repository,
       _unlockOverride = unlock,
       _pinOverride = pin,
       _biometricOverride = biometric,
       _sessionOverride = session,
       _authOverride = auth;

  final SettingsRepository? _repository;
  final VaultUnlockService? _unlockOverride;
  final PinService? _pinOverride;
  final BiometricService? _biometricOverride;
  final SessionService? _sessionOverride;
  final AuthRepository? _authOverride;

  SettingsRepository? get repository => _repository;

  VaultUnlockService get _unlock =>
      _unlockOverride ?? getIt<VaultUnlockService>();

  PinService? get _pin {
    if (_pinOverride != null) {
      return _pinOverride;
    }
    if (getIt.isRegistered<PinService>()) {
      return getIt<PinService>();
    }
    return null;
  }

  BiometricService? get _biometric {
    if (_biometricOverride != null) {
      return _biometricOverride;
    }
    if (getIt.isRegistered<BiometricService>()) {
      return getIt<BiometricService>();
    }
    return null;
  }

  SessionService? get _session {
    if (_sessionOverride != null) {
      return _sessionOverride;
    }
    if (getIt.isRegistered<SessionService>()) {
      return getIt<SessionService>();
    }
    return null;
  }

  AuthRepository? get _auth {
    if (_authOverride != null) {
      return _authOverride;
    }
    if (getIt.isRegistered<AuthRepository>()) {
      return getIt<AuthRepository>();
    }
    return null;
  }

  final profile = const UserProfile(name: UserProfile.defaultName).obs;
  final themePreference = ThemePreference.system.obs;
  final security = const SecuritySettingsUiState().obs;
  final showBiometricSetting = false.obs;
  final isSecurityBusy = false.obs;

  static const _biometricEnableReason = 'برای فعال‌سازی باز کردن با اثر انگشت یا چهره';

  @override
  void onInit() {
    super.onInit();
    _syncProfileFromHome();
    loadSecuritySettings();
  }

  Future<void> loadSecuritySettings() async {
    final session = _session;
    final userId = session?.current?.userId;
    if (userId == null) {
      showBiometricSetting.value = false;
      return;
    }

    final auth = _auth;
    if (auth != null) {
      final loaded = await auth.currentSecuritySettings();
      if (loaded is Success<SecuritySettings>) {
        security.value = security.value.copyWith(
          autoLockTimeout: loaded.data.autoLockTimeout,
        );
      }
    }

    final pin = _pin;
    if (pin != null) {
      final enabled = await pin.isEnabled(userId);
      security.value = security.value.copyWith(
        pinEnabled: enabled is Success<bool> && enabled.data,
      );
    }

    final biometric = _biometric;
    if (biometric != null) {
      showBiometricSetting.value = await biometric.isAvailable();
      final enabled = await biometric.isEnabled(userId);
      security.value = security.value.copyWith(
        biometricEnabled: enabled is Success<bool> && enabled.data,
      );
    } else {
      showBiometricSetting.value = false;
    }
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

  Future<void> onBiometricToggle(bool enabled, BuildContext context) async {
    if (isSecurityBusy.value) {
      return;
    }
    if (!enabled) {
      return;
    }
    await enableBiometric(context);
  }

  Future<void> enableBiometric(BuildContext context) async {
    final biometric = _biometric;
    if (biometric == null || isSecurityBusy.value) {
      return;
    }
    isSecurityBusy.value = true;
    try {
      final result = await biometric.enable(
        localizedReason: _biometricEnableReason,
      );
      if (!context.mounted) {
        return;
      }
      if (result is FailureResult<void>) {
        if (result.failure is! BiometricCancelledFailure) {
          AppToast.error(
            context,
            title: vaultUserMessage(result.failure.message),
          );
        }
        return;
      }
      security.value = security.value.copyWith(biometricEnabled: true);
    } finally {
      isSecurityBusy.value = false;
    }
  }

  Future<void> disableBiometric(BuildContext context) async {
    final biometric = _biometric;
    if (biometric == null || isSecurityBusy.value) {
      return;
    }
    isSecurityBusy.value = true;
    try {
      final result = await biometric.disable();
      if (!context.mounted) {
        return;
      }
      if (result is FailureResult<void>) {
        AppToast.error(
          context,
          title: vaultUserMessage(result.failure.message),
        );
        return;
      }
      security.value = security.value.copyWith(biometricEnabled: false);
    } finally {
      isSecurityBusy.value = false;
    }
  }

  Future<void> disablePin(BuildContext context) async {
    final pin = _pin;
    if (pin == null || isSecurityBusy.value) {
      return;
    }
    isSecurityBusy.value = true;
    try {
      final result = await pin.disable();
      if (!context.mounted) {
        return;
      }
      if (result is FailureResult<void>) {
        AppToast.error(
          context,
          title: vaultUserMessage(result.failure.message),
        );
        return;
      }
      security.value = security.value.copyWith(pinEnabled: false);
    } finally {
      isSecurityBusy.value = false;
    }
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

  Future<void> setAutoLockTimeout(Duration timeout) async {
    final auth = _auth;
    if (auth == null || isSecurityBusy.value) {
      return;
    }
    isSecurityBusy.value = true;
    try {
      final result = await auth.setAutoLockTimeout(timeout);
      if (result is FailureResult<void>) {
        return;
      }
      security.value = security.value.copyWith(autoLockTimeout: timeout);
    } finally {
      isSecurityBusy.value = false;
    }
  }

  Future<void> onChangeMasterPasswordSubmitted({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
    required BuildContext context,
  }) async {
    if (isSecurityBusy.value) {
      return;
    }
    final policyError = MasterPasswordPolicy.fieldError(newPassword);
    if (policyError != null) {
      AppToast.error(context, title: policyError);
      return;
    }
    if (newPassword != confirmPassword) {
      AppToast.error(context, title: 'تکرار رمز با رمز جدید یکسان نیست');
      return;
    }
    final auth = _auth;
    if (auth == null) {
      AppToast.error(context, title: 'عملیات امنیتی انجام نشد.');
      return;
    }
    isSecurityBusy.value = true;
    try {
      final result = await auth.changeMasterPassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      if (!context.mounted) {
        return;
      }
      if (result is FailureResult<void>) {
        AppToast.error(
          context,
          title: vaultUserMessage(result.failure.message),
        );
        return;
      }
      AppToast.success(
        context,
        title: 'رمز اصلی',
        message: 'رمز اصلی به‌روزرسانی شد',
      );
      Get.back();
    } finally {
      isSecurityBusy.value = false;
    }
  }

  Future<void> onPinSubmitted({
    required String pin,
    required String confirmPin,
    required BuildContext context,
  }) async {
    if (!PinPolicy.isValid(pin)) {
      AppToast.error(context, title: 'کد PIN باید ۴ تا ۶ رقم باشد');
      return;
    }
    if (pin != confirmPin) {
      AppToast.error(context, title: 'تکرار PIN یکسان نیست');
      return;
    }
    final pinService = _pin;
    if (pinService == null || isSecurityBusy.value) {
      AppToast.error(context, title: 'عملیات امنیتی انجام نشد.');
      return;
    }
    isSecurityBusy.value = true;
    try {
      final result = await pinService.enable(pin);
      if (!context.mounted) {
        return;
      }
      if (result is FailureResult<void>) {
        AppToast.error(
          context,
          title: vaultUserMessage(result.failure.message),
        );
        return;
      }
      security.value = security.value.copyWith(pinEnabled: true);
      Get.back();
    } finally {
      isSecurityBusy.value = false;
    }
  }

  Future<void> onPinChanged({
    required String currentPin,
    required String pin,
    required String confirmPin,
    required BuildContext context,
  }) async {
    if (!PinPolicy.isValid(pin)) {
      AppToast.error(context, title: 'کد PIN باید ۴ تا ۶ رقم باشد');
      return;
    }
    if (pin != confirmPin) {
      AppToast.error(context, title: 'تکرار PIN یکسان نیست');
      return;
    }
    final pinService = _pin;
    if (pinService == null || isSecurityBusy.value) {
      AppToast.error(context, title: 'عملیات امنیتی انجام نشد.');
      return;
    }
    isSecurityBusy.value = true;
    try {
      final result = await pinService.change(
        currentPin: currentPin,
        newPin: pin,
      );
      if (!context.mounted) {
        return;
      }
      if (result is FailureResult<void>) {
        AppToast.error(
          context,
          title: vaultUserMessage(result.failure.message),
        );
        return;
      }
      Get.back();
    } finally {
      isSecurityBusy.value = false;
    }
  }

  Future<void> lock() async {
    await _unlock.lock();
    Get.offAllNamed(AppRoutes.authLogin);
  }

  Future<void> onLogoutConfirmed() async {
    await _unlock.lock();
    Get.offAllNamed(AppRoutes.authLogin);
  }
}
