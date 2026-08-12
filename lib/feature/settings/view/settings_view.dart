import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keyva/core/theme/app_spacing.dart';
import 'package:keyva/core/theme/extensions/responsive_extentions.dart';
import 'package:keyva/core/theme/extensions/theme_extentions.dart';
import 'package:keyva/feature/settings/model/app_info.dart';
import 'package:keyva/feature/settings/util/settings_avatar_icons.dart';
import 'package:keyva/feature/settings/viewmodel/settings_viewmodel.dart';
import 'package:keyva/feature/settings/widget/account_edit_bottom_sheet.dart';
import 'package:keyva/feature/settings/widget/backup_restore_dialog.dart';
import 'package:keyva/feature/settings/widget/change_master_password_dialog.dart';
import 'package:keyva/feature/settings/widget/faq_guide_bottom_sheet.dart';
import 'package:keyva/feature/settings/widget/pin_code_dialog.dart';
import 'package:keyva/feature/settings/widget/settings_group_card.dart';
import 'package:keyva/feature/settings/widget/settings_row.dart';
import 'package:keyva/feature/settings/widget/theme_picker_bottom_sheet.dart';
import 'package:keyva/shared/icons/app_icons.dart';
import 'package:keyva/shared/widget/app_buttom_widget.dart';
import 'package:keyva/shared/widget/app_dialog_widget.dart';
import 'package:keyva/shared/widget/app_header_widget.dart';
import 'package:keyva/shared/widget/app_title_item_widget.dart';
import 'package:keyva/shared/widget/user_info_widger.dart';

