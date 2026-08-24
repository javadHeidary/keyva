import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keyva/core/routes/app_routing.dart';
import 'package:keyva/core/theme/app_spacing.dart';
import 'package:keyva/core/theme/extensions/responsive_extentions.dart';
import 'package:keyva/core/theme/extensions/theme_extentions.dart';
import 'package:keyva/feature/category/util/category_icons.dart';
import 'package:keyva/feature/category/viewmodel/category_list_viewmodel.dart';
import 'package:keyva/feature/shell/util/main_shell_layout.dart';
import 'package:keyva/shared/icons/app_icons.dart';
import 'package:keyva/shared/widget/app_empty_widget.dart';
import 'package:keyva/shared/widget/app_dialog_widget.dart';
import 'package:keyva/shared/widget/app_fab_widget.dart';
import 'package:keyva/shared/widget/app_header_widget.dart';
import 'package:keyva/shared/widget/category_widget.dart';

class CategoryListView extends GetView<CategoryListViewModel> {
  const CategoryListView({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final fabBottomInset = MainShellLayout.fabBottomInset(
      context,
      extraPadding: AppSpacing.lg.h,
    );

    return Scaffold(
      backgroundColor: colors.pageBackground,
      floatingActionButtonLocation: AppFabWidget.scaffoldLocation(
        bottomInset: fabBottomInset,
        expandable: false,
      ),
      floatingActionButton: AppFabWidget(
        bottomInset: fabBottomInset,
        buttonSize: 45.s,
        icon: const Icon(AppIcon.add),
        onPressed: () => Get.toNamed(AppRoutes.categoryCreate),
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
                  AppSpacing.hugePlus.h,
                ),
                sliver: categories.isEmpty
                    ? SliverToBoxAdapter(
                        child: AppEmptyWidget.categories(),
                      )
                    : SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: AppSpacing.md.w,
                          mainAxisSpacing: AppSpacing.md.h,
                          childAspectRatio: 1.6,
                        ),
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final category = categories[index];

                          return KeyedSubtree(
                            key: Key('category-card-${category.id}'),
                            child: CategoryCardWidget(
                              title: category.name,
                              itemCount: controller.itemCountFor(category.id),
                              icon: CategoryIcons.widgetForId(
                                category.iconId,
                                color: colors.primary,
                              ),
                              onTap: () =>
                                  controller.openCategory(category.id),
                              onEdit: () => controller.openEdit(category.id),
                              onDelete: () => _confirmDelete(
                                context,
                                category.name,
                                category.id,
                              ),
                            ),
                          );
                        }, childCount: categories.length),
                      ),
              ),
              SliverToBoxAdapter(child: SizedBox(height: 80.h)),
              SliverToBoxAdapter(child: SizedBox(height: 80.h)),
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
