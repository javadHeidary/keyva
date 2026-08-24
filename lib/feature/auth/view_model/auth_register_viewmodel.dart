import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keyva/core/database/models/user_record.dart';
import 'package:keyva/core/exceptions/result.dart';
import 'package:keyva/core/routes/app_routing.dart';
import 'package:keyva/core/security/master_password_policy.dart';
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
  final passwordStrength = 0.0.obs;
  final hasPasswordInput = false.obs;

  final dialogCountdown = 3.obs;
  final canConfirmDialog = false.obs;

  @override
  void onInit() {
    super.onInit();
    passwordController.addListener(_syncPasswordStrength);
  }

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  void toggleConfirmPasswordVisibility() {
    isConfirmPasswordVisible.value = !isConfirmPasswordVisible.value;
  }

  void _syncPasswordStrength() {
    final password = passwordController.text;
    hasPasswordInput.value = password.isNotEmpty;
    passwordStrength.value = _visualPasswordStrength(password);
  }

  double _visualPasswordStrength(String password) {
    if (password.isEmpty) {
      return 0;
    }
    var score = 0.0;
    if (password.length >= 8) {
      score += 0.2;
    }
    if (password.length >= 12) {
      score += 0.2;
    }
    if (RegExp('[a-z]').hasMatch(password)) {
      score += 0.15;
    }
    if (RegExp('[A-Z]').hasMatch(password)) {
      score += 0.15;
    }
    if (RegExp('[0-9]').hasMatch(password)) {
      score += 0.15;
    }
    if (RegExp(r'[^a-zA-Z0-9]').hasMatch(password)) {
      score += 0.15;
    }
    return score.clamp(0.0, 1.0);
  }

  String? confirmPasswordValidator(String? value) {
    final policyError = MasterPasswordPolicy.fieldError(value);
    if (policyError != null) {
      return policyError;
    }
    if (value != passwordController.text) {
      return 'تکرار رمز عبور یکسان نیست';
    }
    return null;
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
    passwordController.removeListener(_syncPasswordStrength);
    usernameController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }
}
