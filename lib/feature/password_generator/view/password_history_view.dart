import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keyva/core/theme/app_sizes.dart';
import 'package:keyva/core/theme/app_spacing.dart';
import 'package:keyva/core/theme/app_typography.dart';
import 'package:keyva/core/theme/extensions/responsive_extentions.dart';
import 'package:keyva/core/theme/extensions/theme_extentions.dart';
import 'package:keyva/feature/password_generator/viewmodel/password_history_viewmodel.dart';
import 'package:keyva/feature/type/login/widget/login_detail_credential_card.dart';
import 'package:keyva/shared/widget/app_header_widget.dart';
import 'package:keyva/shared/widget/login_section_card_widget.dart';

class PasswordHistoryView extends GetView<PasswordHistoryViewModel> {
  const PasswordHistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.pageBackground,
      body: SafeArea(
        child: Obx(() {
          controller.entries.length;
          final entries = controller.entries;

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: AppHeaderWidget(
                  title: 'تاریخچه رمزها',
                  titleAlign: TextAlign.center,
                  leading: Icon(
                    Icons.arrow_back_ios_new_rounded,
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
                  AppSpacing.xxl.h,
                ),
                sliver: entries.isEmpty
                    ? SliverToBoxAdapter(
                        child: AppSectionCardWidget(
                          children: [
                            Text(
                              'هنوز رمزی در تاریخچه نیست. با کپی رمز از تولیدکننده، اینجا ذخیره می‌شود.',
                              style: AppTypography.bodyMedium.copyWith(
                                color: colors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                    : SliverList.separated(
                        itemCount: entries.length,
                        separatorBuilder: (_, __) =>
                            SizedBox(height: AppSpacing.md.h),
                        itemBuilder: (context, index) {
                          final entry = entries[index];
                          return LoginDetailCredentialCard(
                            icon: Icons.lock_outline_rounded,
                            label: controller.formatCopiedAt(entry.copiedAt),
                            value: entry.password,
                            maxLines: 2,
                            trailing: LoginDetailActionIcon(
                              icon: Icons.copy_rounded,
                              tooltip: 'کپی',
                              onTap: () => controller.copyPassword(
                                context,
                                entry.password,
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
