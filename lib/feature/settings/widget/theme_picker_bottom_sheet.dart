import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keyva/core/theme/app_radius.dart';
import 'package:keyva/core/theme/app_spacing.dart';
import 'package:keyva/core/theme/app_typography.dart';
import 'package:keyva/core/theme/extensions/responsive_extentions.dart';
import 'package:keyva/core/theme/extensions/theme_extentions.dart';
import 'package:keyva/feature/settings/model/theme_preference.dart';
import 'package:keyva/feature/settings/viewmodel/settings_viewmodel.dart';

Future<void> showThemePickerBottomSheet(BuildContext context) {
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
                'انتخاب پوسته',
                textAlign: TextAlign.center,
                style: AppTypography.titleMedium.copyWith(
                  color: colors.textPrimary,
                ),
              ),
              SizedBox(height: AppSpacing.lg.h),
              for (final mode in ThemePreference.values) ...[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    mode.label,
                    style: AppTypography.bodyMedium.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                  trailing: controller.themePreference.value == mode
                      ? Icon(Icons.check_rounded, color: colors.primary)
                      : null,
                  onTap: () {
                    controller.setThemePreference(mode);
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
