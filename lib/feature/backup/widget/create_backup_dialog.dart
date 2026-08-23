import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keyva/core/theme/app_radius.dart';
import 'package:keyva/core/theme/app_spacing.dart';
import 'package:keyva/core/theme/app_typography.dart';
import 'package:keyva/core/theme/extensions/responsive_extentions.dart';
import 'package:keyva/core/theme/extensions/theme_extentions.dart';
import 'package:keyva/feature/backup/viewmodel/backup_viewmodel.dart';
import 'package:keyva/shared/widget/app_buttom_widget.dart';
import 'package:keyva/shared/widget/app_textfield_widget.dart';

Future<void> showCreateBackupDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierColor: context.colors.overlay,
    barrierDismissible: false,
    builder: (dialogContext) => const _CreateBackupDialog(),
  );
}

class _CreateBackupDialog extends StatefulWidget {
  const _CreateBackupDialog();

  @override
  State<_CreateBackupDialog> createState() => _CreateBackupDialogState();
}

class _CreateBackupDialogState extends State<_CreateBackupDialog> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final controller = Get.find<BackupViewModel>();

    return Dialog(
      backgroundColor: colors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.modal),
      ),
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.lg.s),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'ایجاد پشتیبان',
                textAlign: TextAlign.center,
                style: AppTypography.titleMedium.copyWith(
                  color: colors.textPrimary,
                ),
              ),
              SizedBox(height: AppSpacing.md.h),
              Text(
                'یک رمز عبور جدا برای فایل پشتیبان انتخاب کنید. این رمز با رمز اصلی یکی نیست.',
                textAlign: TextAlign.right,
                style: AppTypography.bodySmall.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              SizedBox(height: AppSpacing.lg.h),
              AppTextFieldWidget(
                key: const Key('backup-create-password'),
                controller: _passwordController,
                labelText: 'رمز عبور فایل پشتیبان',
                obscureText: true,
                textDirection: TextDirection.ltr,
              ),
              SizedBox(height: AppSpacing.md.h),
              AppTextFieldWidget(
                key: const Key('backup-create-confirm'),
                controller: _confirmController,
                labelText: 'تکرار رمز عبور',
                obscureText: true,
                textDirection: TextDirection.ltr,
              ),
              SizedBox(height: AppSpacing.xl.h),
              Obx(() {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppButtonWidget(
                      key: const Key('backup-create-submit'),
                      title: 'ایجاد و ذخیره',
                      isLoading: controller.isBusy.value,
                      onPressed: () => controller.createBackup(
                        password: _passwordController.text,
                        confirmPassword: _confirmController.text,
                        context: context,
                      ),
                    ),
                    SizedBox(height: AppSpacing.sm.h),
                    TextButton(
                      key: const Key('backup-create-cancel'),
                      onPressed: controller.isBusy.value
                          ? null
                          : () => Navigator.of(context).pop(),
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
            ],
          ),
        ),
      ),
    );
  }
}
