import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keyva/core/theme/app_radius.dart';
import 'package:keyva/core/theme/app_sizes.dart';
import 'package:keyva/core/theme/app_spacing.dart';
import 'package:keyva/core/theme/extensions/responsive_extentions.dart';
import 'package:keyva/core/theme/extensions/theme_extentions.dart';
import 'package:keyva/feature/home/model/vault_models.dart';
import 'package:keyva/feature/home/util/vault_more_actions.dart';
import 'package:keyva/feature/home/viewmodel/home_viewmodel.dart';
import 'package:keyva/feature/vault/view/vault_item_pin_ui.dart';
import 'package:keyva/feature/vault/view/vault_list_item_icon.dart';
import 'package:keyva/shared/icons/app_icons.dart';
import 'package:keyva/shared/widget/app_empty_widget.dart';
import 'package:keyva/shared/widget/app_fab_widget.dart';
import 'package:keyva/shared/widget/app_header_widget.dart';
import 'package:keyva/shared/widget/app_list_item_widget.dart';
import 'package:keyva/shared/widget/app_more_widget.dart';

class TypeListItemView extends GetView<HomeController> {
  TypeListItemView({super.key, VaultItemType? type})
    : vaultType = type ?? _typeFromArguments();

  final VaultItemType vaultType;

  static VaultItemType _typeFromArguments() {
    final args = Get.arguments;
    if (args is VaultItemType) return args;
    return VaultItemType.login;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      key: const Key('vault-type-list'),
      backgroundColor: colors.pageBackground,

      floatingActionButton: AppFabWidget(
        buttonSize: 50.s,
        icon: const Icon(AppIcon.add),
        onPressed: () => controller.onAddItemForType(vaultType),
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: AppHeaderWidget(
                title: vaultType.label,
                titleAlign: TextAlign.center,
                leading: Icon(
                  AppIcon.arrowBack,
                  size: AppSizes.iconLg.s,
                  color: colors.textPrimary,
                ),
                onLeadingTap: Get.back,
                trailingActions: [
                  AppHeaderTrailingAction(
                    child: Icon(
                      AppIcon.search,
                      size: AppSizes.iconLg.s,
                      color: colors.textPrimary,
                    ),
                    onTap: controller.onTypeListSearchTap,
                  ),
                ],
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
                child: Obx(() {
                  final items = controller.itemsForType(vaultType);
                  if (items.isEmpty) {
                    return _TypeListSectionCard(
                      children: [AppEmptyWidget.typeList(vaultType)],
                    );
                  }

                  return _TypeListSectionCard(
                    children: [
                      for (var i = 0; i < items.length; i++) ...[
                        if (i > 0) const _TypeListSectionDivider(),
                        _TypeListVaultItemTile(item: items[i]),
                      ],
                    ],
                  );
                }),
              ),
            ),
            SliverToBoxAdapter(child: SizedBox(height: AppSpacing.hugePlus.h)),
          ],
        ),
      ),
    );
  }
}

class _TypeListVaultItemTile extends GetView<HomeController> {
  const _TypeListVaultItemTile({required this.item});

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

class _TypeListSectionCard extends StatelessWidget {
  const _TypeListSectionCard({required this.children});

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

class _TypeListSectionDivider extends StatelessWidget {
  const _TypeListSectionDivider();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300.h,
      child: Divider(height: 1, thickness: 2, color: context.colors.divider),
    );
  }
}
