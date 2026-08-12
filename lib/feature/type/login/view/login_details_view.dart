import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keyva/core/theme/app_radius.dart';
import 'package:keyva/core/theme/app_sizes.dart';
import 'package:keyva/core/theme/app_spacing.dart';
import 'package:keyva/core/theme/app_typography.dart';
import 'package:keyva/core/theme/extensions/responsive_extentions.dart';
import 'package:keyva/core/theme/extensions/theme_extentions.dart';
import 'package:keyva/feature/type/login/util/login_password_util.dart';
import 'package:keyva/feature/type/login/viewmodel/login_details_viewmodel.dart';
import 'package:keyva/feature/type/login/widget/login_detail_credential_card.dart';
import 'package:keyva/feature/type/login/widget/login_favicon_widget.dart';
import 'package:keyva/shared/icons/app_icons.dart';
import 'package:keyva/shared/widget/login_section_card_widget.dart';
import 'package:keyva/shared/widget/app_buttom_widget.dart';
import 'package:keyva/shared/widget/app_header_widget.dart';
import 'package:keyva/shared/widget/app_title_item_widget.dart';

class LoginDetailsView extends GetView<LoginDetailsViewModel> {
  const LoginDetailsView({super.key});

  static const _cardGap = AppSpacing.md;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.pageBackground,
      body: SafeArea(
        child: Obx(() {
          controller.storeItems;
          controller.isPasswordVisible.value;
          final login = controller.item;
          if (login == null) {
            return const SizedBox.shrink();
          }

          final strengthColor = loginPasswordStrengthColor(
            context,
            controller.passwordStrength,
          );

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: AppHeaderWidget(
                  title: controller.headerTitle,
                  titleAlign: TextAlign.center,
                  leading: Icon(
                    AppIcon.arrowBack,
                    size: AppSizes.iconMd.s,
                    color: colors.textPrimary,
                  ),
                  onLeadingTap: Get.back,
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.pagePadding.s,
                  AppSpacing.sm.h,
                  AppSpacing.pagePadding.s,
                  0,
                ),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const AppTitleItemWidget(title: 'مشخصات ورود'),
                      LoginDetailCredentialCard(
                        icon: AppIcon.folder,
                        label: 'دسته‌بندی',
                        value: controller.categoryLabel,
                      ),
                      SizedBox(height: _cardGap.h),
                      LoginDetailCredentialCard(
                        icon: AppIcon.accountCircle,
                        label: 'نام کاربری',
                        value: login.username,
                        trailing: LoginDetailActionIcon(
                          icon: AppIcon.copy,
                          tooltip: 'کپی',
                          onTap: () => controller.copyValue(
                            context,
                            login.username,
                            'نام کاربری کپی شد',
                          ),
                        ),
                      ),
                      SizedBox(height: _cardGap.h),
                      LoginDetailCredentialCard(
                        icon: AppIcon.lock,
                        label: 'رمز عبور',
                        value: controller.isPasswordVisible.value
                            ? login.password
                            : '•' * login.password.length,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            LoginDetailActionIcon(
                              icon: controller.isPasswordVisible.value
                                  ? AppIcon.visibilityOff
                                  : AppIcon.visibility,
                              tooltip: 'نمایش رمز',
                              onTap: controller.togglePasswordVisibility,
                            ),
                            LoginDetailActionIcon(
                              icon: AppIcon.copy,
                              tooltip: 'کپی',
                              onTap: () => controller.copyValue(
                                context,
                                login.password,
                                'رمز عبور کپی شد',
                              ),
                            ),
                          ],
                        ),
                      ),
                      for (var i = 0; i < login.websites.length; i++) ...[
                        SizedBox(height: _cardGap.h),
                        LoginDetailCredentialCard(
                          label: login.websites.length > 1
                              ? 'وب‌سایت ${i + 1}'
                              : 'وب‌سایت',
                          value:
                              websiteHostForFavicon(login.websites[i]) ??
                              login.websites[i],
                          leading: LoginFaviconWidget(
                            website: login.websites[i],
                            size: 44.s,
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              LoginDetailActionIcon(
                                icon: AppIcon.copy,
                                tooltip: 'کپی',
                                onTap: () => controller.copyValue(
                                  context,
                                  login.websites[i],
                                  'آدرس وب‌سایت کپی شد',
                                ),
                              ),
                              LoginDetailActionIcon(
                                icon: AppIcon.externalLink,
                                tooltip: 'باز کردن',
                                onTap: () => controller.openWebsite(
                                  context,
                                  login.websites[i],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      SizedBox(height: AppSpacing.sectionGap.h),
                      const AppTitleItemWidget(title: 'وضعیت امنیتی'),
                      AppSectionCardWidget(
                        padding: EdgeInsets.all(AppSpacing.lg.s),
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: 44.s,
                                height: 44.s,
                                decoration: BoxDecoration(
                                  color: colors.success.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.card,
                                  ),
                                  shape: BoxShape.rectangle,
                                ),
                                child: Icon(
                                  AppIcon.shield,
                                  size: AppSizes.iconMd.s,
                                  color: colors.success,
                                ),
                              ),
                              SizedBox(width: AppSpacing.md.s),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'قدرت رمز',
                                      style: AppTypography.labelMedium.copyWith(
                                        color: colors.textSecondary,
                                      ),
                                    ),
                                    SizedBox(height: AppSpacing.xxs.s),
                                    Text(
                                      controller.passwordStrengthLabel,
                                      style: AppTypography.titleMedium.copyWith(
                                        color: strengthColor,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'آخرین بروزرسانی',
                                      style: AppTypography.labelMedium.copyWith(
                                        color: colors.textSecondary,
                                      ),
                                    ),
                                    SizedBox(height: AppSpacing.xxs.s),
                                    Text(
                                      controller.createdAtLabel,
                                      style: AppTypography.titleMedium.copyWith(
                                        color: colors.textPrimary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      textAlign: TextAlign.end,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (login.notes != null && login.notes!.isNotEmpty) ...[
                        SizedBox(height: AppSpacing.sectionGap.h),
                        const AppTitleItemWidget(title: 'یادداشت'),
                        LoginDetailCredentialCard(
                          icon: AppIcon.note,
                          label: 'یادداشت',
                          value: login.notes!,
                          maxLines: 4,
                          trailing: LoginDetailActionIcon(
                            icon: AppIcon.copy,
                            tooltip: 'کپی',
                            onTap: () => controller.copyValue(
                              context,
                              login.notes!,
                              'یادداشت کپی شد',
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.pagePadding.s,
                  AppSpacing.hugePlus.h,
                  AppSpacing.pagePadding.s,
                  AppSpacing.xxl.h,
                ),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      Expanded(
                        child: AppButtonWidget(
                          title: 'ویرایش',
                          icon: Icon(
                            AppIcon.edit,
                            size: AppSizes.iconMd.s,
                          ),
                          onPressed: controller.navigateToEdit,
                        ),
                      ),
                      SizedBox(width: AppSpacing.md.s),
                      Expanded(
                        child: AppButtonWidget(
                          title: 'حذف',
                          icon: Icon(
                            AppIcon.delete,
                            size: AppSizes.iconMd.s,
                          ),
                          backgroundColor: colors.error.withValues(alpha: 0.3),
                          foregroundColor: colors.error,
                          onPressed: () => controller.confirmDelete(context),
                        ),
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
