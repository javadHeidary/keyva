import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keyva/core/security/auto_lock_policy.dart';
import 'package:keyva/core/theme/app_radius.dart';
import 'package:keyva/core/theme/app_spacing.dart';
import 'package:keyva/core/theme/app_typography.dart';
import 'package:keyva/core/theme/extensions/responsive_extentions.dart';
import 'package:keyva/core/theme/extensions/theme_extentions.dart';
import 'package:keyva/feature/settings/viewmodel/settings_viewmodel.dart';

Future<void> showAutoLockTimeoutBottomSheet(BuildContext context) {
  final controller = Get.find<SettingsViewModel>();

  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: context.colors.card,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppRadius.modal),
      ),
    ),
    builder: (sheetContext) {
      final colors = sheetContext.colors;

      return SafeArea(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg.s),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'قفل خودکار',
                textAlign: TextAlign.center,
                style: AppTypography.titleMedium.copyWith(
                  color: colors.textPrimary,
                ),
              ),
              SizedBox(height: AppSpacing.lg.h),
              for (final timeout in AutoLockPolicy.values) ...[
                ListTile(
                  key: Key('settings-auto-lock-option-${timeout.inSeconds}'),
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    AutoLockPolicy.label(timeout),
                    style: AppTypography.bodyMedium.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                  trailing: controller.security.value.autoLockTimeout == timeout
                      ? Icon(Icons.check_rounded, color: colors.primary)
                      : null,
                  onTap: () {
                    controller.setAutoLockTimeout(timeout);
                    Navigator.of(sheetContext).pop();
                  },
                ),
              ],
            ],
          ),
        ),
      );
    },
  );
}
