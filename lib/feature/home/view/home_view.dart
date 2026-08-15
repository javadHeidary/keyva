import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keyva/core/routes/app_routing.dart';
import 'package:keyva/core/theme/app_radius.dart';
import 'package:keyva/core/theme/app_sizes.dart';
import 'package:keyva/core/theme/app_spacing.dart';
import 'package:keyva/core/theme/app_typography.dart';
import 'package:keyva/core/theme/extensions/responsive_extentions.dart';
import 'package:keyva/core/theme/extensions/theme_extentions.dart';
import 'package:keyva/feature/category/controller/category_catalog_controller.dart';
import 'package:keyva/feature/home/model/vault_models.dart';
import 'package:keyva/feature/home/util/vault_more_actions.dart';
import 'package:keyva/feature/home/viewmodel/home_viewmodel.dart';
import 'package:keyva/feature/shell/util/main_shell_layout.dart';
import 'package:keyva/shared/icons/app_icons.dart';
import 'package:keyva/shared/widget/app_empty_widget.dart';
import 'package:keyva/shared/widget/app_fab_widget.dart';
import 'package:keyva/shared/widget/app_list_item_widget.dart';
import 'package:keyva/shared/widget/app_more_widget.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final fabBottomInset = MainShellLayout.fabBottomInset(context);

    return Scaffold(
      key: controller.scaffoldKey,
      floatingActionButtonLocation: AppFabWidget.scaffoldLocation(
        bottomInset: fabBottomInset,
        expandable: true,
      ),
      floatingActionButton: AppFabWidget(
        bottomInset: fabBottomInset,
        buttonSize: 45.s,
        icon: const Icon(AppIcon.add),
        children: [
          AppFabChildButton(
            icon: Icon(AppIcon.creditCard),
            onPressed: () =>
                controller.onAddItemForType(VaultItemType.bankCard),
          ),
          AppFabChildButton(
            icon: Icon(AppIcon.stickyNote),
            onPressed: () =>
                controller.onAddItemForType(VaultItemType.secureNote),
          ),
          AppFabChildButton(
            icon: Icon(AppIcon.lock),
            onPressed: () => controller.onAddItemForType(VaultItemType.login),
          ),
        ],
      ),
      body: SafeArea(
        child: Obx(() {
          if (controller.vaultItems.isEmpty) {
            return AppEmptyWidget.vault(onCreate: controller.onCreateFirstItem);
          }
          return const _VaultContent();
        }),
      ),
    );
  }
}

class _VaultContent extends GetView<HomeController> {
  const _VaultContent();

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        _homePaddedSliver(child: SizedBox(height: AppSpacing.xxl.h)),
        _homePaddedSliver(child: _AccountHeader()),
        _homePaddedSliver(child: _TypesSection()),
        _homePaddedSliver(child: _CategoriesSection()),
        _homePaddedSliver(child: _ItemsSection()),
        _homePaddedSliver(child: _TrashSection(), bottom: AppSpacing.hugePlus),
      ],
    );
  }
}

SliverPadding _homePaddedSliver({required Widget child, double bottom = 0}) {
  return SliverPadding(
    padding: EdgeInsets.only(
      right: AppSpacing.lg.s,
      left: AppSpacing.lg.s,
      bottom: bottom,
    ),
    sliver: SliverToBoxAdapter(child: child),
  );
}

class _AccountHeader extends GetView<HomeController> {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {},
            borderRadius: BorderRadius.circular(AppRadius.extra),
            child: Container(
              width: 40.s,
              height: 40.s,
              decoration: BoxDecoration(
                color: colors.textTertiary,
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(AppRadius.medium),
              ),
              alignment: Alignment.center,
              child: Icon(AppIcon.accountCircle),
            ),
          ),
        ),
        SizedBox(width: AppSpacing.sm.s),
        Expanded(
          flex: 1,
          child: GestureDetector(
            onTap: controller.openSettings,
            behavior: HitTestBehavior.opaque,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Obx(
                  () => Text(
                    controller.accountOwnerName.value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.titleLarge.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: controller.onHomeSearchTap,
              borderRadius: BorderRadius.circular(12.s),
              child: Container(
                height: 48.s,
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg.s),
                decoration: BoxDecoration(
                  color: colors.input,
                  borderRadius: BorderRadius.circular(12.s),
                ),
                child: Row(
                  children: [
                    Icon(
                      AppIcon.search,
                      size: 22.s,
                      color: colors.textSecondary,
                    ),
                    SizedBox(width: AppSpacing.sm.s),
                    Text(
                      'جستجو ...',
                      style: AppTypography.bodyMedium.copyWith(
                        color: colors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TypesSection extends GetView<HomeController> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.xl.s),
      child: Obx(() {
        final summaries = controller.typeSummaries;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(
                right: AppSpacing.xs.s,
                bottom: AppSpacing.sm.h,
              ),
              child: Text(
                'انواع آیتم‌ها',
                style: AppTypography.titleMedium.copyWith(
                  color: context.colors.textPrimary,
                ),
              ),
            ),
            _SectionCard(
              children: [
                for (var i = 0; i < summaries.length; i++) ...[
                  if (i > 0) const _SectionDivider(),
                  _TypeListTile(summary: summaries[i]),
                ],
              ],
            ),
          ],
        );
      }),
    );
  }
}

class _TypeListTile extends GetView<HomeController> {
  const _TypeListTile({required this.summary});

  final VaultTypeSummary summary;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.medium),
      ),
      child: AppListItemWidget(
        title: summary.type.label,
        subtitle: '${summary.itemCount} مورد',
        trailingIcon: _CircleIcon(
          icon: Icon(
            summary.type.icon,
            size: AppSizes.iconMd.s,
            color: context.colors.textSecondary,
          ),
        ),
        leadingIcon: Icon(AppIcon.chevronRight, size: AppSizes.iconMd.s),
        onTap: () => Get.toNamed(AppRoutes.typeList, arguments: summary.type),
        onLeadingPressed: () => controller.onTypeMoreActions(summary.type),
      ),
    );
  }
}

