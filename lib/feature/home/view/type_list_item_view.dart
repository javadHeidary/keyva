import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keyva/core/theme/app_radius.dart';
import 'package:keyva/core/theme/app_sizes.dart';
import 'package:keyva/core/theme/app_spacing.dart';
import 'package:keyva/core/theme/app_typography.dart';
import 'package:keyva/core/theme/extensions/responsive_extentions.dart';
import 'package:keyva/core/theme/extensions/theme_extentions.dart';
import 'package:keyva/feature/home/model/vault_models.dart';
import 'package:keyva/feature/home/viewmodel/home_viewmodel.dart';
import 'package:keyva/shared/widget/app_header_widget.dart';
import 'package:keyva/shared/widget/app_list_item_widget.dart';

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
      floatingActionButton: FloatingActionButton(
        onPressed: () => controller.onAddItemForType(vaultType),
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        child: Icon(Icons.add_rounded, size: AppSizes.iconLg.s),
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: AppHeaderWidget(
                title: vaultType.label,
                titleAlign: TextAlign.center,
                leading: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: AppSizes.iconMd.s,
                  color: colors.textPrimary,
                ),
                onLeadingTap: Get.back,
                trailingActions: [
                  AppHeaderTrailingAction(
                    child: Icon(
                      Icons.search_rounded,
                      size: AppSizes.iconLg.s,
                      color: colors.textPrimary,
                    ),
                    onTap: controller.onTypeListSearchTap,
                  ),
                  AppHeaderTrailingAction(
                    child: Icon(
                      Icons.menu_rounded,
                      size: AppSizes.iconLg.s,
                      color: colors.textPrimary,
                    ),
                    onTap: controller.onTypeListMenuTap,
                  ),
                ],
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.sm.s,
                AppSpacing.sm.h,
                AppSpacing.lg.s,
                80.h,
              ),
              sliver: SliverToBoxAdapter(
                child: Obx(() {
                  final items = controller.itemsForType(vaultType);
                  if (items.isEmpty) {
                    return _TypeListSectionCard(
                      children: [
                        Padding(
                          padding: EdgeInsets.all(AppSpacing.lg.s),
                          child: Text(
                            'هنوز آیتمی از این نوع ثبت نشده است.',
                            textAlign: TextAlign.center,
                            style: AppTypography.bodyMedium.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                        ),
                      ],
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
