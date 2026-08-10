import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:keyva/core/gen/assets.gen.dart';
import 'package:keyva/core/routes/app_routing.dart';
import 'package:keyva/core/theme/app_radius.dart';
import 'package:keyva/core/theme/app_sizes.dart';
import 'package:keyva/core/theme/app_spacing.dart';
import 'package:keyva/core/theme/app_typography.dart';
import 'package:keyva/core/theme/extensions/responsive_extentions.dart';
import 'package:keyva/core/theme/extensions/theme_extentions.dart';
import 'package:keyva/feature/home/model/vault_models.dart';
import 'package:keyva/feature/home/viewmodel/home_viewmodel.dart';
import 'package:keyva/shared/widget/app_buttom_widget.dart';
import 'package:keyva/shared/widget/app_list_item_widget.dart';
import 'package:keyva/shared/widget/app_search_header_widger.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      key: controller.scaffoldKey,
      backgroundColor: colors.pageBackground,
      endDrawer: const _HomeNavigationDrawer(),
      floatingActionButton: Obx(() {
        if (controller.vaultItems.isEmpty) return const SizedBox.shrink();
        return FloatingActionButton(
          onPressed: controller.onAddItem,
          backgroundColor: colors.primary,
          foregroundColor: colors.onPrimary,
          child: Icon(Icons.add_rounded, size: AppSizes.iconLg.s),
        );
      }),
      body: SafeArea(
        child: Obx(() {
          if (controller.vaultItems.isEmpty) {
            return _VaultEmptyState(onCreate: controller.onCreateFirstItem);
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
    return Padding(
      padding: EdgeInsets.only(left: AppSpacing.lg.s, right: AppSpacing.lg.s),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl.h)),
          SliverToBoxAdapter(child: _AccountHeader()),
          SliverToBoxAdapter(child: _TypesSection()),
          SliverToBoxAdapter(child: _CategoriesSection()),
          SliverToBoxAdapter(child: _ItemsSection()),
          SliverToBoxAdapter(child: _TrashSection()),
          SliverToBoxAdapter(child: SizedBox(height: AppSpacing.hugePlus.h)),
        ],
      ),
    );
  }
}

class _AccountHeader extends GetView<HomeController> {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        InkWell(
          onTap: () => controller.scaffoldKey.currentState?.openEndDrawer(),
          borderRadius: BorderRadius.circular(AppRadius.extra),
          child: SizedBox(
            width: 40.s,
            height: 40.s,
            child: Icon(
              Icons.menu_rounded,
              size: AppSizes.iconLg.s,
              color: colors.textPrimary,
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
          child: AppSearchHeaderWidget(
            controller: controller.searchController,
            hintText: 'جستجو ...',
            onChanged: controller.onSearchChanged,
            padding: EdgeInsets.zero,
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
        leadingIcon: Icon(Icons.chevron_right_rounded, size: AppSizes.iconMd.s),
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
            final selectedCategoryId = controller.selectedCategoryId.value;
            return ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: controller.categories.length,
              separatorBuilder: (_, __) => SizedBox(width: AppSpacing.sm.s),
              itemBuilder: (context, index) {
                final category = controller.categories[index];
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
    final colors = context.colors;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.lg.s),
      child: Obx(() {
        final items = controller.visibleItems;
        if (items.isEmpty) {
          return _SectionCard(
            children: [
              Padding(
                padding: EdgeInsets.all(AppSpacing.lg.s),
                child: Text(
                  'موردی با این فیلترها یافت نشد.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ),
            ],
          );
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
      leadingIcon: Icon(
        Icons.more_vert_rounded,
        size: AppSizes.iconMd.s,
        color: colors.textSecondary,
      ),
      onTap: () => controller.onItemTap(item),
      onLeadingPressed: () => _showItemActions(context, item),
    );
  }

  void _showItemActions(BuildContext context, VaultListItem item) {
    final actions = _actionsForType(item.type);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.colors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.modal),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final action in actions)
                ListTile(
                  title: Text(
                    action,
                    style: AppTypography.bodyMedium.copyWith(
                      color: context.colors.textPrimary,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    controller.onItemMoreAction(item, action);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  List<String> _actionsForType(VaultItemType type) {
    switch (type) {
      case VaultItemType.login:
        return ['کپی نام کاربری', 'کپی رمز عبور'];
      case VaultItemType.bankCard:
        return ['کپی شماره کارت', 'کپی CVV2', 'کپی تاریخ انقضا'];
      case VaultItemType.secureNote:
        return ['کپی محتوای یادداشت'];
    }
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
                    icon: SvgPicture.asset(
                      Assets.icons.trashTest.path,
                      width: AppSizes.iconSm.s,
                      height: AppSizes.iconSm.s,
                      colorFilter: ColorFilter.mode(
                        colors.textTertiary,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                  leadingIcon: Icon(
                    Icons.chevron_right_rounded,
                    size: AppSizes.iconLg.s,
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

class _VaultEmptyState extends StatelessWidget {
  const _VaultEmptyState({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl.s),
      child: Column(
        children: [
          const Spacer(flex: 2),
          SvgPicture.asset(
            Assets.images.onboardinTest.path,
            width: 220.w,
            height: 220.h,
            fit: BoxFit.contain,
          ),
          SizedBox(height: AppSpacing.xl.h),
          Text(
            'هنوز چیزی ذخیره نکرده‌اید',
            textAlign: TextAlign.center,
            style: AppTypography.titleLarge.copyWith(color: colors.textPrimary),
          ),
          SizedBox(height: AppSpacing.md.h),
          Text(
            'رمزها، کارت‌های بانکی و یادداشت‌های امن خود را در گاوصندوق شخصی نگه دارید.',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              color: colors.textSecondary,
            ),
          ),
          const Spacer(flex: 3),
          AppButtonWidget(
            title: 'ایجاد اولین آیتم',
            icon: Icon(Icons.add_rounded, size: AppSizes.iconMd.s),
            onPressed: onCreate,
          ),
          SizedBox(height: AppSpacing.xxl.h),
        ],
      ),
    );
  }
}

class _HomeNavigationDrawer extends StatelessWidget {
  const _HomeNavigationDrawer();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Drawer(
      backgroundColor: colors.card,
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.all(AppSpacing.lg.s),
          children: [
            Text(
              'منوی ناوبری',
              style: AppTypography.titleMedium.copyWith(
                color: colors.textPrimary,
              ),
            ),
            SizedBox(height: AppSpacing.lg.h),
            ListTile(
              leading: Icon(
                Icons.settings_rounded,
                color: colors.primary,
              ),
              title: Text(
                'تنظیمات',
                style: AppTypography.bodyMedium.copyWith(
                  color: colors.textPrimary,
                ),
              ),
              onTap: () {
                Navigator.of(context).pop();
                Get.toNamed(AppRoutes.settings);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.password_rounded,
                color: colors.primary,
              ),
              title: Text(
                'تولید رمز عبور',
                style: AppTypography.bodyMedium.copyWith(
                  color: colors.textPrimary,
                ),
              ),
              onTap: () {
                Navigator.of(context).pop();
                Get.toNamed(AppRoutes.passwordGenerator);
              },
            ),
          ],
        ),
      ),
    );
  }
}