class _CategoriesSection extends GetView<HomeController> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(
            right: AppSpacing.xs.s,
            bottom: AppSpacing.md.h,
          ),
          child: Text(
            'دسته‌بندی‌ها',
            style: AppTypography.titleMedium.copyWith(
              color: context.colors.textPrimary,
            ),
          ),
        ),
        SizedBox(
          height: 44.h,
          child: Obx(() {
            final _ = Get.find<CategoryCatalogController>().categories.length;
            final selectedCategoryId = controller.selectedCategoryId.value;
            final filterCategories = controller.filterCategories;
            return ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: filterCategories.length,
              separatorBuilder: (_, __) => SizedBox(width: AppSpacing.sm.s),
              itemBuilder: (context, index) {
                final category = filterCategories[index];
                final isSelected = selectedCategoryId == category.id;
                return _CategoryChip(
                  label: category.name,
                  isSelected: isSelected,
                  onTap: () => controller.selectCategory(category.id),
                );
              },
            );
          }),
        ),
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.button),
      child: Ink(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.lg.s,
          vertical: AppSpacing.sm.s,
        ),
        decoration: BoxDecoration(
          color: isSelected ? colors.primary : colors.input,
          borderRadius: BorderRadius.circular(AppRadius.button),
          border: Border.all(
            color: isSelected ? colors.primary : colors.border,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTypography.labelLarge.copyWith(
              color: isSelected ? colors.onPrimary : colors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _ItemsSection extends GetView<HomeController> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.lg.s),
      child: Obx(() {
        final items = controller.visibleItems;
        if (items.isEmpty) {
          return _SectionCard(children: [AppEmptyWidget.filteredResults()]);
        }

        return _SectionCard(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) const _SectionDivider(),
              _VaultItemTile(item: items[i]),
            ],
          ],
        );
      }),
    );
  }
}

class _VaultItemTile extends GetView<HomeController> {
  const _VaultItemTile({required this.item});

  final VaultListItem item;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return AppListItemWidget(
      title: item.title,
      subtitle: item.subtitle,
      trailingIcon: _CircleIcon(
        icon: Icon(
          item.type.icon,
          size: AppSizes.iconMd.s,
          color: colors.textSecondary,
        ),
      ),
      leadingIcon: AppMoreWidget(
        dialogTitle: item.title,
        actions: vaultMoreActionsForItem(item),
      ),
      onTap: () => controller.onItemTap(item),
    );
  }
}

class _TrashSection extends GetView<HomeController> {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.lg.s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(
              right: AppSpacing.xs.s,
              bottom: AppSpacing.sm.h,
            ),
            child: Text(
              'سطل زباله',
              style: AppTypography.titleMedium.copyWith(
                color: colors.textPrimary,
              ),
            ),
          ),
          Obx(
            () => _SectionCard(
              children: [
                AppListItemWidget(
                  title: 'موارد حذف‌شده',
                  subtitle: '${controller.trashItemCount.value} مورد',
                  trailingIcon: _CircleIcon(
                    icon: Icon(
                      AppIcon.delete,
                      size: AppSizes.iconMd.s,
                      color: context.colors.textSecondary,
                    ),
                  ),
                  leadingIcon: Icon(
                    AppIcon.chevronRight,
                    size: AppSizes.iconMd.s,
                  ),
                  onTap: controller.onTrashTap,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: context.shadows.card,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Column(mainAxisSize: MainAxisSize.min, children: children),
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300.w,
      child: Divider(height: 1, thickness: 2, color: context.colors.divider),
    );
  }
}

class _CircleIcon extends StatelessWidget {
  const _CircleIcon({required this.icon});

  final Widget icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      width: 40.s,
      height: 40.s,
      decoration: BoxDecoration(
        color: colors.input,
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(AppRadius.medium),
      ),
      child: Center(child: icon),
    );
  }
}
