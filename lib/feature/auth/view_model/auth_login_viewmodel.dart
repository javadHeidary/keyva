import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keyva/core/routes/app_routing.dart';

class LoginController extends GetxController {
  final passwordController = TextEditingController();
  final isPasswordVisible = false.obs;
  final isLoading = false.obs;
  final errorMessage = ''.obs;
  final loginFormKey = GlobalKey<FormState>();

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  Future<void> login() async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      await Future.delayed(const Duration(milliseconds: 800));
      Get.offAllNamed(AppRoutes.home);
    } catch (e) {
      errorMessage.value = 'خطا در ورود. لطفاً دوباره تلاش کنید';
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

  @override
  void onClose() {
    passwordController.dispose();
    super.onClose();
  }
}
