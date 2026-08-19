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
import 'package:keyva/shared/icons/app_icons.dart';
import 'package:keyva/shared/widget/app_empty_widget.dart';
import 'package:keyva/shared/widget/app_fab_widget.dart';
import 'package:keyva/shared/widget/app_header_widget.dart';
import 'package:keyva/shared/widget/app_list_item_widget.dart';
import 'package:keyva/shared/widget/app_more_widget.dart';

class TypeListItemView extends GetView<HomeController> {
  const TypeListItemView({super.key});

  VaultItemType get _vaultType {
    final args = Get.arguments;
    if (args is VaultItemType) return args;
    return VaultItemType.login;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final vaultType = _vaultType;
    return Scaffold(
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
    final colors = context.colors;

    return AppListItemWidget(
      title: item.title,
      subtitle: item.subtitle,
      trailingIcon: _TypeListCircleIcon(
        icon: Icon(
          item.type.icon,
          size: AppSizes.iconMd.s,
          color: colors.textSecondary,
        ),
      ),
      leadingIcon: AppMoreWidget(
        dialogTitle: item.title,
        actions: vaultMoreActionsForItem(
          item,
          source: controller.sourceFor(item.id),
          onDelete: controller.isVaultSubmitting
              ? null
              : () => controller.confirmDelete(context, item),
        ),
      ),
      onTap: () => controller.onItemTap(item),
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

class _TypeListCircleIcon extends StatelessWidget {
  const _TypeListCircleIcon({required this.icon});

  final Widget icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      width: 40.s,
      height: 40.s,
      decoration: BoxDecoration(
        color: colors.input,
        borderRadius: BorderRadius.circular(AppRadius.medium),
      ),
      child: Center(child: icon),
    );
  }
}
