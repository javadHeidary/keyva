import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keyva/core/theme/app_radius.dart';
import 'package:keyva/core/theme/app_sizes.dart';
import 'package:keyva/core/theme/app_spacing.dart';
import 'package:keyva/core/theme/app_typography.dart';
import 'package:keyva/core/theme/extensions/responsive_extentions.dart';
import 'package:keyva/core/theme/extensions/theme_extentions.dart';
import 'package:keyva/feature/settings/model/user_profile.dart';
import 'package:keyva/feature/settings/util/settings_avatar_icons.dart';
import 'package:keyva/feature/settings/viewmodel/settings_viewmodel.dart';
import 'package:keyva/shared/widget/app_buttom_widget.dart';
import 'package:keyva/shared/widget/app_textfield_widget.dart';

Future<void> showAccountEditBottomSheet(BuildContext context) {
  final controller = Get.find<SettingsViewModel>();
  final nameController = TextEditingController(text: controller.profile.value.name);
  final selectedAvatarId = controller.profile.value.avatarId.obs;

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
              SizedBox(height: AppSpacing.lg.h),
              Text(
                'آیکون حساب',
                style: AppTypography.labelLarge.copyWith(
                  color: colors.textPrimary,
                ),
              ),
              SizedBox(height: AppSpacing.sm.h),
              Obx(() {
                return Wrap(
                  spacing: AppSpacing.sm.s,
                  runSpacing: AppSpacing.sm.s,
                  children: [
                    for (final preset in UserProfileAvatars.presets)
                      _AvatarChip(
                        selected: selectedAvatarId.value == preset.id,
                        icon: SettingsAvatarIcons.iconForId(preset.id),
                        onTap: () => selectedAvatarId.value = preset.id,
                      ),
                  ],
                );
              }),
              SizedBox(height: AppSpacing.xl.h),
              AppButtonWidget(
                title: 'ذخیره',
                onPressed: () {
                  final name = nameController.text.trim();
                  if (name.isEmpty) return;
                  controller.updateProfile(
                    controller.profile.value.copyWith(
                      name: name,
                      avatarId: selectedAvatarId.value,
                    ),
                  );
                  Navigator.of(sheetContext).pop();
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _AvatarChip extends StatelessWidget {
  const _AvatarChip({
    required this.selected,
    required this.icon,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Material(
      color: selected
          ? colors.primary.withValues(alpha: 0.12)
          : colors.input,
      borderRadius: BorderRadius.circular(AppRadius.medium),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        child: SizedBox(
          width: 48.s,
          height: 48.s,
          child: Icon(
            icon,
            size: AppSizes.iconLg.s,
            color: selected ? colors.primary : colors.textSecondary,
          ),
        ),
      ),
    );
  }
}
