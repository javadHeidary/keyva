import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keyva/core/theme/app_radius.dart';
import 'package:keyva/core/theme/app_sizes.dart';
import 'package:keyva/core/theme/app_spacing.dart';
import 'package:keyva/core/theme/extensions/responsive_extentions.dart';
import 'package:keyva/core/theme/extensions/theme_extentions.dart';
import 'package:keyva/feature/type/image/viewmodel/image_folder_viewmodel.dart';
import 'package:keyva/feature/type/image/widget/encrypted_vault_image.dart';
import 'package:keyva/feature/vault/view/vault_item_details_leading.dart';
import 'package:keyva/feature/vault/view/vault_item_pin_ui.dart';
import 'package:keyva/feature/vault/viewmodel/vault_home_viewmodel.dart';
import 'package:keyva/shared/icons/app_icons.dart';
import 'package:keyva/shared/widget/app_empty_widget.dart';
import 'package:keyva/shared/widget/app_fab_widget.dart';
import 'package:keyva/shared/widget/app_header_widget.dart';
import 'package:keyva/shared/widget/app_loading_widger.dart';
import 'package:keyva/shared/widget/app_page_loading_overlay.dart';

class ImageFolderView extends GetView<ImageFolderViewModel> {
  const ImageFolderView({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Obx(() {
      if (Get.isRegistered<VaultHomeViewModel>()) {
        Get.find<VaultHomeViewModel>().vault.value;
      }
      final busy = controller.isBusy;
      final exporting = controller.isExporting.value;
      final folder = controller.folder;
      final photos = controller.photos;

      return Scaffold(
        key: const Key('vault-image-folder'),
        backgroundColor: colors.pageBackground,
        floatingActionButton: busy
            ? null
            : AppFabWidget(
                key: const Key('vault-image-folder-fab'),
                buttonSize: 50.s,
                icon: const Icon(AppIcon.add),
                onPressed: () => controller.addPhoto(context),
              ),
        body: AppPageLoadingOverlay(
          visible: busy,
          message: controller.overlayMessage,
          child: SafeArea(
            child: folder == null
                ? const SizedBox.shrink()
                : CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: AppHeaderWidget(
                          title: controller.headerTitle,
                          titleAlign: TextAlign.center,
                          leading: VaultItemDetailsLeading(
                            openedAfterCreate: controller.openedAfterCreate,
                          ),
                          onLeadingTap: busy ? null : Get.back,
                          trailingActions: [
                            vaultPinHeaderAction(
                              isPinned: folder.isPinned,
                              color: folder.isPinned
                                  ? colors.primary
                                  : colors.textSecondary,
                              onTap: busy
                                  ? () {}
                                  : () => controller.togglePin(context),
                            ),
                            if (photos.isNotEmpty)
                              AppHeaderTrailingAction(
                                onTap: busy
                                    ? null
                                    : () => controller.saveAllToGallery(
                                        context,
                                      ),
                                child: Tooltip(
                                  message: 'ذخیره همه تصاویر در گالری',
                                  child: Semantics(
                                    button: true,
                                    label: 'ذخیره همه تصاویر در گالری',
                                    child: exporting
                                        ? AppLoadingWidget.indicator(
                                            context: context,
                                            layout: AppLoadingLayout.inline,
                                            color: colors.textPrimary,
                                            size: AppSizes.iconMd.s,
                                          )
                                        : Icon(
                                            AppIcon.download,
                                            key: const Key(
                                              'vault-image-folder-save-gallery',
                                            ),
                                            size: AppSizes.iconLg.s,
                                            color: colors.textPrimary,
                                          ),
                                  ),
                                ),
                              ),
                            AppHeaderTrailingAction(
                              child: Icon(
                                AppIcon.edit,
                                key: const Key('vault-image-folder-edit'),
                                size: AppSizes.iconLg.s,
                                color: colors.textPrimary,
                              ),
                              onTap: busy ? null : controller.navigateToEdit,
                            ),
                            AppHeaderTrailingAction(
                              child: Icon(
                                AppIcon.delete,
                                key: const Key('vault-image-folder-delete'),
                                size: AppSizes.iconLg.s,
                                color: colors.error,
                              ),
                              onTap: busy
                                  ? null
                                  : () => controller.confirmDelete(context),
                            ),
                          ],
                        ),
                      ),
                      if (photos.isEmpty)
                        SliverPadding(
                          padding: EdgeInsets.fromLTRB(
                            AppSpacing.lg.s,
                            AppSpacing.lg.h,
                            AppSpacing.lg.s,
                            AppSpacing.hugePlus.h,
                          ),
                          sliver: const SliverToBoxAdapter(
                            child: AppEmptyWidget(
                              key: Key('vault-image-folder-empty'),
                              icon: AppIcon.images,
                              title: 'این پوشه خالی است',
                              description:
                                  'با دکمه + عکس بگیرید یا از گالری انتخاب کنید.',
                            ),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: EdgeInsets.fromLTRB(
                            AppSpacing.lg.s,
                            AppSpacing.sm.h,
                            AppSpacing.lg.s,
                            AppSpacing.hugePlus.h,
                          ),
                          sliver: SliverGrid(
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  crossAxisSpacing: AppSpacing.sm.s,
                                  mainAxisSpacing: AppSpacing.sm.s,
                                ),
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              final photo = photos[index];
                              return KeyedSubtree(
                                key: Key('vault-image-photo-${photo.id}'),
                                child: Material(
                                  color: colors.input,
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.medium,
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: InkWell(
                                    onTap: busy
                                        ? null
                                        : () => controller.openPhoto(photo.id),
                                    child: EncryptedVaultImage(
                                      blobId: photo.thumbnailBlobId,
                                    ),
                                  ),
                                ),
                              );
                            }, childCount: photos.length),
                          ),
                        ),
                    ],
                  ),
          ),
        ),
      );
    });
  }
}
