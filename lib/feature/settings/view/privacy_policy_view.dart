import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keyva/core/theme/app_sizes.dart';
import 'package:keyva/core/theme/app_spacing.dart';
import 'package:keyva/core/theme/app_typography.dart';
import 'package:keyva/core/theme/extensions/responsive_extentions.dart';
import 'package:keyva/core/theme/extensions/theme_extentions.dart';
import 'package:keyva/feature/settings/model/privacy_policy_content.dart';
import 'package:keyva/shared/icons/app_icons.dart';
import 'package:keyva/shared/widget/app_header_widget.dart';

class PrivacyPolicyView extends StatelessWidget {
  const PrivacyPolicyView({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final sections = PrivacyPolicyContent.sections;

    return Scaffold(
      backgroundColor: colors.pageBackground,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: AppHeaderWidget(
                title: PrivacyPolicyContent.title,
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
                AppSpacing.sm.h,
                AppSpacing.pagePadding.s,
                AppSpacing.huge.h,
              ),
              sliver: SliverList.separated(
                itemCount: sections.length,
                separatorBuilder: (_, __) => SizedBox(height: AppSpacing.lg.h),
                itemBuilder: (context, index) {
                  final section = sections[index];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        section.title,
                        textAlign: TextAlign.start,
                        style: AppTypography.titleMedium.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                      SizedBox(height: AppSpacing.sm.h),
                      Text(
                        section.body,
                        textAlign: TextAlign.start,
                        style: AppTypography.bodyMedium.copyWith(
                          color: colors.textSecondary,
                          height: 1.7,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
