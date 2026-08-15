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
import 'package:keyva/shared/icons/app_icons.dart';
import 'package:keyva/shared/widget/app_buttom_widget.dart';
import 'package:keyva/shared/widget/app_header_widget.dart';
import 'package:keyva/shared/widget/login_section_card_widget.dart';

class NoteDetailsView extends GetView<NoteDetailsViewModel> {
  const NoteDetailsView({super.key});

  static const _cardGap = AppSpacing.md;
  static const _notesMaxHeight = 280;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.pageBackground,
      body: SafeArea(
        child: Obx(() {
          controller.storeItems;
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
                              note.body,
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
                            constraints: BoxConstraints(
                              maxHeight: _notesMaxHeight.h,
                            ),
                            child: SingleChildScrollView(
                              child: NoteBodyTextWidget(
                                text: note.body,
                                onLinkTap: (type, value) => controller
                                    .openNoteLink(context, type, value),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: AppSpacing.sectionGap.h),
                      LoginDetailCredentialCard(
                        icon: AppIcon.folder,
                        label: 'دسته‌بندی',
                        value: controller.categoryLabel,
                      ),
                      SizedBox(height: _cardGap.h),
                      LoginDetailCredentialCard(
                        icon: AppIcon.heading,
                        label: 'عنوان',
                        value: note.title,
                        trailing: LoginDetailActionIcon(
                          icon: AppIcon.copy,
                          tooltip: 'کپی',
                          onTap: () => controller.copyValue(
                            context,
                            note.title,
                            'کپی',

                            'عنوان کپی شد',
                          ),
                        ),
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
