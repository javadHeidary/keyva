import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keyva/core/exceptions/app_failure.dart';
import 'package:keyva/core/exceptions/result.dart';
import 'package:keyva/core/routes/app_routing.dart';
import 'package:keyva/core/security/biometric_service.dart';
import 'package:keyva/core/security/pin_service.dart';
import 'package:keyva/feature/auth/model/account_summary.dart';
import 'package:keyva/feature/auth/repository/auth_repository.dart';
import 'package:keyva/feature/vault/service/vault_unlock_service.dart';
import 'package:keyva/feature/vault/view/vault_user_message.dart';
import 'package:keyva/shared/widget/app_dialog_widget.dart';

enum UnlockMethod { masterPassword, pin, biometric }

class LoginController extends GetxController {
  LoginController({
    required VaultUnlockService unlock,
    required AuthRepository auth,
    PinService? pin,
    BiometricService? biometric,
  }) : _unlock = unlock,
       _auth = auth,
       _pin = pin,
       _biometric = biometric;

  static const pinLockoutMessage =
      'محدودیت تلاش PIN تمام شده است. اکنون فقط با رمز اصلی می‌توانید وارد شوید.';
  static const biometricLockoutMessage =
      'محدودیت تلاش ورود با اثرانگشت تمام شده است. اکنون فقط با رمز اصلی می‌توانید وارد شوید.';
  static const masterPasswordLockoutMessage =
      'محدودیت تلاش رمز اصلی تمام شده است. لطفاً بعد از ۲ دقیقه دوباره تلاش کنید.';
  static const masterPasswordLockoutTitle = 'ورود با رمز اصلی مسدود شد';
  static const loadingMessage = 'در حال ورود...';
  static const errorTitle = 'ورود';
  static const successTitle = 'ورود به حساب';
  static const successBody = 'ورود با موفقیت انجام شد';
  static const wrongPasswordMessage = 'رمز اشتباه است';
  static const emptyPasswordMessage = 'رمز اصلی الزامی است';
  static const shortPasswordMessage = 'رمز اصلی باید حداقل ۸ کاراکتر باشد';
  static const emptyPinMessage = 'کد PIN الزامی است';

  final VaultUnlockService _unlock;
  final AuthRepository _auth;
  final PinService? _pin;
  final BiometricService? _biometric;

  final passwordController = TextEditingController();
  final pinController = TextEditingController();
  final isPasswordVisible = false.obs;
  final isPinVisible = false.obs;
  final isLoading = false.obs;
  final errorMessage = ''.obs;
  final successMessage = ''.obs;
  final loginFormKey = GlobalKey<FormState>();
  final unlockMethod = UnlockMethod.masterPassword.obs;
  final showMethodPicker = true.obs;
  final pinEnabled = false.obs;
  final pinLockedOut = false.obs;
  final biometricEnabled = false.obs;
  final biometricAvailable = false.obs;
  final biometricLockedOut = false.obs;
  final masterPasswordLockedOut = false.obs;
  final masterPasswordLockoutRemaining = Duration.zero.obs;
  final selectedUserId = ''.obs;
  final selectedUsername = ''.obs;
  final canSwitchAccount = false.obs;
  Timer? _masterPasswordLockoutTimer;

  bool get pinAvailable => pinEnabled.value && !pinLockedOut.value;

  bool get biometricOptionAvailable =>
      biometricEnabled.value &&
      biometricAvailable.value &&
      !biometricLockedOut.value;

  @override
  void onInit() {
    super.onInit();
    prepareSelectedAccount();
  }

  Future<void> prepareSelectedAccount() async {
    final argumentId = _argumentUserId();
    String? userId = argumentId;
    if (userId == null) {
      final resolved = await _auth.resolveUnlockUserId();
      if (resolved is Success<String>) {
        userId = resolved.data;
      }
    }
    if (userId == null || userId.isEmpty) {
      Get.offNamed(AppRoutes.authAccounts);
      return;
    }
    selectedUserId.value = userId;
    final account = await _auth.getAccount(userId);
    if (account is Success<AccountSummary>) {
      selectedUsername.value = account.data.username;
    }
    final listed = await _auth.getAccounts();
    if (listed is Success<List<AccountSummary>>) {
      canSwitchAccount.value = listed.data.length > 1;
    }
    await loadUnlockOptions(userId);
  }

  Future<void> loadUnlockOptions(String userId) async {
    if (_pin != null) {
      final enabled = await _pin.isEnabled(userId);
      pinEnabled.value = enabled is Success<bool> && enabled.data;
      final locked = await _pin.isLockedOut(userId);
      pinLockedOut.value = locked is Success<bool> && locked.data;
    }
    if (_biometric != null) {
      biometricAvailable.value = await _biometric.isAvailable();
      final enabled = await _biometric.isEnabled(userId);
      biometricEnabled.value = enabled is Success<bool> && enabled.data;
      final locked = await _biometric.isLockedOut(userId);
      biometricLockedOut.value = locked is Success<bool> && locked.data;
    }
    await _refreshMasterPasswordLockout(userId);
    _showPickerOrMasterPassword();
  }

