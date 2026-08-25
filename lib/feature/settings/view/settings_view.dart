import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keyva/core/routes/app_routing.dart';
import 'package:keyva/core/security/auto_lock_policy.dart';
import 'package:keyva/core/theme/app_spacing.dart';
import 'package:keyva/core/theme/extensions/responsive_extentions.dart';
import 'package:keyva/core/theme/extensions/theme_extentions.dart';
import 'package:keyva/feature/settings/model/app_info.dart';
import 'package:keyva/feature/settings/model/support_us_content.dart';
import 'package:keyva/feature/settings/viewmodel/settings_viewmodel.dart';
import 'package:keyva/feature/settings/widget/account_edit_bottom_sheet.dart';
import 'package:keyva/feature/settings/widget/auto_lock_timeout_bottom_sheet.dart';
import 'package:keyva/feature/settings/widget/change_master_password_dialog.dart';
import 'package:keyva/feature/settings/widget/contact_us_bottom_sheet.dart';
import 'package:keyva/feature/settings/widget/delete_account_dialog.dart';
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
                          onEdit: () => showAccountEditBottomSheet(context),
                        );
                      }),
                      SizedBox(height: AppSpacing.sectionGap.h),
                      const AppTitleItemWidget(title: 'امنیت'),
                      SettingsGroupCard(
                        children: [
                          KeyedSubtree(
                            key: const Key('settings-lock'),
                            child: SettingsRow.nav(
                              title: 'قفل کردن',
                              icon: AppIcon.lock,
                              onTap: controller.lock,
                            ),
                          ),
                          KeyedSubtree(
                            key: const Key('settings-change-master-password'),
                            child: SettingsRow.nav(
                              title: 'تغییر رمز اصلی',
                              icon: AppIcon.masterPassword,
                              onTap: () =>
                                  showChangeMasterPasswordDialog(context),
                            ),
                          ),
                          if (controller.showBiometricSetting.value)
                            KeyedSubtree(
                              key: const Key('settings-biometric-toggle'),
                              child: SettingsRow.toggle(
                                title: 'ورود با اثرانگشت',
                                icon: AppIcon.fingerprint,
                                value:
                                    controller.security.value.biometricEnabled,
                                onChanged: (enabled) {
                                  if (enabled) {
                                    controller.onBiometricToggle(true, context);
                                    return;
                                  }
                                  _confirmDisableBiometric(context);
                                },
                              ),
                            ),
                          KeyedSubtree(
                            key: const Key('settings-pin-toggle'),
                            child: SettingsRow.toggle(
                              title: 'کد PIN',
                              icon: AppIcon.pin,
                              value: controller.security.value.pinEnabled,
                              onChanged: (enabled) {
                                if (enabled) {
                                  showPinCodeDialog(context);
                                  return;
                                }
                                _confirmDisablePin(context);
                              },
                            ),
                          ),
                          if (controller.security.value.pinEnabled)
                            KeyedSubtree(
                              key: const Key('settings-change-pin'),
                              child: SettingsRow.nav(
                                title: 'تغییر PIN',
                                icon: AppIcon.pin,
                                onTap: () => showPinCodeDialog(
                                  context,
                                  mode: PinCodeDialogMode.change,
                                ),
                              ),
                            ),
                          KeyedSubtree(
                            key: const Key('settings-prevent-screenshot'),
                            child: SettingsRow.toggle(
                              title: 'جلوگیری از اسکرین شات',
                              icon: AppIcon.noPhotography,
                              value:
                                  controller.security.value.preventScreenshot,
                              onChanged: (enabled) => controller
                                  .setPreventScreenshot(enabled, context),
                            ),
                          ),
                          KeyedSubtree(
                            key: const Key('settings-auto-lock'),
                            child: SettingsRow.nav(
                              title: 'قفل خودکار',
                              icon: AppIcon.lockClock,
                              subtitle: AutoLockPolicy.label(
                                controller.security.value.autoLockTimeout,
                              ),
                              onTap: () =>
                                  showAutoLockTimeoutBottomSheet(context),
                            ),
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
                          KeyedSubtree(
                            key: const Key('settings-backup-restore'),
                            child: SettingsRow.nav(
                              title: 'پشتیبان‌گیری و بازیابی',
                              icon: AppIcon.backup,
                              onTap: () => Get.toNamed(AppRoutes.backupRestore),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: AppSpacing.sectionGap.h),
                      const AppTitleItemWidget(title: 'اطلاعات'),
                      SettingsGroupCard(
                        children: [
                          KeyedSubtree(
                            key: const Key('settings-privacy-policy'),
                            child: SettingsRow.nav(
                              title: 'سیاست حریم خصوصی',
                              icon: AppIcon.privacy,
                              onTap: () => Get.toNamed(AppRoutes.privacyPolicy),
                            ),
                          ),
                          KeyedSubtree(
                            key: const Key('settings-about'),
                            child: SettingsRow.nav(
                              title: 'درباره ما',
                              icon: AppIcon.users,
                              onTap: () => Get.toNamed(AppRoutes.about),
                            ),
                          ),
                          KeyedSubtree(
                            key: const Key('settings-contact'),
                            child: SettingsRow.nav(
                              title: 'تماس با ما',
                              icon: AppIcon.mail,
                              onTap: () => showContactUsBottomSheet(context),
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
                            title: SupportUsContent.rateTitle,
                            icon: AppIcon.star,
                            onTap: () => controller.onRateApp(context),
                          ),
                          SettingsRow.nav(
                            title: SupportUsContent.otherAppsTitle,
                            icon: AppIcon.apps,
                            onTap: () => controller.onOpenOtherApps(context),
                          ),
                          SettingsRow.nav(
                            title: SupportUsContent.shareTitle,
                            icon: AppIcon.share,
                            onTap: () => controller.onShareApp(context),
                          ),
                        ],
                      ),

                      SizedBox(height: AppSpacing.sectionGap.h),
                      AppButtonWidget(
                        key: const Key('settings-delete-account'),
                        title: 'حذف حساب',
                        backgroundColor: colors.error.withValues(alpha: 0.12),
                        foregroundColor: colors.error,
                        onPressed: () => showDeleteAccountDialog(context),
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

  void _confirmDisablePin(BuildContext context) {
    AppDialogWidget.show(
      context,
      type: AppDialogType.warning,
      title: 'غیرفعال کردن PIN',
      description: 'ورود با کد PIN روی این دستگاه غیرفعال می‌شود.',
      buttonText: 'غیرفعال کردن',
      onConfirm: () => controller.disablePin(context),
    );
  }

  void _confirmDisableBiometric(BuildContext context) {
    AppDialogWidget.show(
      context,
      type: AppDialogType.warning,
      title: 'غیرفعال کردن ورود با اثرانگشت',
      description: 'ورود با اثرانگشت روی این دستگاه غیرفعال می‌شود.',
      buttonText: 'غیرفعال کردن',
      onConfirm: () => controller.disableBiometric(context),
    );
  }
}
