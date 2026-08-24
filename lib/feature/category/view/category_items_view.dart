import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keyva/core/routes/app_routing.dart';
import 'package:keyva/core/theme/app_radius.dart';
import 'package:keyva/core/theme/app_sizes.dart';
import 'package:keyva/core/theme/app_spacing.dart';
import 'package:keyva/core/theme/extensions/responsive_extentions.dart';
import 'package:keyva/core/theme/extensions/theme_extentions.dart';
import 'package:keyva/feature/category/controller/category_catalog_controller.dart';
import 'package:keyva/feature/home/model/vault_models.dart';
import 'package:keyva/feature/home/util/vault_more_actions.dart';
import 'package:keyva/feature/home/viewmodel/home_viewmodel.dart';
import 'package:keyva/feature/vault/view/vault_item_navigation.dart';
import 'package:keyva/feature/vault/view/vault_item_pin_ui.dart';
import 'package:keyva/feature/vault/view/vault_list_item_icon.dart';
import 'package:keyva/shared/icons/app_icons.dart';
import 'package:keyva/shared/widget/app_empty_widget.dart';
import 'package:keyva/shared/widget/app_fab_widget.dart';
import 'package:keyva/shared/widget/app_header_widget.dart';
import 'package:keyva/shared/widget/app_list_item_widget.dart';
import 'package:keyva/shared/widget/app_more_widget.dart';

class CategoryItemsView extends GetView<HomeController> {
  CategoryItemsView({super.key, String? categoryId})
    : categoryId = categoryId ?? vaultRouteCategoryId() ?? '';

  final String categoryId;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      key: const Key('category-items'),
      backgroundColor: colors.pageBackground,
      floatingActionButtonLocation: AppFabWidget.scaffoldLocation(
        bottomInset: AppSpacing.lg.h,
        expandable: true,
      ),
      floatingActionButton: AppFabWidget(
        bottomInset: AppSpacing.lg.h,
        buttonSize: 45.s,
        icon: const Icon(AppIcon.add),
        children: [
          AppFabChildButton(
            key: const Key('category-items-fab-bank-card'),
            icon: Icon(AppIcon.creditCard),
            onPressed: () => controller.onAddItemForType(
              VaultItemType.bankCard,
              categoryId: categoryId,
            ),
          ),
          AppFabChildButton(
            key: const Key('category-items-fab-secure-note'),
            icon: Icon(AppIcon.stickyNote),
            onPressed: () => controller.onAddItemForType(
              VaultItemType.secureNote,
              categoryId: categoryId,
            ),
          ),
          AppFabChildButton(
            key: const Key('category-items-fab-login'),
            icon: Icon(AppIcon.lock),
            onPressed: () => controller.onAddItemForType(
              VaultItemType.login,
              categoryId: categoryId,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Obx(() {
          final catalog = Get.find<CategoryCatalogController>();
          catalog.categories.length;
          final category = catalog.findById(categoryId);
          if (category == null) {
            if (controller.hasLoadedVault) {
              _leaveIfCategoryMissing();
            }
            return const SizedBox.shrink();
          }

          final items = controller.itemsForCategory(categoryId);

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: AppHeaderWidget(
                  title: category.name,
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
                  AppSpacing.lg.s,
                  AppSpacing.sm.h,
                  AppSpacing.lg.s,
                  80.h,
                ),
                sliver: SliverToBoxAdapter(
                  child: items.isEmpty
                      ? _CategoryItemsSectionCard(
                          children: [
                            AppEmptyWidget.categoryItems(
                              key: const Key('category-items-empty'),
                            ),
                          ],
                        )
                      : _CategoryItemsSectionCard(
                          children: [
                            for (var i = 0; i < items.length; i++) ...[
                              if (i > 0) const _CategoryItemsSectionDivider(),
                              _CategoryItemsVaultItemTile(item: items[i]),
                            ],
                          ],
                        ),
                ),
              ),
              SliverToBoxAdapter(child: SizedBox(height: AppSpacing.hugePlus.h)),
            ],
          );
        }),
      ),
    );
  }

  void _leaveIfCategoryMissing() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.currentRoute != AppRoutes.categoryItems) {
        return;
      }
      if (!Get.isRegistered<CategoryCatalogController>()) {
        return;
      }
      final stillMissing =
          Get.find<CategoryCatalogController>().findById(categoryId) == null;
      if (stillMissing) {
        Get.back();
      }
    });
  }
}

class _CategoryItemsVaultItemTile extends GetView<HomeController> {
  const _CategoryItemsVaultItemTile({required this.item});

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

class _CategoryItemsSectionCard extends StatelessWidget {
  const _CategoryItemsSectionCard({required this.children});

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

class _CategoryItemsSectionDivider extends StatelessWidget {
  const _CategoryItemsSectionDivider();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300.h,
      child: Divider(height: 1, thickness: 2, color: context.colors.divider),
    );
  }
}
