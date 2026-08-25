import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keyva/core/constants/layout_constants.dart';
import 'package:keyva/core/theme/app_spacing.dart';
import 'package:keyva/core/theme/app_typography.dart';
import 'package:keyva/core/theme/extensions/responsive_extentions.dart';
import 'package:keyva/core/theme/extensions/theme_extentions.dart';
import 'package:keyva/feature/backup/viewmodel/restore_viewmodel.dart';
import 'package:keyva/feature/backup/widget/restore_progress_overlay.dart';
import 'package:keyva/shared/icons/app_icons.dart';
import 'package:keyva/shared/widget/app_buttom_widget.dart';
import 'package:keyva/shared/widget/app_header_widget.dart';
import 'package:keyva/shared/widget/app_textfield_widget.dart';

class RestoreAccountSetupView extends StatelessWidget {
  const RestoreAccountSetupView({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final controller = Get.find<RestoreViewModel>();

    return Scaffold(
      resizeToAvoidBottomInset: LayoutConstants.resizeToAvoidBottomInset,
      backgroundColor: colors.pageBackground,
      body: SafeArea(
        child: Column(
          children: [
            AppHeaderWidget(
              title: 'حساب جدید برای بازیابی',
              titleAlign: TextAlign.center,
              leading: Icon(
                AppIcon.arrowBack,
                size: 24.s,
                color: colors.textPrimary,
              ),
              onLeadingTap: Get.back,
            ),
            Expanded(
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.pagePadding.s,
                    vertical: AppSpacing.pagePadding.h,
                  ),
                  child: Form(
                    key: controller.setupFormKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'رمز فایل پشتیبان فقط برای باز کردن فایل استفاده شد. '
                          'برای این دستگاه یک رمز اصلی جدید انتخاب کنید.',
                          textAlign: TextAlign.right,
                          style: AppTypography.bodyMedium.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                        SizedBox(height: AppSpacing.sectionGap.h),
                        AppTextFieldWidget(
                          key: const Key('backup-restore-setup-username'),
                          controller: controller.usernameController,
                          textInputAction: TextInputAction.next,
                          labelText: 'نام کاربری',
                          hintText: 'یک نام برای حساب خود انتخاب کنید',
                          prefixIcon: const Icon(AppIcon.accountCircle),
                          validator: restoreUsernameError,
                        ),
                        SizedBox(height: AppSpacing.lg.h),
                        Obx(() {
                          return AppTextFieldWidget(
                            key: const Key('backup-restore-setup-password'),
                            controller: controller.passwordController,
                            obscureText: !controller.isPasswordVisible.value,
                            textInputAction: TextInputAction.next,
                            labelText: 'رمز اصلی',
                            hintText: 'یک رمز اصلی جدید انتخاب کنید',
                            prefixIcon: const Icon(AppIcon.lock),
                            validator: restoreMasterPasswordError,
                            suffixIcon: IconButton(
                              icon: Icon(
                                controller.isPasswordVisible.value
                                    ? AppIcon.visibilityOff
                                    : AppIcon.visibility,
                              ),
                              onPressed: controller.togglePasswordVisibility,
                            ),
                          );
                        }),
                        SizedBox(height: AppSpacing.lg.h),
                        Obx(() {
                          return AppTextFieldWidget(
                            key: const Key('backup-restore-setup-confirm'),
                            controller: controller.confirmPasswordController,
                            obscureText:
                                !controller.isConfirmPasswordVisible.value,
                            textInputAction: TextInputAction.done,
                            labelText: 'تکرار رمز اصلی',
                            hintText: 'رمز اصلی را دوباره وارد کنید',
                            prefixIcon: const Icon(AppIcon.lock),
                            validator: restoreMasterPasswordError,
                            suffixIcon: IconButton(
                              icon: Icon(
                                controller.isConfirmPasswordVisible.value
                                    ? AppIcon.visibilityOff
                                    : AppIcon.visibility,
                              ),
                              onPressed:
                                  controller.toggleConfirmPasswordVisibility,
                            ),
                          );
                        }),
                        SizedBox(height: AppSpacing.lg.h),
                        Obx(() {
                          if (controller.errorMessage.value.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: EdgeInsets.only(bottom: AppSpacing.lg.h),
                            child: Text(
                              controller.errorMessage.value,
                              key: const Key('backup-restore-setup-error'),
                              style: AppTypography.bodyMedium.copyWith(
                                color: colors.error,
                              ),
                            ),
                          );
                        }),
                        Obx(() {
                          return AppButtonWidget(
                            key: const Key('backup-restore-setup-submit'),
                            title: 'ایجاد حساب و بازیابی',
                            isLoading: controller.isBusy.value,
                            onPressed: () => _onSubmit(controller),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onSubmit(RestoreViewModel controller) {
    if (!(controller.setupFormKey.currentState?.validate() ?? false)) {
      return;
    }
    controller.startWarningDialogCountdown();
    Get.dialog(
      barrierDismissible: false,
      Obx(() {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: Text('هشدار مهم امنیتی', style: AppTypography.headlineSmall),
            content: Text(
              'رمز اصلی، کلید حساب جدید شماست و در برنامه ذخیره نمی‌شود.\n\n'
              'رمز فایل پشتیبان جایگزین این رمز نمی‌شود.\n\n'
              'اگر رمز اصلی را فراموش کنید، هیچ راهی برای بازیابی اطلاعات وجود ندارد.',
              style: AppTypography.bodyMedium,
            ),
            actions: [
              TextButton(
                key: const Key('backup-restore-setup-warning-cancel'),
                onPressed: () => Get.back(),
                child: Text('انصراف', style: AppTypography.button),
              ),
              TextButton(
                key: const Key('backup-restore-setup-warning-confirm'),
                onPressed: controller.canConfirmDialog.value
                    ? () async {
                        final navigatorContext = Get.context;
                        Get.back();
                        if (navigatorContext == null ||
                            !navigatorContext.mounted) {
                          return;
                        }
                        await runRestoreWithProgressOverlay(
                          context: navigatorContext,
                          restore: controller,
                          action: () => controller.completeNewAccountRestore(
                            navigatorContext,
                          ),
                        );
                        if (!navigatorContext.mounted) {
                          return;
                        }
                        await controller.presentNewAccountRestoreSuccess(
                          navigatorContext,
                        );
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
