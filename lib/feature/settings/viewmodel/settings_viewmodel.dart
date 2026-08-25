import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keyva/core/database/models/security_settings.dart';
import 'package:keyva/core/database/models/user_record.dart';
import 'package:keyva/core/di/injection_container.dart';
import 'package:keyva/core/exceptions/app_failure.dart';
import 'package:keyva/core/exceptions/result.dart';
import 'package:keyva/core/routes/app_routing.dart';
import 'package:keyva/core/security/biometric_service.dart';
import 'package:keyva/core/security/master_password_policy.dart';
import 'package:keyva/core/security/pin_policy.dart';
import 'package:keyva/core/security/pin_service.dart';
import 'package:keyva/core/security/screen_protection_service.dart';
import 'package:keyva/core/session/app_lock_controller.dart';
import 'package:keyva/core/session/session_service.dart';
import 'package:keyva/feature/auth/model/account_deletion_outcome.dart';
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

typedef SettingsUrlLauncher = Future<bool> Function(Uri uri);

class SettingsViewModel extends GetxController {
  SettingsViewModel({
    SettingsRepository? repository,
    VaultUnlockService? unlock,
    PinService? pin,
    BiometricService? biometric,
    SessionService? session,
    AuthRepository? auth,
    ScreenProtectionService? screenProtection,
    SettingsUrlLauncher? launchUrlFn,
    String? telegramUrl,
    String? baleUrl,
    String? baleFallbackUrl,
    String? supportEmail,
  }) : _repository = repository,
       _unlockOverride = unlock,
       _pinOverride = pin,
       _biometricOverride = biometric,
       _sessionOverride = session,
       _authOverride = auth,
       _screenProtectionOverride = screenProtection,
       _launchUrl = launchUrlFn ?? _launchExternal,
       telegramUrl = telegramUrl ?? AppInfo.telegramUrl,
       baleUrl = baleUrl ?? AppInfo.baleUrl,
       baleFallbackUrl = baleFallbackUrl ?? AppInfo.baleFallbackUrl,
       supportEmail = supportEmail ?? AppInfo.feedbackEmail;

  final SettingsRepository? _repository;
  final VaultUnlockService? _unlockOverride;
  final PinService? _pinOverride;
  final BiometricService? _biometricOverride;
  final SessionService? _sessionOverride;
  final AuthRepository? _authOverride;
  final ScreenProtectionService? _screenProtectionOverride;
  final SettingsUrlLauncher _launchUrl;
  final String telegramUrl;
  final String baleUrl;
  final String baleFallbackUrl;
  final String supportEmail;

  static Future<bool> _launchExternal(Uri uri) {
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

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

  ScreenProtectionService? get _screenProtection {
    if (_screenProtectionOverride != null) {
      return _screenProtectionOverride;
    }
    if (getIt.isRegistered<ScreenProtectionService>()) {
      return getIt<ScreenProtectionService>();
    }
    return null;
  }

  final profile = const UserProfile(name: UserProfile.defaultName).obs;
  final themePreference = ThemePreference.system.obs;
  final security = const SecuritySettingsUiState().obs;
  final showBiometricSetting = false.obs;
  final isSecurityBusy = false.obs;

  static const _biometricEnableReason =
      'برای فعال‌سازی ورود با اثرانگشت';

  @override
  void onInit() {
    super.onInit();
    loadThemePreference();
    loadProfile();
    loadSecuritySettings();
  }

  Future<void> loadThemePreference() async {
    final repository = _repository;
    if (repository == null) {
      return;
    }
    themePreference.value = await repository.loadThemePreference();
  }

  Future<void> loadProfile() async {
    final auth = _auth;
    if (auth != null) {
      final loaded = await auth.currentUser();
      if (loaded is Success<UserRecord>) {
        final value = UserProfile(name: loaded.data.username);
        profile.value = value;
        _applyProfileToHome(value);
        return;
      }
    }
    _syncProfileFromHome();
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
          preventScreenshot: loaded.data.preventScreenshots,
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
    }
  }

  void _applyProfileToHome(UserProfile value) {
    if (Get.isRegistered<HomeController>()) {
      final home = Get.find<HomeController>();
      home.updateAccountProfile(name: value.name);
    }
  }

