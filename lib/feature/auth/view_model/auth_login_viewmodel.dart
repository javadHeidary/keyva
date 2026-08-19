import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keyva/core/exceptions/app_failure.dart';
import 'package:keyva/core/exceptions/result.dart';
import 'package:keyva/core/routes/app_routing.dart';
import 'package:keyva/core/security/biometric_service.dart';
import 'package:keyva/core/security/pin_policy.dart';
import 'package:keyva/core/security/pin_service.dart';
import 'package:keyva/feature/auth/repository/auth_repository.dart';
import 'package:keyva/feature/vault/service/vault_unlock_service.dart';
import 'package:keyva/feature/vault/view/vault_user_message.dart';

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
  final loginFormKey = GlobalKey<FormState>();
  final unlockMethod = UnlockMethod.masterPassword.obs;
  final pinEnabled = false.obs;
  final pinLockedOut = false.obs;
  final biometricEnabled = false.obs;
  final biometricAvailable = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadUnlockOptions();
  }

  Future<void> loadUnlockOptions() async {
    final resolved = await _auth.resolveUnlockUserId();
    if (resolved is! Success<String>) {
      return;
    }
    final userId = resolved.data;

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
    }
    _selectPreferredMethod();
    if (unlockMethod.value == UnlockMethod.biometric) {
      unlockWithBiometric();
    }
  }

  void useMasterPassword() {
    errorMessage.value = '';
    unlockMethod.value = UnlockMethod.masterPassword;
  }

  void usePin() {
    if (!pinEnabled.value || pinLockedOut.value) {
      return;
    }
    errorMessage.value = '';
    unlockMethod.value = UnlockMethod.pin;
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
    if (!(loginFormKey.currentState?.validate() ?? false)) {
      return;
    }

    isLoading.value = true;
    try {
      final resolved = await _auth.resolveUnlockUserId();
      if (resolved is FailureResult<String>) {
        errorMessage.value = vaultUserMessage(resolved.failure.message);
        return;
      }
      final userId = (resolved as Success<String>).data;
      final unlocked = await _unlock.unlock(
        userId: userId,
        masterPassword: passwordController.text,
      );
      if (unlocked is FailureResult<void>) {
        errorMessage.value = vaultUserMessage(unlocked.failure.message);
        return;
      }
      Get.offAllNamed(AppRoutes.shell);
    } finally {
      passwordController.clear();
      isLoading.value = false;
    }
  }

  Future<void> unlockWithPin() async {
    if (isLoading.value) {
      return;
    }
    errorMessage.value = '';
    final pin = pinController.text;
    if (!PinPolicy.isValid(pin)) {
      errorMessage.value = 'کد PIN باید ۴ تا ۶ رقم باشد';
      return;
    }

    isLoading.value = true;
    try {
      final resolved = await _auth.resolveUnlockUserId();
      if (resolved is FailureResult<String>) {
        errorMessage.value = vaultUserMessage(resolved.failure.message);
        return;
      }
      final userId = (resolved as Success<String>).data;
      final unlocked = await _unlock.unlockWithPin(userId: userId, pin: pin);
      if (unlocked is FailureResult<void>) {
        final locked = await _pin?.isLockedOut(userId);
        pinLockedOut.value = locked is Success<bool> && locked.data;
        if (pinLockedOut.value) {
          unlockMethod.value = UnlockMethod.masterPassword;
        }
        errorMessage.value = vaultUserMessage(unlocked.failure.message);
        return;
      }
      Get.offAllNamed(AppRoutes.shell);
    } finally {
      pinController.clear();
      isLoading.value = false;
    }
  }

  Future<void> unlockWithBiometric() async {
    if (isLoading.value) {
      return;
    }
    errorMessage.value = '';
    isLoading.value = true;
    try {
      final resolved = await _auth.resolveUnlockUserId();
      if (resolved is FailureResult<String>) {
        errorMessage.value = vaultUserMessage(resolved.failure.message);
        return;
      }
      final userId = (resolved as Success<String>).data;
      final unlocked = await _unlock.unlockWithBiometric(userId: userId);
      if (unlocked is FailureResult<void>) {
        if (unlocked.failure is BiometricCancelledFailure) {
          return;
        }
        errorMessage.value = vaultUserMessage(unlocked.failure.message);
        return;
      }
      Get.offAllNamed(AppRoutes.shell);
    } finally {
      isLoading.value = false;
    }
  }

  void showMultiAccountInfo() {
    Get.dialog(
      Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('چند حساب روی دستگاه', textAlign: TextAlign.right),
          content: const Text(
            'اگر چند حساب روی این دستگاه دارید، تنها کافی است رمز اکانت مربوط به هر حساب را وارد کنید. '
            'برنامه به‌صورت خودکار همان حساب را شناسایی و وارد آن می‌شود.\n\n'
            'لیستی از حساب‌ها نمایش داده نمی‌شود تا حریم خصوصی شما حفظ شود.',
            textAlign: TextAlign.right,
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('متوجه شدم', textAlign: TextAlign.left),
            ),
          ],
        ),
      ),
    );
  }

  void _selectPreferredMethod() {
    if (biometricEnabled.value && biometricAvailable.value) {
      unlockMethod.value = UnlockMethod.biometric;
    } else if (pinEnabled.value && !pinLockedOut.value) {
      unlockMethod.value = UnlockMethod.pin;
    } else {
      unlockMethod.value = UnlockMethod.masterPassword;
    }
  }

  @override
  void onClose() {
    passwordController.dispose();
    pinController.dispose();
    super.onClose();
  }
}
