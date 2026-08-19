import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keyva/core/theme/app_radius.dart';
import 'package:keyva/core/theme/app_spacing.dart';
import 'package:keyva/core/theme/app_typography.dart';
import 'package:keyva/core/theme/extensions/responsive_extentions.dart';
import 'package:keyva/core/theme/extensions/theme_extentions.dart';
import 'package:keyva/feature/backup/viewmodel/restore_viewmodel.dart';
import 'package:keyva/shared/widget/app_buttom_widget.dart';
import 'package:keyva/shared/widget/app_textfield_widget.dart';

Future<void> showRestoreBackupPasswordDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierColor: context.colors.overlay,
    builder: (dialogContext) => const _RestoreBackupPasswordDialog(),
  );
}

class _RestoreBackupPasswordDialog extends StatefulWidget {
  const _RestoreBackupPasswordDialog();

  @override
  State<_RestoreBackupPasswordDialog> createState() =>
      _RestoreBackupPasswordDialogState();
}

class _RestoreBackupPasswordDialogState
    extends State<_RestoreBackupPasswordDialog> {
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final controller = Get.find<RestoreViewModel>();

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
                'رمز فایل پشتیبان',
                textAlign: TextAlign.center,
                style: AppTypography.titleMedium.copyWith(
                  color: colors.textPrimary,
                ),
              ),
              SizedBox(height: AppSpacing.lg.h),
              AppTextFieldWidget(
                key: const Key('backup-restore-password'),
                controller: _passwordController,
                labelText: 'رمز عبور فایل پشتیبان',
                obscureText: true,
                textDirection: TextDirection.ltr,
              ),
              SizedBox(height: AppSpacing.xl.h),
              Obx(() {
                return AppButtonWidget(
                  key: const Key('backup-restore-submit'),
                  title: 'ادامه',
                  isLoading: controller.isBusy.value,
                  onPressed: () async {
                    final preview = await controller.decryptSelectedBackup(
                      password: _passwordController.text,
                      context: context,
                    );
                    if (preview == null || !context.mounted) {
                      return;
                    }
                    Navigator.of(context).pop();
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
