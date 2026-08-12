import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keyva/core/theme/app_radius.dart';
import 'package:keyva/core/theme/app_sizes.dart';
import 'package:keyva/core/theme/app_spacing.dart';
import 'package:keyva/core/theme/app_typography.dart';
import 'package:keyva/core/theme/extensions/responsive_extentions.dart';
import 'package:keyva/core/theme/extensions/theme_extentions.dart';
import 'package:keyva/feature/password_generator/model/password_generator_settings.dart';
import 'package:keyva/feature/password_generator/viewmodel/password_generator_viewmodel.dart';
import 'package:keyva/shared/icons/app_icons.dart';
import 'package:keyva/shared/widget/app_buttom_widget.dart';
import 'package:keyva/shared/widget/app_header_widget.dart';
import 'package:keyva/shared/widget/app_title_item_widget.dart';
import 'package:keyva/shared/widget/login_section_card_widget.dart';
import 'package:keyva/shared/widget/password_strengthbar_widget.dart';
import 'package:keyva/shared/widget/toggle_item_widget.dart';

class PasswordGeneratorView extends GetView<PasswordGeneratorViewModel> {
  const PasswordGeneratorView({super.key, this.embeddedInShell = false});

  final bool embeddedInShell;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.pageBackground,
      body: SafeArea(
        child: Obx(() {
          controller.generatedPassword.value;
          controller.strength.value;
          controller.settingsRx.value;
          final settings = controller.settings;

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: AppHeaderWidget(
                  title: 'تولید رمز عبور',
                  titleAlign: TextAlign.center,
                  leading: embeddedInShell
                      ? null
                      : Icon(
                          AppIcon.arrowBack,
                          size: AppSizes.iconMd.s,
                          color: colors.textPrimary,
                        ),
                  onLeadingTap: embeddedInShell ? null : Get.back,
                  trailingActions: [
                    AppHeaderTrailingAction(
                      child: Icon(
                        AppIcon.history,
                        size: AppSizes.iconLg.s,
                        color: colors.textPrimary,
                      ),
                      onTap: controller.openHistoryMenu,
                    ),
                  ],
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.pagePadding.s,
                  AppSpacing.sm.h,
                  AppSpacing.pagePadding.s,
                  AppSpacing.hugePlus.h,
                ),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppSectionCardWidget(
                        padding: EdgeInsets.all(AppSpacing.lg.s),
                        children: [
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(AppSpacing.lg.s),
                            decoration: BoxDecoration(
                              color: colors.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(
                                AppRadius.medium,
                              ),
                              border: Border.all(
                                color: colors.primary.withValues(alpha: 0.25),
                                width: 1,
                              ),
                            ),
                            child: SelectableText(
                              controller.generatedPassword.value.isEmpty
                                  ? '—'
                                  : controller.generatedPassword.value,
                              textAlign: TextAlign.center,
                              style: AppTypography.titleLarge.copyWith(
                                color: colors.primary,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                          SizedBox(height: AppSpacing.md.h),
                          Row(
                            children: [
                              Expanded(
                                child: AppButtonWidget(
                                  title: 'کپی',
                                  icon: Icon(
                                    AppIcon.copy,
                                    size: AppSizes.iconMd.s,
                                  ),
                                  onPressed: () =>
                                      controller.copyPassword(context),
                                ),
                              ),
                              SizedBox(width: AppSpacing.md.s),
                              Expanded(
                                child: AppButtonWidget(
                                  title: 'تولید مجدد',
                                  icon: Icon(
                                    AppIcon.refresh,
                                    size: AppSizes.iconMd.s,
                                  ),
                                  backgroundColor: colors.primary.withValues(
                                    alpha: 0.12,
                                  ),
                                  foregroundColor: colors.primary,
                                  onPressed: controller.regenerate,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: AppSpacing.sectionGap.h),
                      Row(
                        children: [
                          Text(
                            'قدرت امنیتی',
                            style: AppTypography.labelMedium.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            AppIcon.shield,
                            size: AppSizes.iconMd.s,
                            color: controller.strengthColor(context),
                          ),
                          SizedBox(width: AppSpacing.xs.s),
                          Text(
                            '${controller.strengthLabel} • ${controller.strengthPercent}%',
                            style: AppTypography.labelMedium.copyWith(
                              color: controller.strengthColor(context),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: AppSpacing.sm.h),
                      PasswordStrengthBarWidget(
                        strength: controller.strength.value,
                        showLabel: false,
                      ),
                      SizedBox(height: AppSpacing.sectionGap.h),
                      const AppTitleItemWidget(title: 'سفارشی‌سازی'),
                      AppSectionCardWidget(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'طول رمز عبور',
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: colors.textPrimary,
                                  ),
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm.s,
                                  vertical: AppSpacing.xxs.s,
                                ),
                                decoration: BoxDecoration(
                                  color: colors.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.button,
                                  ),
                                ),
                                child: Text(
                                  '${settings.length}',
                                  style: AppTypography.labelMedium.copyWith(
                                    color: colors.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Slider(
                            value: settings.length.toDouble(),
                            min: PasswordGeneratorSettings.minLength.toDouble(),
                            max: PasswordGeneratorSettings.maxLength.toDouble(),
                            divisions:
                                PasswordGeneratorSettings.maxLength -
                                PasswordGeneratorSettings.minLength,
                            activeColor: colors.primary,
                            inactiveColor: colors.textSecondary,
                            onChanged: controller.setLength,
                          ),
                          SizedBox(height: AppSpacing.md.h),
                          ToggleItemWidget(
                            title: 'حروف بزرگ (A-Z)',
                            subtitle: 'شامل حروف بزرگ انگلیسی',
                            value: settings.uppercase,
                            onChanged: controller.toggleUppercase,
                          ),
                          SizedBox(height: AppSpacing.sm.h),
                          ToggleItemWidget(
                            title: 'حروف کوچک (a-z)',
                            subtitle: 'شامل حروف کوچک انگلیسی',
                            value: settings.lowercase,
                            onChanged: controller.toggleLowercase,
                          ),
                          SizedBox(height: AppSpacing.sm.h),
                          ToggleItemWidget(
                            title: 'اعداد (0-9)',
                            subtitle: 'شامل ارقام',
                            value: settings.numbers,
                            onChanged: controller.toggleNumbers,
                          ),
                          SizedBox(height: AppSpacing.sm.h),
                          ToggleItemWidget(
                            title: 'نمادها (@#\$%!)',
                            subtitle: 'شامل کاراکترهای خاص',
                            value: settings.symbols,
                            onChanged: controller.toggleSymbols,
                          ),
                          SizedBox(height: AppSpacing.sm.h),
                          ToggleItemWidget(
                            title: 'حذف کاراکترهای مشابه',
                            subtitle: 'I l 1 O 0',
                            titleColor: colors.warning,
                            value: settings.excludeSimilar,
                            onChanged: controller.toggleExcludeSimilar,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
