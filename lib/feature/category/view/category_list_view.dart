import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keyva/core/theme/app_sizes.dart';
import 'package:keyva/core/theme/app_spacing.dart';
import 'package:keyva/core/theme/extensions/responsive_extentions.dart';
import 'package:keyva/core/theme/extensions/theme_extentions.dart';
import 'package:keyva/core/theme/app_typography.dart';
import 'package:keyva/feature/category/util/category_icons.dart';
import 'package:keyva/feature/category/viewmodel/category_list_viewmodel.dart';
import 'package:keyva/shared/widget/app_dialog_widget.dart';
import 'package:keyva/shared/widget/app_header_widget.dart';
import 'package:keyva/shared/widget/category_widget.dart';

class CategoryListView extends GetView<CategoryListViewModel> {
  const CategoryListView({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.pageBackground,
      floatingActionButton: FloatingActionButton(
        heroTag: 'category_list_fab',
        onPressed: controller.openCreate,
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        child: Icon(Icons.add_rounded, size: AppSizes.iconLg.s),
      ),
      body: SafeArea(
        child: Obx(() {
          final categories = controller.catalog.categories;

          return CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(
                child: AppHeaderWidget(
                  title: 'دسته‌بندی‌ها',
                  titleAlign: TextAlign.center,
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.pagePadding.s,
                  AppSpacing.md.h,
                  AppSpacing.pagePadding.s,
                  96.h,
                ),
                sliver: categories.isEmpty
                    ? SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.all(AppSpacing.xl.s),
                          child: Text(
                            'هنوز دسته‌بندی ایجاد نکرده‌اید.',
                            textAlign: TextAlign.center,
                            style: AppTypography.bodyMedium.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                        ),
                      )
                    : SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: AppSpacing.md.h,
                          crossAxisSpacing: AppSpacing.md.s,
                          childAspectRatio: 1.1,
                        ),
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final category = categories[index];
                          return CategoryCardWidget(
                            title: category.name,
                            itemCount: controller.itemCountFor(category.id),
                            icon: CategoryIcons.widgetForId(
                              category.iconId,
                              color: colors.primary,
                            ),
                            onEdit: () => controller.openEdit(category.id),
                            onDelete: () => _confirmDelete(
                              context,
                              category.name,
                              category.id,
                            ),
                          );
                        }, childCount: categories.length),
                      ),
              ),
            ],
          );
        }),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String name, String id) {
    AppDialogWidget.show(
      context,
      type: AppDialogType.warning,
      title: 'حذف دسته‌بندی',
      description:
          'دسته «$name» حذف می‌شود. آیتم‌های این دسته به «بدون دسته‌بندی» '
          'منتقل می‌شوند.',
      buttonText: 'حذف',
      onConfirm: () => controller.deleteCategory(id),
    );
  }
}
