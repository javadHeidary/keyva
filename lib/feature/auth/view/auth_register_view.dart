import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keyva/core/routes/app_routing.dart';
import 'package:keyva/core/security/master_password_policy.dart';
import 'package:keyva/core/theme/app_spacing.dart';
import 'package:keyva/core/theme/app_typography.dart';
import 'package:keyva/core/theme/extensions/responsive_extentions.dart';
import 'package:keyva/core/theme/extensions/theme_extentions.dart';
import 'package:keyva/feature/auth/view_model/auth_register_viewmodel.dart';
import 'package:keyva/feature/auth/widget/auth_brand_header.dart';
import 'package:keyva/feature/auth/widget/auth_countdown_warning_dialog.dart';
import 'package:keyva/feature/auth/widget/auth_error_toast_binder.dart';
import 'package:keyva/feature/auth/widget/auth_footer_link.dart';
import 'package:keyva/shared/icons/app_icons.dart';
import 'package:keyva/shared/widget/app_buttom_widget.dart';
import 'package:keyva/shared/widget/app_textfield_widget.dart';
import 'package:keyva/shared/widget/password_strengthbar_widget.dart';

class AuthRegisterView extends GetView<RegisterController> {
  const AuthRegisterView({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: AuthErrorToastBinder(
        message: controller.errorMessage,
        child: SafeArea(
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.pagePadding.s,
                AppSpacing.pagePadding.h,
                AppSpacing.pagePadding.s,
                AppSpacing.pagePadding.h + bottomInset,
              ),
              child: Column(
                children: [
                  const AuthBrandHeader(compact: false),
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
                  SizedBox(height: AppSpacing.sectionGap.h),
                  Form(
                    key: controller.registerFormKey,
                    child: Column(
                      children: [
                        Obx(() {
                          return AppTextFieldWidget(
                            key: const Key('auth-register-username'),
                            controller: controller.usernameController,
                            enabled: !controller.isLoading.value,
                            textInputAction: TextInputAction.next,
                            labelText: 'نام کاربری',
                            hintText: 'یک نام برای حساب خود انتخاب کنید',
                            prefixIcon: const Icon(AppIcon.accountCircle),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'نام کاربری الزامی است';
                              }
                              if (value.trim().length < 3) {
                                return 'نام کاربری باید حداقل ۳ کاراکتر باشد';
                              }
                              return null;
                            },
                          );
                        }),
                        SizedBox(height: AppSpacing.lg.h),
                        Obx(() {
                          return AppTextFieldWidget(
                            key: const Key('auth-register-password'),
                            controller: controller.passwordController,
                            enabled: !controller.isLoading.value,
                            obscureText: !controller.isPasswordVisible.value,
                            textInputAction: TextInputAction.next,
                            labelText: 'رمز اصلی',
                            hintText: 'رمز اصلی را وارد کنید',
                            prefixIcon: const Icon(AppIcon.lock),
                            suffixIcon: IconButton(
                              onPressed: controller.togglePasswordVisibility,
                              icon: Icon(
                                controller.isPasswordVisible.value
                                    ? AppIcon.visibilityOff
                                    : AppIcon.visibility,
                              ),
                            ),
                            validator: MasterPasswordPolicy.fieldError,
                          );
                        }),
                        Obx(() {
                          if (!controller.hasPasswordInput.value) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: EdgeInsets.only(top: AppSpacing.sm.h),
                            child: PasswordStrengthBarWidget(
                              strength: controller.passwordStrength.value,
                              showLabel: true,
                              useSegmentedBars: true,
                            ),
                          );
                        }),
                        SizedBox(height: AppSpacing.lg.h),
                        Obx(() {
                          return AppTextFieldWidget(
                            key: const Key('auth-register-confirm'),
                            controller: controller.confirmPasswordController,
                            enabled: !controller.isLoading.value,
                            obscureText:
                                !controller.isConfirmPasswordVisible.value,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _onRegisterPressed(),
                            labelText: 'تکرار رمز اصلی',
                            hintText: 'رمز اصلی را دوباره وارد کنید',
                            prefixIcon: const Icon(AppIcon.lock),
                            validator: controller.confirmPasswordValidator,
                            suffixIcon: IconButton(
                              onPressed:
                                  controller.toggleConfirmPasswordVisibility,
                              icon: Icon(
                                controller.isConfirmPasswordVisible.value
                                    ? AppIcon.visibilityOff
                                    : AppIcon.visibility,
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  SizedBox(height: AppSpacing.xxl.h),
                  Obx(() {
                    return AppButtonWidget(
                      key: const Key('auth-register-submit'),
                      title: 'ایجاد حساب',
                      isLoading: controller.isLoading.value,
                      onPressed: _onRegisterPressed,
                    );
                  }),
                  SizedBox(height: AppSpacing.sectionGap.h),
                  AuthFooterLink(
                    key: const Key('auth-register-to-accounts'),
                    prefix: 'اکانت دارید؟ ',
                    actionLabel: 'ورود',
                    prefixColor: colors.textSecondary,
                    onTap: () => Get.offNamed(AppRoutes.authAccounts),
                  ),
                  SizedBox(height: AppSpacing.md.h),
                  AuthFooterLink(
                    key: const Key('auth-register-to-restore'),
                    prefix: 'فایل پشتیبان دارید؟ ',
                    actionLabel: 'بازیابی',
                    prefixColor: colors.textSecondary,
                    onTap: () => Get.toNamed(AppRoutes.authRestore),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onRegisterPressed() {
    if (controller.isLoading.value) {
      return;
    }
    if (!(controller.registerFormKey.currentState?.validate() ?? false)) {
      return;
    }
    controller.startWarningDialogCountdown();
    showAuthCountdownWarningDialog(
      countdown: controller.dialogCountdown,
      canConfirm: controller.canConfirmDialog,
      onConfirm: controller.createAccount,
    );
  }
}
