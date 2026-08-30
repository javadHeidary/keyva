import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:keyva/core/constants/security_constants.dart';
import 'package:keyva/core/theme/app_radius.dart';
import 'package:keyva/core/theme/app_spacing.dart';
import 'package:keyva/core/theme/app_typography.dart';
import 'package:keyva/core/theme/extensions/responsive_extentions.dart';
import 'package:keyva/core/theme/extensions/theme_extentions.dart';
import 'package:keyva/feature/settings/viewmodel/settings_viewmodel.dart';
import 'package:keyva/shared/widget/app_buttom_widget.dart';
import 'package:keyva/shared/widget/app_textfield_widget.dart';

enum PinCodeDialogMode { setup, change }

const pinSetupSecurityInfo = '';
Future<void> showPinCodeDialog(
  BuildContext context, {
  PinCodeDialogMode mode = PinCodeDialogMode.setup,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: context.colors.overlay,
    barrierDismissible: false,
    builder: (dialogContext) => _PinCodeDialog(mode: mode),
  );
}

class _PinCodeDialog extends StatefulWidget {
  const _PinCodeDialog({required this.mode});

  final PinCodeDialogMode mode;

  @override
  State<_PinCodeDialog> createState() => _PinCodeDialogState();
}

class _PinCodeDialogState extends State<_PinCodeDialog> {
  final _currentController = TextEditingController();
  final _pinController = TextEditingController();
  final _confirmController = TextEditingController();

  List<TextInputFormatter> get _pinFormatters => [
    FilteringTextInputFormatter.digitsOnly,
    LengthLimitingTextInputFormatter(SecurityConstants.pinMaxLength),
  ];

  @override
  void dispose() {
    _currentController.clear();
    _pinController.clear();
    _confirmController.clear();
    _currentController.dispose();
    _pinController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final controller = Get.find<SettingsViewModel>();
    final isChange = widget.mode == PinCodeDialogMode.change;

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
                isChange ? 'تغییر کد PIN' : 'تنظیم کد PIN',
                textAlign: TextAlign.center,
                style: AppTypography.titleMedium.copyWith(
                  color: colors.textPrimary,
                ),
              ),
              SizedBox(height: AppSpacing.md.h),
              Text(
                pinSetupSecurityInfo,
                key: const Key('settings-pin-security-info'),
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              SizedBox(height: AppSpacing.lg.h),
              if (isChange) ...[
                AppTextFieldWidget(
                  key: const Key('settings-pin-current'),
                  controller: _currentController,
                  labelText: 'PIN فعلی',
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  textDirection: TextDirection.ltr,
                  inputFormatters: _pinFormatters,
                ),
                SizedBox(height: AppSpacing.md.h),
              ],
              AppTextFieldWidget(
                key: const Key('settings-pin-new'),
                controller: _pinController,
                labelText: isChange ? 'PIN جدید' : 'کد PIN',
                obscureText: true,
                keyboardType: TextInputType.number,
                textDirection: TextDirection.ltr,
                inputFormatters: _pinFormatters,
              ),
              SizedBox(height: AppSpacing.md.h),
              AppTextFieldWidget(
                key: const Key('settings-pin-confirm'),
                controller: _confirmController,
                labelText: 'تکرار PIN',
                obscureText: true,
                keyboardType: TextInputType.number,
                textDirection: TextDirection.ltr,
                inputFormatters: _pinFormatters,
              ),
              SizedBox(height: AppSpacing.xl.h),
              Obx(() {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppButtonWidget(
                      key: const Key('settings-pin-save'),
                      title: 'ذخیره',
                      isLoading: controller.isSecurityBusy.value,
                      onPressed: () {
                        if (isChange) {
                          controller.onPinChanged(
                            currentPin: _currentController.text,
                            pin: _pinController.text,
                            confirmPin: _confirmController.text,
                            context: context,
                          );
                          return;
                        }
                        controller.onPinSubmitted(
                          pin: _pinController.text,
                          confirmPin: _confirmController.text,
                          context: context,
                        );
                      },
                    ),
                    SizedBox(height: AppSpacing.sm.h),
                    TextButton(
                      key: const Key('settings-pin-cancel'),
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
