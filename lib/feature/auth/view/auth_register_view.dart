import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keyva/core/theme/app_spacing.dart';
import 'package:keyva/core/theme/app_typography.dart';
import 'package:keyva/core/theme/extensions/responsive_extentions.dart';
import 'package:keyva/core/theme/extensions/theme_extentions.dart';
import 'package:keyva/feature/auth/view_model/auth_register_viewmodel.dart';
import 'package:keyva/shared/widget/app_buttom_widget.dart';
import 'package:keyva/shared/widget/app_textfield_widget.dart';

class AuthRegisterView extends StatelessWidget {
  const AuthRegisterView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<RegisterController>();
    final colors = context.colors;

    return Scaffold(
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg.s),
            child: Column(
              children: [
                SizedBox(height: 24.h),
                Container(
                  width: 72.s,
                  height: 72.s,
                  decoration: const BoxDecoration(shape: BoxShape.circle),
                  child: Icon(
                    Icons.lock_outline_rounded,
                    size: 36.s,
                    color: colors.primary,
                  ),
                ),
                SizedBox(height: AppSpacing.lg.h),
                Text(
                  'ایجاد حساب جدید',
                  style: AppTypography.headlineLarge.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
                SizedBox(height: AppSpacing.sm.h),
                Text(
                  'رمز اصلی شما مبنای رمزنگاری تمام اطلاعات خواهد بود',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                SizedBox(height: AppSpacing.sectionGap.h + AppSpacing.xs.h),

                SizedBox(height: AppSpacing.xxxl.h),
                Form(
                  key: controller.registerFormKey,
                  child: Column(
                    children: [
                      AppTextField(
                        controller: controller.usernameController,
                        textInputAction: TextInputAction.next,
                        labelText: 'نام کاربری',
                        hintText: 'یک نام برای حساب خود انتخاب کنید',
                        prefixIcon: const Icon(Icons.person_add_outlined),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'نام کاربری الزامی است';
                          }
                          if (value.trim().length < 3) {
                            return 'نام کاربری باید حداقل ۳ کاراکتر باشد';
                          }
                          return null;
                        },
                      ),

                      SizedBox(height: AppSpacing.lg.h),
                      Obx(() {
                        return AppTextField(
                          controller: controller.passwordController,
                          obscureText: !controller.isPasswordVisible.value,
                          textInputAction: TextInputAction.next,
                          labelText: 'Master Password',
                          hintText: 'رمز اصلی را وارد کنید',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              controller.isPasswordVisible.value
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: controller.togglePasswordVisibility,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'رمز عبور الزامی است';
                            }
                            if (value.length < 8) {
                              return 'رمز عبور باید حداقل ۸ کاراکتر باشد';
                            }
                            return null;
                          },
                        );
                      }),
                      SizedBox(height: AppSpacing.lg.h),
                      Obx(() {
                        return AppTextField(
                          controller: controller.confirmPasswordController,
                          obscureText:
                              !controller.isConfirmPasswordVisible.value,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) =>
                              _onRegisterPressed(controller),
                          labelText: 'تکرار Master Password',
                          hintText: 'رمز اصلی را دوباره وارد کنید',
                          prefixIcon: const Icon(Icons.lock_outline),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'رمز عبور الزامی است';
                            }
                            if (value.length < 8) {
                              return 'رمز عبور باید حداقل ۸ کاراکتر باشد';
                            }
                            return null;
                          },
                          suffixIcon: IconButton(
                            icon: Icon(
                              controller.isConfirmPasswordVisible.value
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed:
                                controller.toggleConfirmPasswordVisibility,
                          ),
                        );
                      }),
                    ],
                  ),
                ),

                SizedBox(height: AppSpacing.xxl.h),
                Obx(() {
                  return AppButton(
                    title: 'ثبت‌نام',
                    isLoading: controller.isLoading.value,
                    onPressed: () => _onRegisterPressed(controller),
                  );
                }),
                SizedBox(height: AppSpacing.sectionGap.h + AppSpacing.xs.h),
                const _LoginText(),
                SizedBox(height: AppSpacing.xxxl.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onRegisterPressed(RegisterController controller) {
    if (!controller.registerFormKey.currentState!.validate()) return;
    controller.startWarningDialogCountdown();
    _showMasterPasswordWarningDialog(controller);
  }

  void _showMasterPasswordWarningDialog(RegisterController controller) {
    Get.dialog(
      barrierDismissible: false,
      Obx(() {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: Text('هشدار مهم امنیتی', style: AppTypography.headlineSmall),
            content: Text(
              'رمز اصلی (Master Password) مهم‌ترین رمز برنامه است.\n\n'
              'در صورت فراموش کردن این رمز، امکان بازیابی اطلاعات شما وجود ندارد.\n\n'
              'لطفاً آن را در محل امنی یادداشت کنید یا در یک Password Manager ذخیره نمایید.',
              style: AppTypography.bodyMedium,
            ),
            actions: [
              TextButton(
                onPressed: controller.canConfirmDialog.value
                    ? () {
                        Get.back();
                        controller.createAccount();
                      }
                    : null,
                child: Text(
                  controller.canConfirmDialog.value
                      ? 'متوجه شدم و ادامه می‌دهم'
                      : 'متوجه شدم (${controller.dialogCountdown.value})',
                  style: AppTypography.button,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

/// Keeps [TapGestureRecognizer] alive to avoid recreating it on rebuild.
class _LoginText extends StatefulWidget {
  const _LoginText();

  @override
  State<_LoginText> createState() => _LoginTextState();
}

class _LoginTextState extends State<_LoginText> {
  late final TapGestureRecognizer _recognizer;

  @override
  void initState() {
    super.initState();
    _recognizer = TapGestureRecognizer()..onTap = Get.back;
  }

  @override
  void dispose() {
    _recognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Text.rich(
      TextSpan(
        text: 'اکانت دارید؟ ',
        style: AppTypography.bodyMedium.copyWith(color: colors.textSecondary),
        children: [
          TextSpan(
            text: 'ورود',
            style: AppTypography.titleMedium.copyWith(color: colors.primary),
            recognizer: _recognizer,
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
