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
import 'package:keyva/feature/vault/view/vault_error_view.dart';
import 'package:keyva/feature/vault/view/vault_item_pin_ui.dart';
import 'package:keyva/feature/vault/view/vault_list_item_icon.dart';
import 'package:keyva/feature/vault/viewmodel/vault_ui_status.dart';
import 'package:keyva/shared/icons/app_icons.dart';
import 'package:keyva/shared/widget/app_empty_widget.dart';
import 'package:keyva/shared/widget/app_fab_widget.dart';
import 'package:keyva/shared/widget/app_list_item_widget.dart';
import 'package:keyva/shared/widget/app_more_widget.dart';
import 'package:keyva/shared/widget/keyva_logo.dart';

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
        expandableKey: controller.createFabKey,
        bottomInset: fabBottomInset,
        buttonSize: 45.s,
        icon: const Icon(AppIcon.add),
        children: [
          AppFabChildButton(
            key: const Key('home-fab-bank-card'),
            icon: Icon(AppIcon.creditCard),
            onPressed: () =>
                controller.onAddItemForType(VaultItemType.bankCard),
          ),
          AppFabChildButton(
            key: const Key('home-fab-secure-note'),
            icon: Icon(AppIcon.stickyNote),
            onPressed: () =>
                controller.onAddItemForType(VaultItemType.secureNote),
          ),
          AppFabChildButton(
            key: const Key('home-fab-login'),
            icon: Icon(AppIcon.lock),
            onPressed: () => controller.onAddItemForType(VaultItemType.login),
          ),
          AppFabChildButton(
            key: const Key('home-fab-image'),
            icon: Icon(AppIcon.images),
            onPressed: () => controller.onAddItemForType(VaultItemType.image),
          ),
        ],
      ),
      body: SafeArea(
        child: Obx(() {
          final status = controller.vaultStatus;
          switch (status) {
            case VaultUiStatus.initial:
            case VaultUiStatus.loading:
            case VaultUiStatus.empty:
            case VaultUiStatus.loaded:
            case VaultUiStatus.submitting:
            case VaultUiStatus.success:
              return const _VaultContent();
            case VaultUiStatus.error:
              if (controller.hasLoadedVault) {
                return const _VaultContent();
              }
              return KeyedSubtree(
                key: const Key('vault-home-error'),
                child: VaultErrorView(
                  message: controller.vaultErrorMessage,
                  onRetry: controller.loadVault,
                ),
              );
          }
        }),
      ),
    );
  }
}

class _VaultContent extends GetView<HomeController> {
  const _VaultContent();

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: controller.refreshVault,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          _homePaddedSliver(child: SizedBox(height: AppSpacing.xxl.h)),
          _homePaddedSliver(child: _AccountHeader()),
          _homePaddedSliver(child: _TypesSection()),
          _homePaddedSliver(child: _CategoriesSection()),
          _homePaddedSliver(
            child: const _ItemsSection(),
            bottom: AppSpacing.hugePlus,
          ),
        ],
      ),
    );
  }
}

