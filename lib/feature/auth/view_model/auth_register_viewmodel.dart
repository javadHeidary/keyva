import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keyva/core/routes/app_routing.dart';

class RegisterController extends GetxController {
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
    isLoading.value = true;

    try {
      await Future.delayed(const Duration(milliseconds: 900));
      Get.offAllNamed(AppRoutes.home);
    } catch (e) {
      errorMessage.value = 'خطا در ایجاد حساب. لطفاً دوباره تلاش کنید';
    } finally {
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
