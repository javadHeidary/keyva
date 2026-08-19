import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keyva/core/database/models/user_record.dart';
import 'package:keyva/core/exceptions/result.dart';
import 'package:keyva/core/routes/app_routing.dart';
import 'package:keyva/feature/auth/repository/auth_repository.dart';
import 'package:keyva/feature/vault/service/vault_unlock_service.dart';
import 'package:keyva/feature/vault/view/vault_user_message.dart';

class RegisterController extends GetxController {
  RegisterController({
    required AuthRepository auth,
    required VaultUnlockService unlock,
  }) : _auth = auth,
       _unlock = unlock;

  final AuthRepository _auth;
  final VaultUnlockService _unlock;

  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final registerFormKey = GlobalKey<FormState>();

  final isPasswordVisible = false.obs;
  final isConfirmPasswordVisible = false.obs;
  final isLoading = false.obs;
  final errorMessage = ''.obs;

  final dialogCountdown = 3.obs;
  final canConfirmDialog = false.obs;

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  void toggleConfirmPasswordVisibility() {
    isConfirmPasswordVisible.value = !isConfirmPasswordVisible.value;
  }

  void startWarningDialogCountdown() {
    dialogCountdown.value = 3;
    canConfirmDialog.value = false;
    _runCountdown();
  }

  Future<void> _runCountdown() async {
    while (dialogCountdown.value > 0) {
      await Future.delayed(const Duration(seconds: 1));
      if (isClosed) return;
      dialogCountdown.value--;
    }
    canConfirmDialog.value = true;
  }

  Future<void> createAccount() async {
    if (isLoading.value) {
      return;
    }
    errorMessage.value = '';
    if (!(registerFormKey.currentState?.validate() ?? false)) {
      return;
    }
    if (passwordController.text != confirmPasswordController.text) {
      errorMessage.value = 'تکرار رمز عبور یکسان نیست';
      return;
    }

    isLoading.value = true;
    try {
      final created = await _auth.createAccount(
        username: usernameController.text.trim(),
        masterPassword: passwordController.text,
      );
      if (created is FailureResult<UserRecord>) {
        errorMessage.value = vaultUserMessage(created.failure.message);
        return;
      }
      final user = (created as Success<UserRecord>).data;
      final unlocked = await _unlock.unlock(
        userId: user.id,
        masterPassword: passwordController.text,
      );
      if (unlocked is FailureResult<void>) {
        errorMessage.value = vaultUserMessage(unlocked.failure.message);
        return;
      }
      Get.offAllNamed(AppRoutes.shell);
    } finally {
      passwordController.clear();
      confirmPasswordController.clear();
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    usernameController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }
}
