import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keyva/core/theme/app_radius.dart';
import 'package:keyva/core/theme/app_spacing.dart';
import 'package:keyva/core/theme/app_typography.dart';
import 'package:keyva/core/theme/extensions/responsive_extentions.dart';
import 'package:keyva/core/theme/extensions/theme_extentions.dart';
import 'package:keyva/feature/settings/model/user_profile.dart';
import 'package:keyva/feature/settings/viewmodel/settings_viewmodel.dart';
import 'package:keyva/shared/widget/app_buttom_widget.dart';
import 'package:keyva/shared/widget/app_textfield_widget.dart';

Future<void> showAccountEditBottomSheet(BuildContext context) {
  final controller = Get.find<SettingsViewModel>();
  final nameController = TextEditingController(text: controller.profile.value.name);

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.colors.card,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppRadius.modal),
      ),
    ),
    builder: (sheetContext) {
      final colors = sheetContext.colors;

      return Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.lg.s,
          right: AppSpacing.lg.s,
          top: AppSpacing.lg.s,
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom + AppSpacing.lg.s,
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'ویرایش حساب',
                textAlign: TextAlign.center,
                style: AppTypography.titleMedium.copyWith(
                  color: colors.textPrimary,
                ),
              ),
              SizedBox(height: AppSpacing.lg.h),
              AppTextFieldWidget(
                controller: nameController,
                labelText: 'نام حساب',
                textDirection: TextDirection.rtl,
              ),
              SizedBox(height: AppSpacing.xl.h),
              AppButtonWidget(
                title: 'ذخیره',
                onPressed: () async {
                  final name = nameController.text.trim();
                  if (name.isEmpty) return;
                  final saved = await controller.updateProfile(
                    UserProfile(name: name),
                  );
                  if (saved && sheetContext.mounted) {
                    Navigator.of(sheetContext).pop();
                  }
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}
