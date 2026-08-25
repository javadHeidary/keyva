import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keyva/core/theme/app_radius.dart';
import 'package:keyva/core/theme/app_spacing.dart';
import 'package:keyva/core/theme/app_typography.dart';
import 'package:keyva/core/theme/extensions/responsive_extentions.dart';
import 'package:keyva/core/theme/extensions/theme_extentions.dart';
import 'package:keyva/feature/settings/viewmodel/settings_viewmodel.dart';
import 'package:keyva/shared/icons/app_icons.dart';
import 'package:keyva/shared/widget/app_buttom_widget.dart';
import 'package:keyva/shared/widget/app_textfield_widget.dart';

Future<void> showDeleteAccountDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierColor: context.colors.overlay,
    barrierDismissible: false,
    builder: (dialogContext) => const _DeleteAccountDialog(),
  );
}

class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog();

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  static const stayOpenMessage =
      'لطفاً تا پایان حذف، برنامه را نبندید و از آن خارج نشوید.';

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final controller = Get.find<SettingsViewModel>();

    return PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: colors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.modal),
        ),
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg.s),
          child: SingleChildScrollView(
            child: Obx(() {
              final busy = controller.isSecurityBusy.value;
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 64.s,
                      height: 64.s,
                      decoration: BoxDecoration(
                        color: colors.warning.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        AppIcon.warning,
                        size: 32.s,
                        color: colors.warning,
                      ),
                    ),
                  ),
                  SizedBox(height: AppSpacing.xl.h),
                  Text(
                    'حذف حساب',
                    textAlign: TextAlign.center,
                    style: AppTypography.headlineSmall.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                  SizedBox(height: AppSpacing.sm.h),
                  Text(
                    'این حساب و تمام اطلاعات گاوصندوق روی این دستگاه برای همیشه '
                    'حذف می‌شود. این کار قابل بازگشت نیست. اگر نسخه پشتیبان ندارید، '
                    'داده‌ها از بین می‌روند.',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMedium.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                  SizedBox(height: AppSpacing.lg.h),
                  AppTextFieldWidget(
                    key: const Key('settings-delete-account-password'),
                    controller: _passwordController,
                    labelText: 'رمز اصلی',
                    obscureText: true,
                    enabled: !busy,
                    textDirection: TextDirection.ltr,
                  ),
                  if (busy) ...[
                    SizedBox(height: AppSpacing.md.h),
                    Text(
                      key: const Key('settings-delete-account-stay-open'),
                      stayOpenMessage,
                      textAlign: TextAlign.center,
                      style: AppTypography.bodySmall.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                  SizedBox(height: AppSpacing.xl.h),
                  AppButtonWidget(
                    key: const Key('settings-delete-account-confirm'),
                    title: 'حذف حساب',
                    isLoading: busy,
                    backgroundColor: colors.error,
                    foregroundColor: colors.onPrimary,
                    onPressed: () => controller.onDeleteAccountConfirmed(
                      masterPassword: _passwordController.text,
                      context: context,
                    ),
                  ),
                  SizedBox(height: AppSpacing.sm.h),
                  TextButton(
                    key: const Key('settings-delete-account-cancel'),
                    onPressed: busy ? null : () => Navigator.of(context).pop(),
                    child: Text(
                      'انصراف',
                      style: AppTypography.button.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }
}
