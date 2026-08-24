import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keyva/core/theme/app_radius.dart';
import 'package:keyva/core/theme/app_sizes.dart';
import 'package:keyva/core/theme/app_spacing.dart';
import 'package:keyva/core/theme/app_typography.dart';
import 'package:keyva/core/theme/extensions/responsive_extentions.dart';
import 'package:keyva/core/theme/extensions/theme_extentions.dart';
import 'package:keyva/shared/icons/app_icons.dart';
import 'package:keyva/shared/widget/app_buttom_widget.dart';

Future<void> showAuthCountdownWarningDialog({
  required RxInt countdown,
  required RxBool canConfirm,
  required VoidCallback onConfirm,
}) {
  return Get.dialog(
    barrierDismissible: false,
    Obx(() {
      final canSubmit = canConfirm.value;
      return Builder(
        builder: (context) {
          final colors = context.colors;
          return Directionality(
            textDirection: TextDirection.rtl,
            child: Dialog(
              backgroundColor: colors.card,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.modal.s),
              ),
              insetPadding: EdgeInsets.symmetric(horizontal: AppSpacing.xxl.s),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.xl.s,
                  AppSpacing.xxl.s,
                  AppSpacing.xl.s,
                  AppSpacing.xl.s,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: AppSizes.itemHeight.s,
                      height: AppSizes.itemHeight.s,
                      decoration: BoxDecoration(
                        color: colors.warning.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        AppIcon.warning,
                        size: AppSizes.iconXl.s,
                        color: colors.warning,
                      ),
                    ),
                    SizedBox(height: AppSpacing.xl.h),
                    Text(
                      'هشدار مهم امنیتی',
                      textAlign: TextAlign.center,
                      style: AppTypography.headlineSmall.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                    SizedBox(height: AppSpacing.sm.h),
                    Text(
                      'رمز اصلی، کلید حساب شماست و در برنامه ذخیره نمی‌شود.\n\n'
                      'اگر این رمز را فراموش کنید، هیچ راهی برای بازیابی اطلاعات وجود ندارد.\n\n'
                      'لطفاً آن را در جایی امن نگه دارید.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyMedium.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                    SizedBox(height: AppSpacing.xxl.h),
                    AppButtonWidget(
                      key: const Key('auth-register-warning-confirm'),
                      title: canSubmit
                          ? 'متوجه شدم و ادامه می‌دهم'
                          : 'متوجه شدم (${countdown.value})',
                      textStyle: AppTypography.withFaNum(AppTypography.button),
                      enabled: canSubmit,
                      onPressed: canSubmit
                          ? () {
                              Get.back();
                              onConfirm();
                            }
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }),
  );
}
