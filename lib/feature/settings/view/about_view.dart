import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keyva/core/gen/assets.gen.dart';
import 'package:keyva/core/theme/app_radius.dart';
import 'package:keyva/core/theme/app_sizes.dart';
import 'package:keyva/core/theme/app_spacing.dart';
import 'package:keyva/core/theme/app_typography.dart';
import 'package:keyva/core/theme/extensions/responsive_extentions.dart';
import 'package:keyva/core/theme/extensions/theme_extentions.dart';
import 'package:keyva/feature/settings/model/about_content.dart';
import 'package:keyva/feature/settings/model/app_info.dart';
import 'package:keyva/shared/icons/app_icons.dart';
import 'package:keyva/shared/widget/app_header_widget.dart';

class AboutView extends StatelessWidget {
  const AboutView({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final logo = context.isDark
        ? Assets.images.logoDarkMode
        : Assets.images.logoLightMode;

    return Scaffold(
      backgroundColor: colors.pageBackground,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: AppHeaderWidget(
                title: AboutContent.aboutTitle,
                titleAlign: TextAlign.center,
                leading: Icon(
                  AppIcon.arrowBack,
                  size: AppSizes.iconLg.s,
                  color: colors.textPrimary,
                ),
                onLeadingTap: Get.back,
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.pagePadding.s,
                AppSpacing.md.h,
                AppSpacing.pagePadding.s,
                AppSpacing.hugePlus.h,
              ),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: logo.image(
                        width: 88.s,
                        height: 88.s,
                        fit: BoxFit.contain,
                      ),
                    ),
                    SizedBox(height: AppSpacing.md.h),
                    Text(
                      AboutContent.appName,
                      textAlign: TextAlign.center,
                      style: AppTypography.headlineMedium.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                    SizedBox(height: AppSpacing.xs.h),
                    Text(
                      AboutContent.tagline,
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyMedium.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                    SizedBox(height: AppSpacing.xl.h),
                    Text(
                      AboutContent.aboutTitle,
                      style: AppTypography.titleMedium.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                    SizedBox(height: AppSpacing.sm.h),
                    Text(
                      AboutContent.description,
                      textAlign: TextAlign.start,
                      style: AppTypography.bodyMedium.copyWith(
                        color: colors.textSecondary,
                        height: 1.7,
                      ),
                    ),
                    SizedBox(height: AppSpacing.xl.h),
                    Text(
                      AboutContent.featuresTitle,
                      style: AppTypography.titleMedium.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                    SizedBox(height: AppSpacing.sm.h),
                    ...AboutContent.features.map(
                      (feature) => Padding(
                        padding: EdgeInsets.only(bottom: AppSpacing.sm.h),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              AppIcon.check,
                              size: AppSizes.iconSm.s,
                              color: colors.primary,
                            ),
                            SizedBox(width: AppSpacing.sm.s),
                            Expanded(
                              child: Text(
                                feature,
                                style: AppTypography.bodyMedium.copyWith(
                                  color: colors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: AppSpacing.md.h),
                    Container(
                      padding: EdgeInsets.all(AppSpacing.lg.s),
                      decoration: BoxDecoration(
                        color: colors.card,
                        borderRadius: BorderRadius.circular(AppRadius.card),
                        boxShadow: context.shadows.card,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            AboutContent.privacyTitle,
                            style: AppTypography.titleMedium.copyWith(
                              color: colors.textPrimary,
                            ),
                          ),
                          SizedBox(height: AppSpacing.sm.h),
                          Text(
                            AboutContent.privacyFirst,
                            textAlign: TextAlign.start,
                            style: AppTypography.bodySmall.copyWith(
                              color: colors.textSecondary,
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: AppSpacing.xl.h),
                    Text(
                      AboutContent.versionLabel,
                      textAlign: TextAlign.center,
                      style: AppTypography.labelMedium.copyWith(
                        color: colors.textTertiary,
                      ),
                    ),
                    SizedBox(height: AppSpacing.xs.h),
                    Text(
                      AppInfo.displayVersion,
                      textAlign: TextAlign.center,
                      style: AppTypography.withFaNum(
                        AppTypography.bodyMedium.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