  void chooseMasterPassword() {
    errorMessage.value = '';
    showMethodPicker.value = false;
    unlockMethod.value = UnlockMethod.masterPassword;
  }

  void choosePin() {
    if (!pinAvailable) {
      return;
    }
    errorMessage.value = '';
    showMethodPicker.value = false;
    unlockMethod.value = UnlockMethod.pin;
  }

  Future<void> chooseBiometric() async {
    if (!biometricOptionAvailable) {
      return;
    }
    await unlockWithBiometric();
  }

  void backToMethods() {
    errorMessage.value = '';
    _showPickerOrMasterPassword();
  }

  void changeAccount() {
    Get.offAllNamed(AppRoutes.authAccounts);
  }

  void useMasterPassword() {
    chooseMasterPassword();
  }

  void usePin() {
    choosePin();
  }

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  void togglePinVisibility() {
    isPinVisible.value = !isPinVisible.value;
  }

  Future<void> login() async {
    if (isLoading.value) {
      return;
    }
    errorMessage.value = '';
    final userId = selectedUserId.value;
    if (userId.isEmpty) {
      Get.offNamed(AppRoutes.authAccounts);
      return;
    }
    if (masterPasswordLockedOut.value) {
      _showLockoutDialog(
        title: masterPasswordLockoutTitle,
        description: masterPasswordLockoutMessage,
      );
      return;
    }
    if (!(loginFormKey.currentState?.validate() ?? false)) {
      return;
    }

    isLoading.value = true;
    var succeeded = false;
    try {
      final unlocked = await _unlock.unlock(
        userId: userId,
        masterPassword: passwordController.text,
      );
      if (unlocked is FailureResult<void>) {
        await _handleMasterPasswordFailure(userId, unlocked.failure);
        return;
      }
      succeeded = true;
      successMessage.value = successBody;
      Get.offAllNamed(AppRoutes.shell);
    } finally {
      passwordController.clear();
      if (!succeeded) {
        isLoading.value = false;
      }
    }
  }

  Future<void> unlockWithPin() async {
    if (isLoading.value) {
      return;
    }
    errorMessage.value = '';
    if (!(loginFormKey.currentState?.validate() ?? false)) {
      return;
    }
    final pin = pinController.text;
    final userId = selectedUserId.value;
    if (userId.isEmpty) {
      Get.offNamed(AppRoutes.authAccounts);
      return;
    }

    isLoading.value = true;
    var succeeded = false;
    try {
      final unlocked = await _unlock.unlockWithPin(userId: userId, pin: pin);
      if (unlocked is FailureResult<void>) {
        await _handlePinFailure(userId, unlocked.failure);
        return;
      }
      succeeded = true;
      successMessage.value = successBody;
      Get.offAllNamed(AppRoutes.shell);
    } finally {
      pinController.clear();
      if (!succeeded) {
        isLoading.value = false;
      }
    }
  }

  Future<void> unlockWithBiometric() async {
    if (isLoading.value) {
      return;
    }
    errorMessage.value = '';
    final userId = selectedUserId.value;
    if (userId.isEmpty) {
      Get.offNamed(AppRoutes.authAccounts);
      return;
    }
    isLoading.value = true;
    var succeeded = false;
    try {
      final unlocked = await _unlock.unlockWithBiometric(userId: userId);
      if (unlocked is FailureResult<void>) {
        if (unlocked.failure is BiometricCancelledFailure) {
          return;
        }
        await _handleBiometricFailure(userId, unlocked.failure);
        return;
      }
      succeeded = true;
      successMessage.value = successBody;
      Get.offAllNamed(AppRoutes.shell);
    } finally {
      if (!succeeded) {
        isLoading.value = false;
      }
    }
  }

  Future<void> _handleMasterPasswordFailure(
    String userId,
    AppFailure failure,
  ) async {
    final wasLocked = masterPasswordLockedOut.value;
    await _refreshMasterPasswordLockout(userId);
    if (masterPasswordLockedOut.value) {
      if (!wasLocked) {
        _showLockoutDialog(
          title: masterPasswordLockoutTitle,
          description: masterPasswordLockoutMessage,
        );
      }
      return;
    }
    final remaining = await _auth.remainingMasterPasswordAttempts(userId);
    if (remaining is Success<int> && remaining.data > 0) {
      errorMessage.value = _masterPasswordRemainingMessage(remaining.data);
      return;
    }
    errorMessage.value = failure is AuthenticationFailure
        ? wrongPasswordMessage
        : vaultUserMessage(failure.message);
  }

