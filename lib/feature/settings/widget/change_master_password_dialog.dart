import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keyva/core/theme/app_radius.dart';
import 'package:keyva/core/theme/app_spacing.dart';
import 'package:keyva/core/theme/app_typography.dart';
import 'package:keyva/core/theme/extensions/responsive_extentions.dart';
import 'package:keyva/core/theme/extensions/theme_extentions.dart';
import 'package:keyva/feature/settings/viewmodel/settings_viewmodel.dart';
import 'package:keyva/shared/widget/app_buttom_widget.dart';
import 'package:keyva/shared/widget/app_textfield_widget.dart';

Future<void> showChangeMasterPasswordDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierColor: context.colors.overlay,
    barrierDismissible: false,
    builder: (dialogContext) => const _ChangeMasterPasswordDialog(),
  );
}

class _ChangeMasterPasswordDialog extends StatefulWidget {
  const _ChangeMasterPasswordDialog();

  @override
  State<_ChangeMasterPasswordDialog> createState() =>
      _ChangeMasterPasswordDialogState();
}

class _ChangeMasterPasswordDialogState
    extends State<_ChangeMasterPasswordDialog> {
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final controller = Get.find<SettingsViewModel>();

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
                'تغییر رمز اصلی',
                textAlign: TextAlign.center,
                style: AppTypography.titleMedium.copyWith(
                  color: colors.textPrimary,
                ),
              ),
              SizedBox(height: AppSpacing.lg.h),
              AppTextFieldWidget(
                key: const Key('settings-change-mp-current'),
                controller: _currentController,
                labelText: 'رمز اصلی فعلی',
                obscureText: true,
                textDirection: TextDirection.ltr,
              ),
              SizedBox(height: AppSpacing.md.h),
              AppTextFieldWidget(
                key: const Key('settings-change-mp-new'),
                controller: _newController,
                labelText: 'رمز اصلی جدید',
                obscureText: true,
                textDirection: TextDirection.ltr,
              ),
              SizedBox(height: AppSpacing.md.h),
              AppTextFieldWidget(
                key: const Key('settings-change-mp-confirm'),
                controller: _confirmController,
                labelText: 'تکرار رمز جدید',
                obscureText: true,
                textDirection: TextDirection.ltr,
              ),
              SizedBox(height: AppSpacing.xl.h),
              Obx(() {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppButtonWidget(
                      key: const Key('settings-change-mp-submit'),
                      title: 'تأیید',
                      isLoading: controller.isSecurityBusy.value,
                      onPressed: () => controller.onChangeMasterPasswordSubmitted(
                        currentPassword: _currentController.text,
                        newPassword: _newController.text,
                        confirmPassword: _confirmController.text,
                        context: context,
                      ),
                    ),
                    SizedBox(height: AppSpacing.sm.h),
                    TextButton(
                      key: const Key('settings-change-mp-cancel'),
                      onPressed: controller.isSecurityBusy.value
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
