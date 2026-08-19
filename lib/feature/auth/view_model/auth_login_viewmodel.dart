import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keyva/core/exceptions/result.dart';
import 'package:keyva/core/routes/app_routing.dart';
import 'package:keyva/feature/auth/repository/auth_repository.dart';
import 'package:keyva/feature/vault/service/vault_unlock_service.dart';
import 'package:keyva/feature/vault/view/vault_user_message.dart';

class LoginController extends GetxController {
  LoginController({
    required VaultUnlockService unlock,
    required AuthRepository auth,
  }) : _unlock = unlock,
       _auth = auth;

  final VaultUnlockService _unlock;
  final AuthRepository _auth;

  final passwordController = TextEditingController();
  final isPasswordVisible = false.obs;
  final isLoading = false.obs;
  final errorMessage = ''.obs;
  final loginFormKey = GlobalKey<FormState>();

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
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

  @override
  void onClose() {
    passwordController.dispose();
    super.onClose();
  }
}
