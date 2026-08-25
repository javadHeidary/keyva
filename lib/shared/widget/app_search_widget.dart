import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keyva/core/constants/layout_constants.dart';
import 'package:keyva/core/theme/app_radius.dart';
import 'package:keyva/core/theme/app_sizes.dart';
import 'package:keyva/core/theme/app_spacing.dart';
import 'package:keyva/core/theme/extensions/responsive_extentions.dart';
import 'package:keyva/core/theme/extensions/theme_extentions.dart';
import 'package:keyva/feature/home/model/vault_models.dart';
import 'package:keyva/feature/home/util/vault_more_actions.dart';
import 'package:keyva/feature/search/viewmodel/search_viewmodel.dart';
import 'package:keyva/feature/vault/view/vault_item_pin_ui.dart';
import 'package:keyva/feature/vault/view/vault_list_item_icon.dart';
import 'package:keyva/shared/icons/app_icons.dart';
import 'package:keyva/shared/widget/app_empty_widget.dart';
import 'package:keyva/shared/widget/app_header_widget.dart';
import 'package:keyva/shared/widget/app_list_item_widget.dart';
import 'package:keyva/shared/widget/app_loading_widger.dart';
import 'package:keyva/shared/widget/app_more_widget.dart';
import 'package:keyva/shared/widget/app_search_header_widger.dart';

class AppSearchWidget extends GetView<SearchViewModel> {
  const AppSearchWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      resizeToAvoidBottomInset: LayoutConstants.resizeToAvoidBottomInset,
      backgroundColor: colors.pageBackground,
      body: SafeArea(
        child: Column(
          children: [
            AppHeaderWidget(
              leading: Icon(
                AppIcon.arrowBack,
                size: AppSizes.iconLg.s,
                color: colors.textPrimary,
              ),
              onLeadingTap: Get.back,
              titleWidget: AppSearchHeaderWidget(
                key: const Key('vault-search-field'),
                controller: controller.searchController,
                focusNode: controller.searchFocusNode,
                hintText: controller.hintText,
                padding: EdgeInsets.zero,
              ),
            ),
            Expanded(child: Obx(() => _buildBody(context))),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (controller.isSearching.value) {
      return Center(child: AppLoadingWidget.section());
    }

    final results = controller.results;
    if (results.isEmpty) {
      final query = controller.searchQuery.value.trim();
      final showIdle = query.isEmpty || controller.isVaultContentEmpty;
      return Center(
        child: showIdle
            ? AppEmptyWidget.searchIdle(typeLabel: controller.typeLabel)
            : AppEmptyWidget.searchNoResults(),
      );
    }

    return ListView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg.s,
        AppSpacing.sm.h,
        AppSpacing.lg.s,
        AppSpacing.hugePlus.h,
      ),
      children: [
        _SearchSectionCard(
          children: [
            for (var i = 0; i < results.length; i++) ...[
              if (i > 0) const _SearchSectionDivider(),
              _SearchResultTile(item: results[i]),
            ],
          ],
        ),
      ],
    );
  }
}

class _SearchResultTile extends GetView<SearchViewModel> {
  const _SearchResultTile({required this.item});

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
              onTogglePin: () => controller.togglePin(context, item),
              onDelete: () => controller.confirmDelete(context, item),
            ),
          ),
        ),
        onTap: () => controller.onItemTap(item),
      ),
    );
  }
}

class _SearchSectionCard extends StatelessWidget {
  const _SearchSectionCard({required this.children});

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

class _SearchSectionDivider extends StatelessWidget {
  const _SearchSectionDivider();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300.w,
      child: Divider(height: 1, thickness: 2, color: context.colors.divider),
    );
  }
}