  Future<void> _refreshMasterPasswordLockout(String userId) async {
    final locked = await _auth.isMasterPasswordLockedOut(userId);
    masterPasswordLockedOut.value = locked is Success<bool> && locked.data;
    if (!masterPasswordLockedOut.value) {
      masterPasswordLockoutRemaining.value = Duration.zero;
      _stopMasterPasswordLockoutTimer();
      return;
    }
    await _tickMasterPasswordLockout(userId);
    _startMasterPasswordLockoutTimer();
  }

  void _startMasterPasswordLockoutTimer() {
    _masterPasswordLockoutTimer?.cancel();
    _masterPasswordLockoutTimer = Timer.periodic(const Duration(seconds: 1), (
      _,
    ) {
      final userId = selectedUserId.value;
      if (userId.isEmpty) {
        return;
      }
      unawaited(_tickMasterPasswordLockout(userId));
    });
  }

  void _stopMasterPasswordLockoutTimer() {
    _masterPasswordLockoutTimer?.cancel();
    _masterPasswordLockoutTimer = null;
  }

  Future<void> _tickMasterPasswordLockout(String userId) async {
    final remaining = await _auth.remainingMasterPasswordLockout(userId);
    if (remaining is Success<Duration>) {
      masterPasswordLockoutRemaining.value = remaining.data;
      if (remaining.data <= Duration.zero) {
        final locked = await _auth.isMasterPasswordLockedOut(userId);
        masterPasswordLockedOut.value = locked is Success<bool> && locked.data;
        if (!masterPasswordLockedOut.value) {
          _stopMasterPasswordLockoutTimer();
        }
      }
    }
  }

  Future<void> _handlePinFailure(String userId, AppFailure failure) async {
    final wasLocked = pinLockedOut.value;
    final locked = await _pin?.isLockedOut(userId);
    pinLockedOut.value = locked is Success<bool> && locked.data;
    if (pinLockedOut.value) {
      if (!wasLocked) {
        _showLockoutDialog(
          title: 'ورود با PIN مسدود شد',
          description: pinLockoutMessage,
        );
      }
      chooseMasterPassword();
      return;
    }
    final remaining = await _pin?.remainingAttempts(userId);
    if (remaining is Success<int> && remaining.data > 0) {
      errorMessage.value = _pinRemainingMessage(remaining.data);
      return;
    }
    errorMessage.value = vaultUserMessage(failure.message);
  }

  Future<void> _handleBiometricFailure(
    String userId,
    AppFailure failure,
  ) async {
    final wasLocked = biometricLockedOut.value;
    final locked = await _biometric?.isLockedOut(userId);
    biometricLockedOut.value = locked is Success<bool> && locked.data;
    if (biometricLockedOut.value) {
      if (!wasLocked) {
        _showLockoutDialog(
          title: 'ورود با اثرانگشت مسدود شد',
          description: biometricLockoutMessage,
        );
      }
      chooseMasterPassword();
      return;
    }
    if (failure is BiometricAuthFailedFailure) {
      final remaining = await _biometric?.remainingAttempts(userId);
      if (remaining is Success<int> && remaining.data > 0) {
        errorMessage.value = _biometricRemainingMessage(remaining.data);
        return;
      }
    }
    errorMessage.value = vaultUserMessage(failure.message);
  }

  void _showLockoutDialog({
    required String title,
    required String description,
  }) {
    final context = Get.context;
    if (context == null) {
      return;
    }
    AppDialogWidget.show(
      context,
      type: AppDialogType.warning,
      title: title,
      description: description,
    );
  }

  String _masterPasswordRemainingMessage(int remaining) {
    return 'رمز اشتباه است. ${_persianCount(remaining)} تلاش باقی مانده است.';
  }

  String _pinRemainingMessage(int remaining) {
    return 'کد PIN اشتباه است. ${_persianCount(remaining)} تلاش باقی مانده است.';
  }

  String _biometricRemainingMessage(int remaining) {
    return 'ورود با اثرانگشت ناموفق بود. ${_persianCount(remaining)} تلاش باقی مانده است.';
  }

  String _persianCount(int value) {
    const digits = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
    return value.toString().split('').map((char) {
      final digit = int.tryParse(char);
      return digit == null ? char : digits[digit];
    }).join();
  }

  String? _argumentUserId() {
    final arguments = Get.arguments;
    if (arguments is String && arguments.isNotEmpty) {
      return arguments;
    }
    return null;
  }

  void _showPickerOrMasterPassword() {
    final hasAlternate = pinAvailable || biometricOptionAvailable;
    showMethodPicker.value = hasAlternate;
    if (!hasAlternate) {
      unlockMethod.value = UnlockMethod.masterPassword;
    }
  }

  String formatMasterPasswordLockoutRemaining() {
    final remaining = masterPasswordLockoutRemaining.value;
    final totalSeconds = remaining.inSeconds < 0 ? 0 : remaining.inSeconds;
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return 'ورود تا $minutes:$seconds مسدود است';
  }

  @override
  void onClose() {
    _stopMasterPasswordLockoutTimer();
    passwordController.dispose();
    pinController.dispose();
    super.onClose();
  }
}