  Future<bool> updateProfile(UserProfile value) async {
    final trimmed = value.copyWith(name: value.name.trim());
    if (trimmed.name.isEmpty) {
      return false;
    }
    final auth = _auth;
    if (auth != null) {
      final saved = await auth.updateProfile(username: trimmed.name);
      if (saved is FailureResult<void>) {
        return false;
      }
    }
    profile.value = trimmed;
    _applyProfileToHome(trimmed);
    return true;
  }

  Future<void> setThemePreference(ThemePreference? value) async {
    if (value == null) return;
    themePreference.value = value;
    Get.changeThemeMode(value.themeMode);
    await _repository?.saveThemePreference(value);
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
            title: 'بیومتریک',
            message: vaultUserMessage(result.failure.message),
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
          title: 'بیومتریک',
          message: vaultUserMessage(result.failure.message),
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
          title: 'کد PIN',
          message: vaultUserMessage(result.failure.message),
        );
        return;
      }
      security.value = security.value.copyWith(pinEnabled: false);
    } finally {
      isSecurityBusy.value = false;
    }
  }

  Future<void> openFeedback(BuildContext context) async {
    await _openMailto(
      context,
      email: AppInfo.feedbackEmail,
      subject: 'نقد و پیشنهادات — کیوا',
    );
  }

  Future<bool> openTelegram(BuildContext context) {
    return _openConfiguredLink(
      context,
      url: telegramUrl,
      unconfiguredMessage: 'لینک تلگرام کیوا هنوز تنظیم نشده است.',
    );
  }

  Future<bool> openBale(BuildContext context) async {
    if (baleUrl.trim().isEmpty && baleFallbackUrl.trim().isEmpty) {
      if (context.mounted) {
        AppToast.info(
          context,
          title: 'ارتباط با ما',
          message: 'لینک بله کیوا هنوز تنظیم نشده است.',
        );
      }
      return false;
    }

    if (baleUrl.trim().isNotEmpty) {
      final opened = await _tryLaunch(Uri.parse(baleUrl.trim()));
      if (opened) return true;
    }

    if (baleFallbackUrl.trim().isNotEmpty) {
      final opened = await _tryLaunch(Uri.parse(baleFallbackUrl.trim()));
      if (opened) return true;
    }

    if (context.mounted) {
      AppToast.info(
        context,
        title: 'ارتباط با ما',
        message: 'امکان باز کردن بله روی این دستگاه وجود ندارد.',
      );
    }
    return false;
  }

  Future<bool> openSupportEmail(BuildContext context) {
    return _openMailto(
      context,
      email: supportEmail,
      subject: AppInfo.supportEmailSubject,
    );
  }

  Future<bool> _openConfiguredLink(
    BuildContext context, {
    required String url,
    required String unconfiguredMessage,
  }) async {
    if (url.trim().isEmpty) {
      if (context.mounted) {
        AppToast.info(
          context,
          title: 'ارتباط با ما',
          message: unconfiguredMessage,
        );
      }
      return false;
    }

    final opened = await _tryLaunch(Uri.parse(url.trim()));
    if (opened) return true;
    if (context.mounted) {
      AppToast.info(
        context,
        title: 'ارتباط با ما',
        message: 'امکان باز کردن این مسیر ارتباطی وجود ندارد.',
      );
    }
    return false;
  }

  Future<bool> _openMailto(
    BuildContext context, {
    required String email,
    required String subject,
  }) async {
    final uri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {'subject': subject},
    );
    try {
      final launched = await _launchUrl(uri);
      if (launched) return true;
      if (context.mounted) {
        AppToast.info(context, title: 'ایمیل', message: 'ایمیل: $email');
      }
      return false;
    } catch (_) {
      if (context.mounted) {
        AppToast.info(context, title: 'ایمیل', message: 'ایمیل: $email');
      }
      return false;
    }
  }

  Future<bool> _tryLaunch(Uri uri) async {
    try {
      return await _launchUrl(uri);
    } catch (_) {
      return false;
    }
  }

  void onOpenOtherApps(BuildContext context) {
    AppToast.info(context, title: 'به‌زودی', message: 'لیست اپلیکیشن‌ها به‌زودی');
  }

  void onRateApp(BuildContext context) {
    AppToast.info(
      context,
      title: 'به‌زودی',
      message: 'امتیازدهی در فاز بعد فعال می‌شود',
    );
  }

  void onShareApp(BuildContext context) {
    AppToast.info(
      context,
      title: 'به‌زودی',
      message: 'اشتراک‌گذاری در فاز بعد فعال می‌شود',
    );
  }

  Future<void> setPreventScreenshot(bool value, BuildContext context) async {
    if (isSecurityBusy.value) {
      return;
    }
    final auth = _auth;
    final protection = _screenProtection;
    if (auth == null || protection == null) {
      AppToast.error(
        context,
        title: 'محافظت صفحه',
        message: vaultUserMessage(const AuthenticationFailure().message),
      );
      return;
    }
    final previous = security.value.preventScreenshot;
    isSecurityBusy.value = true;
    try {
      final persisted = await auth.setPreventScreenshots(value);
      if (persisted is FailureResult<void>) {
        if (context.mounted) {
          AppToast.error(
            context,
            title: 'محافظت صفحه',
            message: vaultUserMessage(persisted.failure.message),
          );
        }
        return;
      }
      final applied = await protection.setEnabled(value);
      if (applied is FailureResult<void>) {
        await auth.setPreventScreenshots(previous);
        if (context.mounted) {
          AppToast.error(
            context,
            title: 'محافظت صفحه',
            message: vaultUserMessage(applied.failure.message),
          );
        }
        return;
      }
      security.value = security.value.copyWith(preventScreenshot: value);
    } finally {
      isSecurityBusy.value = false;
    }
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
      if (Get.isRegistered<AppLockController>()) {
        Get.find<AppLockController>().onTimeoutChanged(timeout);
      }
    } finally {
      isSecurityBusy.value = false;
    }
  }

  static const _changeMasterPasswordTitle = 'تغییر رمز اصلی';

  Future<void> onChangeMasterPasswordSubmitted({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
    required BuildContext context,
  }) async {
    if (isSecurityBusy.value) {
      return;
    }
    final validationMessage = _changeMasterPasswordValidationMessage(
      currentPassword: currentPassword,
      newPassword: newPassword,
      confirmPassword: confirmPassword,
    );
    if (validationMessage != null) {
      AppToast.error(
        context,
        title: _changeMasterPasswordTitle,
        message: validationMessage,
      );
      return;
    }
    final auth = _auth;
    if (auth == null) {
      AppToast.error(
        context,
        title: _changeMasterPasswordTitle,
        message: 'تغییر رمز اصلی انجام نشد. لطفاً دوباره تلاش کنید.',
      );
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
          title: _changeMasterPasswordTitle,
          message: _changeMasterPasswordFailureMessage(result.failure),
        );
        return;
      }
      AppToast.success(
        context,
        title: 'رمز اصلی تغییر کرد',
        message: 'از این به بعد برای ورود با رمز، از رمز جدید استفاده کنید.',
      );
      Get.back();
    } finally {
      isSecurityBusy.value = false;
    }
  }

  String? _changeMasterPasswordValidationMessage({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) {
    if (currentPassword.isEmpty) {
      return 'رمز اصلی فعلی را وارد کنید.';
    }
    switch (MasterPasswordPolicy.validate(newPassword)) {
      case MasterPasswordValidationError.empty:
        return 'رمز اصلی جدید را وارد کنید.';
      case MasterPasswordValidationError.tooShort:
        return 'رمز اصلی جدید باید حداقل ۸ کاراکتر باشد.';
      case null:
        break;
    }
    if (confirmPassword.isEmpty) {
      return 'تکرار رمز اصلی جدید را وارد کنید.';
    }
    if (newPassword != confirmPassword) {
      return 'تکرار رمز با رمز اصلی جدید یکسان نیست.';
    }
    if (newPassword == currentPassword) {
      return 'رمز اصلی جدید باید با رمز فعلی متفاوت باشد.';
    }
    return null;
  }

  String _changeMasterPasswordFailureMessage(AppFailure failure) {
    if (failure is AuthenticationFailure) {
      return 'رمز اصلی فعلی صحیح نیست.';
    }
    return 'تغییر رمز اصلی انجام نشد. لطفاً دوباره تلاش کنید.';
  }

  Future<void> onPinSubmitted({
    required String pin,
    required String confirmPin,
    required BuildContext context,
  }) async {
    if (isSecurityBusy.value) {
      return;
    }
    if (!PinPolicy.isValid(pin)) {
      AppToast.error(context, title: 'کد PIN', message: PinPolicy.userMessage);
      return;
    }
    if (pin != confirmPin) {
      AppToast.error(
        context,
        title: 'کد PIN',
        message: 'تکرار PIN یکسان نیست',
      );
      return;
    }
    final pinService = _pin;
    if (pinService == null) {
      AppToast.error(
        context,
        title: 'کد PIN',
        message: 'عملیات امنیتی انجام نشد.',
      );
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
          title: 'کد PIN',
          message: vaultUserMessage(result.failure.message),
        );
        return;
      }
      security.value = security.value.copyWith(pinEnabled: true);
      AppToast.success(context, title: 'کد PIN', message: 'کد PIN تنظیم شد');
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
    if (isSecurityBusy.value) {
      return;
    }
    if (!PinPolicy.isValid(pin)) {
      AppToast.error(context, title: 'کد PIN', message: PinPolicy.userMessage);
      return;
    }
    if (pin != confirmPin) {
      AppToast.error(
        context,
        title: 'کد PIN',
        message: 'تکرار PIN یکسان نیست',
      );
      return;
    }
    final pinService = _pin;
    if (pinService == null) {
      AppToast.error(
        context,
        title: 'کد PIN',
        message: 'عملیات امنیتی انجام نشد.',
      );
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
          title: 'کد PIN',
          message: vaultUserMessage(result.failure.message),
        );
        return;
      }
      AppToast.success(
        context,
        title: 'کد PIN',
        message: 'کد PIN به‌روزرسانی شد',
      );
      Get.back();
    } finally {
      isSecurityBusy.value = false;
    }
  }

  Future<void> lock() async {
    await _unlock.lock();
    Get.offAllNamed(AppRoutes.authAccounts);
  }

  Future<void> onLogoutConfirmed() async {
    await _unlock.lock();
    Get.offAllNamed(AppRoutes.authAccounts);
  }

  Future<void> onDeleteAccountConfirmed({
    required String masterPassword,
    required BuildContext context,
  }) async {
    if (isSecurityBusy.value) {
      return;
    }
    if (masterPassword.isEmpty) {
      AppToast.error(
        context,
        title: 'حذف حساب',
        message: 'رمز اصلی را وارد کنید.',
      );
      return;
    }
    final auth = _auth;
    if (auth == null) {
      AppToast.error(
        context,
        title: 'حذف حساب',
        message: 'عملیات امنیتی انجام نشد.',
      );
      return;
    }
    isSecurityBusy.value = true;
    _beginCriticalSection();
    try {
      final result = await auth.deleteAccount(masterPassword: masterPassword);
      if (!context.mounted) {
        return;
      }
      if (result is FailureResult<AccountDeletionOutcome>) {
        final failure = result.failure;
        AppToast.error(
          context,
          title: 'حذف حساب',
          message: failure is AuthenticationFailure
              ? 'رمز اصلی صحیح نیست'
              : 'حذف حساب کامل نشد. لطفاً دوباره تلاش کنید.',
        );
        return;
      }
      final remaining =
          (result as Success<AccountDeletionOutcome>).data.hasRemainingAccounts;
      AppToast.success(
        context,
        title: 'حساب حذف شد',
        message: 'اطلاعات این حساب از روی دستگاه پاک شد.',
      );
      Navigator.of(context).pop();
      await _unlock.lock();
      final route = remaining ? AppRoutes.authAccounts : AppRoutes.onBoarding;
      await Get.offAllNamed(route);
    } finally {
      _endCriticalSection();
      isSecurityBusy.value = false;
    }
  }

  void _beginCriticalSection() {
    if (Get.isRegistered<AppLockController>()) {
      Get.find<AppLockController>().beginCriticalSection();
    }
  }

  void _endCriticalSection() {
    if (Get.isRegistered<AppLockController>()) {
      Get.find<AppLockController>().endCriticalSection();
    }
  }
}
