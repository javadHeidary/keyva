import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keyva/core/theme/app_radius.dart';
import 'package:keyva/core/theme/app_sizes.dart';
import 'package:keyva/core/theme/app_spacing.dart';
import 'package:keyva/core/theme/app_typography.dart';
import 'package:keyva/core/theme/extensions/responsive_extentions.dart';
import 'package:keyva/core/theme/extensions/theme_extentions.dart';
import 'package:keyva/feature/type/image/viewmodel/image_details_viewmodel.dart';
import 'package:keyva/feature/type/image/widget/encrypted_vault_image.dart';
import 'package:keyva/feature/type/login/widget/login_detail_credential_card.dart';
import 'package:keyva/feature/vault/viewmodel/vault_home_viewmodel.dart';
import 'package:keyva/shared/icons/app_icons.dart';
import 'package:keyva/shared/widget/app_buttom_widget.dart';
import 'package:keyva/shared/widget/app_header_widget.dart';
import 'package:keyva/shared/widget/app_loading_widger.dart';
import 'package:keyva/shared/widget/login_section_card_widget.dart';

class ImageDetailsView extends GetView<ImageDetailsViewModel> {
  const ImageDetailsView({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      key: const Key('vault-image-details'),
      backgroundColor: colors.pageBackground,
      body: SafeArea(
        child: Obx(() {
          if (Get.isRegistered<VaultHomeViewModel>()) {
            Get.find<VaultHomeViewModel>().vault.value;
          }
          final exporting = controller.isExporting.value;
          final canExport = controller.canExport.value;
          final photo = controller.item;
          if (photo == null) {
            return const SizedBox.shrink();
          }
          final note = controller.note;

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: AppHeaderWidget(
                  title: controller.headerTitle,
                  titleAlign: TextAlign.center,
                  leading: Icon(
                    AppIcon.arrowBack,
                    size: AppSizes.iconLg.s,
                    color: colors.textPrimary,
                  ),
                  onLeadingTap: Get.back,
                  trailingActions: [
                    AppHeaderTrailingAction(
                      onTap: canExport && !exporting
                          ? () => controller.saveToGallery(context)
                          : null,
                      child: Tooltip(
                        message: 'ذخیره در گالری',
                        child: Semantics(
                          button: true,
                          label: 'ذخیره در گالری',
                          child: exporting
                              ? AppLoadingWidget.indicator(
                                  context: context,
                                  layout: AppLoadingLayout.inline,
                                  color: colors.textPrimary,
                                  size: AppSizes.iconMd.s,
                                )
                              : Icon(
                                  AppIcon.download,
                                  key: const Key('vault-image-save-gallery'),
                                  size: AppSizes.iconLg.s,
                                  color: canExport
                                      ? colors.textPrimary
                                      : colors.textTertiary,
                                ),
                        ),
                      ),
                    ),
                  ],
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
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.card),
                        child: AspectRatio(
                          aspectRatio: photo.width / photo.height,
                          child: EncryptedVaultImage(
                            blobId: photo.blobId,
                            fit: BoxFit.contain,
                            onDecoded: controller.onImageDecoded,
                          ),
                        ),
                      ),
                      if (note != null) ...[
                        SizedBox(height: AppSpacing.lg.h),
                        Text(
                          'یادداشت',
                          style: AppTypography.titleMedium.copyWith(
                            color: colors.textPrimary,
                          ),
                        ),
                        SizedBox(height: AppSpacing.sm.h),
                        AppSectionCardWidget(
                          padding: EdgeInsets.all(AppSpacing.lg.s),
                          children: [
                            Align(
                              alignment: AlignmentDirectional.topStart,
                              child: Text(
                                note,
                                style: AppTypography.bodyMedium.copyWith(
                                  color: colors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      SizedBox(height: AppSpacing.lg.h),
                      LoginDetailCredentialCard(
                        icon: AppIcon.calendar,
                        label: 'تاریخ ایجاد',
                        value: controller.createdAtLabel,
                        useFaNumValue: true,
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.hugePlus.s,
                  AppSpacing.hugePlus.h,
                  AppSpacing.hugePlus.s,
                  AppSpacing.xxl.h,
                ),
                sliver: SliverToBoxAdapter(
                  child: AppButtonWidget(
                    key: const Key('vault-image-delete'),
                    title: 'حذف',
                    icon: Icon(AppIcon.delete, size: AppSizes.iconMd.s),
                    backgroundColor: colors.error.withValues(alpha: 0.3),
                    foregroundColor: colors.error,
                    onPressed: () => controller.confirmDelete(context),
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