class SettingsView extends GetView<SettingsViewModel> {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.pageBackground,
      body: SafeArea(
        child: Obx(() {
          controller.profile.value;
          controller.themePreference.value;
          controller.security.value;
          controller.showBiometricSetting.value;

          return CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(
                child: AppHeaderWidget(
                  title: 'تنظیمات',
                  titleAlign: TextAlign.center,
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
                      Obx(() {
                        final profile = controller.profile.value;
                        return UserInfoWidget(
                          name: profile.name,
                          avatar: Container(
                            color: colors.input,
                            child: SettingsAvatarIcons.avatarWidget(
                              profile.avatarId,
                              color: colors.primary,
                            ),
                          ),
                          onEdit: () => showAccountEditBottomSheet(context),
                        );
                      }),
                      SizedBox(height: AppSpacing.sectionGap.h),
                      const AppTitleItemWidget(title: 'امنیت'),
                      SettingsGroupCard(
                        children: [
                          SettingsRow.nav(
                            title: 'تغییر رمز اصلی',
                            icon: AppIcon.masterPassword,
                            onTap: () =>
                                showChangeMasterPasswordDialog(context),
                          ),
                          if (controller.showBiometricSetting.value)
                            SettingsRow.toggle(
                              title: 'احراز هویت بیومتریک',
                              icon: AppIcon.fingerprint,
                              value: controller.security.value.biometricEnabled,
                              onChanged: controller.setBiometricEnabled,
                            ),
                          SettingsRow.toggle(
                            title: 'کد PIN',
                            icon: AppIcon.pin,
                            value: controller.security.value.pinEnabled,
                            onChanged: (enabled) {
                              controller.onPinToggle(enabled, context);
                              if (enabled) {
                                showPinCodeDialog(context);
                              }
                            },
                          ),
                          SettingsRow.toggle(
                            title: 'جلوگیری از اسکرین‌شات و ضبط صفحه',
                            icon: AppIcon.noPhotography,
                            value: controller.security.value.preventScreenshot,
                            onChanged: controller.setPreventScreenshot,
                          ),
                          SettingsRow.toggle(
                            title: 'قفل هنگام خروج از برنامه',
                            icon: AppIcon.logout,
                            value: controller.security.value.lockOnAppExit,
                            onChanged: controller.setLockOnAppExit,
                          ),
                        ],
                      ),
                      SizedBox(height: AppSpacing.sectionGap.h),
                      const AppTitleItemWidget(title: 'ظاهر'),
                      SettingsGroupCard(
                        children: [
                          SettingsRow.nav(
                            title: 'پوسته',
                            icon: AppIcon.palette,
                            subtitle: controller.themePreference.value.label,
                            onTap: () => showThemePickerBottomSheet(context),
                          ),
                        ],
                      ),
                      SizedBox(height: AppSpacing.sectionGap.h),
                      const AppTitleItemWidget(title: 'پشتیبان‌گیری'),
                      SettingsGroupCard(
                        children: [
                          SettingsRow.nav(
                            title: 'پشتیبان‌گیری و بازیابی',
                            icon: AppIcon.backup,
                            onTap: () => showBackupRestoreDialog(context),
                          ),
                        ],
                      ),
                      SizedBox(height: AppSpacing.sectionGap.h),
                      const AppTitleItemWidget(title: 'اطلاعات'),
                      SettingsGroupCard(
                        children: [
                          SettingsRow.nav(
                            title: 'سیاست حریم خصوصی',
                            icon: AppIcon.privacy,
                            onTap: () => _showInfo(
                              context,
                              'سیاست حریم خصوصی',
                              'متن سیاست حریم خصوصی در فاز بعد از طریق لینک یا '
                                  'محتوای محلی نمایش داده می‌شود. داده‌های شما روی '
                                  'دستگاه شما می‌ماند.',
                            ),
                          ),
                          SettingsRow.nav(
                            title: 'درباره ما',
                            icon: AppIcon.users,
                            onTap: () => _showInfo(
                              context,
                              'درباره کیوا',
                              'کیوا یک گاوصندوق شخصی آفلاین برای نگهداری امن '
                                  'اطلاعات حساس است.',
                            ),
                          ),
                          SettingsRow.nav(
                            title: 'تماس با ما',
                            icon: AppIcon.mail,
                            onTap: () => _showInfo(
                              context,
                              'تماس با ما',
                              'راه‌های تماس در نسخه نهایی از طریق ایمیل یا '
                                  'وب‌سایت در دسترس خواهد بود.',
                            ),
                          ),
                          SettingsRow.nav(
                            title: 'سوالات متداول و راهنما',
                            icon: AppIcon.help,
                            onTap: () => showFaqGuideBottomSheet(context),
                          ),
                          SettingsRow.nav(
                            title: 'نقد و پیشنهادات',
                            icon: AppIcon.messageSquare,
                            onTap: () => controller.openFeedback(context),
                          ),
                          SettingsRow.value(
                            title: 'نسخه برنامه',
                            icon: AppIcon.verifiedUser,
                            trailingValue: AppInfo.displayVersion,
                          ),
                        ],
                      ),
                      SizedBox(height: AppSpacing.sectionGap.h),
                      const AppTitleItemWidget(title: 'حمایت از ما'),
                      SettingsGroupCard(
                        children: [
                          SettingsRow.nav(
                            title: 'اپلیکیشن‌های دیگر ما',
                            icon: AppIcon.apps,
                            onTap: () => controller.onOpenOtherApps(context),
                          ),
                          SettingsRow.nav(
                            title: 'امتیاز به ما',
                            icon: AppIcon.star,
                            onTap: () => controller.onRateApp(context),
                          ),
                          SettingsRow.nav(
                            title: 'اشتراک‌گذاری با دوستان',
                            icon: AppIcon.share,
                            onTap: () => controller.onShareApp(context),
                          ),
                        ],
                      ),
                      SizedBox(height: AppSpacing.sectionGap.h),
                      AppButtonWidget(
                        title: 'خروج از حساب',
                        backgroundColor: colors.error.withValues(alpha: 0.12),
                        foregroundColor: colors.error,
                        onPressed: () => _confirmLogout(context),
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

  void _showInfo(BuildContext context, String title, String description) {
    AppDialogWidget.show(context, title: title, description: description);
  }

  void _confirmLogout(BuildContext context) {
    AppDialogWidget.show(
      context,
      type: AppDialogType.warning,
      title: 'خروج از حساب',
      description:
          'با خروج، فقط دسترسی فعلی پایان می‌یابد. داده‌های رمزنگاری‌شده '
          'روی دستگاه باقی می‌مانند.',
      buttonText: 'خروج',
      onConfirm: controller.onLogoutConfirmed,
    );
  }
}