SliverPadding _homePaddedSliver({required Widget child, double bottom = 0}) {
  return SliverPadding(
    padding: EdgeInsetsDirectional.only(
      start: AppSpacing.lg.s,
      end: AppSpacing.lg.s,
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
      key: const Key('home-account-header'),
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        KeyedSubtree(
          key: const Key('home-account-avatar'),
          child: KeyvaLogo(size: 40.s),
        ),
        SizedBox(width: AppSpacing.sm.s),
        Expanded(
          child: GestureDetector(
            onTap: controller.openSettings,
            behavior: HitTestBehavior.opaque,
            child: Obx(
              () => Text(
                key: const Key('home-account-name'),
                controller.accountOwnerName.value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                style: AppTypography.titleLarge.copyWith(
                  color: colors.textPrimary,
                ),
              ),
            ),
          ),
        ),
        Material(
          color: Colors.transparent,
          child: InkWell(
            key: const Key('home-search'),
            onTap: controller.onHomeSearchTap,
            borderRadius: BorderRadius.circular(20.s),
            child: SizedBox(
              width: 40.s,
              height: 40.s,
              child: Center(
                child: Icon(
                  AppIcon.search,
                  size: AppSizes.iconLg.s,
                  color: colors.textPrimary,
                ),
              ),
            ),
          ),
        ),
        IconButton(
          key: const Key('home-lock'),
          onPressed: controller.lock,
          visualDensity: VisualDensity.compact,
          icon: Icon(
            controller.isVaultUnlocked ? AppIcon.lockOpen : AppIcon.lock,
            size: 22.s,
            color: colors.textPrimary,
          ),
          tooltip: 'قفل کردن',
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
          key: const Key('home-type-selector'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsetsDirectional.only(
                start: AppSpacing.xs.s,
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
      child: Obx(() {
        final showInfo = controller.isTypeGuideVisible(summary.type);
        return AppListItemWidget(
          title: summary.type.label,
          subtitle: '${summary.itemCount} مورد',
          useFaNumSubtitle: true,
          trailingIcon: _CircleIcon(
            icon: Icon(
              summary.type.icon,
              size: AppSizes.iconMd.s,
              color: context.colors.textSecondary,
            ),
          ),
          leadingIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showInfo) ...[
                GestureDetector(
                  key: Key('item-type-guide-info-${summary.type.name}'),
                  onTap: () =>
                      controller.onTypeGuideInfoTap(context, summary.type),
                  behavior: HitTestBehavior.opaque,
                  child: Icon(AppIcon.info, size: AppSizes.iconMd.s),
                ),
                SizedBox(width: AppSpacing.sm.s),
              ],
              GestureDetector(
                onTap: () => controller.onTypeMoreActions(summary.type),
                behavior: HitTestBehavior.opaque,
                child: Icon(AppIcon.chevronRight, size: AppSizes.iconMd.s),
              ),
            ],
          ),
          onTap: () => Get.toNamed(AppRoutes.typeList, arguments: summary.type),
        );
      }),
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
          padding: EdgeInsetsDirectional.only(
            start: AppSpacing.xs.s,
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
            if (Get.isRegistered<CategoryCatalogController>()) {
              Get.find<CategoryCatalogController>().categories.length;
            }
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
  const _ItemsSection();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.lg.s),
      child: Obx(() {
        final items = controller.visibleItems;
        if (items.isEmpty) {
          if (controller.isVaultLoadPending) {
            return const SizedBox.shrink();
          }
          return _SectionCard(children: [_itemsEmptyState(controller)]);
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

Widget _itemsEmptyState(HomeController controller) {
  if (controller.hasNoVaultItems) {
    return AppEmptyWidget.vault(key: const Key('vault-home-empty'));
  }

  final type = controller.selectedType.value;
  if (type != null) {
    return KeyedSubtree(
      key: const Key('vault-home-empty'),
      child: AppEmptyWidget.typeList(type),
    );
  }

  return KeyedSubtree(
    key: const Key('vault-home-empty'),
    child: AppEmptyWidget.filteredResults(),
  );
}

class _VaultItemTile extends GetView<HomeController> {
  const _VaultItemTile({required this.item});

  final VaultListItem item;

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: Key('vault-item-${item.id}'),
      child: AppListItemWidget(
        title: item.title,
        subtitle: item.subtitle,
        trailingIcon: VaultListItemIcon(
          item: item,
          source: controller.sourceFor(item.id),
        ),
        leadingIcon: VaultItemPinMoreLeading(
          isPinned: item.isPinned,
          more: AppMoreWidget(
            dialogTitle: item.title,
            actions: vaultMoreActionsForItem(
              item,
              source: controller.sourceFor(item.id),
              onTogglePin: controller.isVaultSubmitting
                  ? null
                  : () => controller.toggleItemPin(context, item),
              onExportFolderImages:
                  controller.isVaultSubmitting ||
                      controller.photoCountFor(item) == 0
                  ? null
                  : () => controller.exportFolderImages(context, item),
              onDelete: controller.isVaultSubmitting
                  ? null
                  : () => controller.confirmDelete(context, item),
            ),
          ),
        ),
        onTap: () => controller.onItemTap(item),
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
