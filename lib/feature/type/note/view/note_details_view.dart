import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keyva/core/theme/app_sizes.dart';
import 'package:keyva/core/theme/app_spacing.dart';
import 'package:keyva/core/theme/app_typography.dart';
import 'package:keyva/core/theme/extensions/responsive_extentions.dart';
import 'package:keyva/core/theme/extensions/theme_extentions.dart';
import 'package:keyva/feature/type/login/widget/login_detail_credential_card.dart';
import 'package:keyva/feature/type/note/viewmodel/note_details_viewmodel.dart';
import 'package:keyva/feature/type/note/widget/note_body_text_widget.dart';
import 'package:keyva/feature/vault/view/vault_item_pin_ui.dart';
import 'package:keyva/shared/icons/app_icons.dart';
import 'package:keyva/shared/widget/app_buttom_widget.dart';
import 'package:keyva/shared/widget/app_header_widget.dart';
import 'package:keyva/shared/widget/login_section_card_widget.dart';

class NoteDetailsView extends GetView<NoteDetailsViewModel> {
  const NoteDetailsView({super.key});

  static const descriptionKey = Key('vault-note-description');
  static const _cardGap = AppSpacing.md;

  static double descriptionMinHeight() {
    final style = AppTypography.bodyMedium;
    final fontSize = style.fontSize ?? 14;
    final height = style.height ?? 1.5;
    return (fontSize * height * 5).s;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      key: const Key('vault-note-details'),
      backgroundColor: colors.pageBackground,
      body: SafeArea(
        child: Obx(() {
          final note = controller.item;
          if (note == null) {
            return const SizedBox.shrink();
          }

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
                    vaultPinHeaderAction(
                      isPinned: note.isPinned,
                      color: note.isPinned
                          ? colors.primary
                          : colors.textSecondary,
                      onTap: () => controller.togglePin(context),
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
                      LoginDetailCredentialCard(
                        icon: AppIcon.folder,
                        label: 'دسته‌بندی',
                        value: controller.categoryLabel,
                      ),
                      SizedBox(height: _cardGap.h),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'یادداشت',
                              style: AppTypography.titleMedium.copyWith(
                                color: colors.textPrimary,
                              ),
                            ),
                          ),
                          LoginDetailActionIcon(
                            icon: AppIcon.copy,
                            tooltip: 'کپی',
                            onTap: () => controller.copyValue(
                              context,
                              note.content,
                              'کپی',
                              'متن یادداشت کپی شد',
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: AppSpacing.sm.h),
                      AppSectionCardWidget(
                        padding: EdgeInsets.all(AppSpacing.lg.s),
                        children: [
                          ConstrainedBox(
                            key: descriptionKey,
                            constraints: BoxConstraints(
                              minHeight: descriptionMinHeight(),
                            ),
                            child: Align(
                              alignment: AlignmentDirectional.topStart,
                              child: NoteBodyTextWidget(
                                text: note.content,
                                onLinkTap: (type, value) => controller
                                    .openNoteLink(context, type, value),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: _cardGap.h),
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
                          key: const Key('vault-item-edit'),
                          title: 'ویرایش',
                          icon: Icon(AppIcon.edit, size: AppSizes.iconMd.s),
                          onPressed: controller.navigateToEdit,
                        ),
                      ),
                      SizedBox(width: AppSpacing.md.s),
                      Expanded(
                        child: AppButtonWidget(
                          title: 'حذف',
                          icon: Icon(AppIcon.delete, size: AppSizes.iconMd.s),
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
