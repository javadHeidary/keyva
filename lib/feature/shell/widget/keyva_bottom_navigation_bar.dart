import 'package:flutter/material.dart';
import 'package:keyva/core/theme/app_radius.dart';
import 'package:keyva/core/theme/app_sizes.dart';
import 'package:keyva/core/theme/app_spacing.dart';
import 'package:keyva/core/theme/app_typography.dart';
import 'package:keyva/core/theme/extensions/responsive_extentions.dart';
import 'package:keyva/core/theme/extensions/theme_extentions.dart';

class KeyvaBottomNavItem {
  const KeyvaBottomNavItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

class KeyvaBottomNavigationBar extends StatelessWidget {
  const KeyvaBottomNavigationBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  final List<KeyvaBottomNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  static BorderRadius get _barRadius =>
      BorderRadius.circular(AppRadius.medium.s);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final shadows = context.shadows;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.pagePadding.s,
          0,
          AppSpacing.pagePadding.s,
          AppSpacing.md.h,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: _barRadius,
            border: Border.all(
              color: colors.border,
              width: AppSizes.inputBorderWidth,
            ),
            boxShadow: shadows.card,
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.sm.s,
              vertical: AppSpacing.sm.h,
            ),
            child: SizedBox(
              height: AppSizes.bottomNavHeight.h,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(items.length, (index) {
                  final item = items[index];
                  final isSelected = index == selectedIndex;
                  return _KeyvaBottomNavBarItem(
                    item: item,
                    isSelected: isSelected,
                    onTap: () => onItemSelected(index),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _KeyvaBottomNavBarItem extends StatelessWidget {
  const _KeyvaBottomNavBarItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final KeyvaBottomNavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final iconSize = AppSizes.iconMd.s;
    final pillRadius = BorderRadius.circular(AppRadius.medium.s);

    return InkWell(
      onTap: onTap,
      borderRadius: pillRadius,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? AppSpacing.md.s : AppSpacing.sm.s,
          vertical: AppSpacing.sm.h,
        ),
        decoration: isSelected
            ? BoxDecoration(color: colors.textPrimary, borderRadius: pillRadius)
            : null,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? item.selectedIcon : item.icon,
              size: iconSize,
              color: isSelected ? colors.card : colors.textSecondary,
            ),
            if (isSelected) ...[
              SizedBox(width: AppSpacing.xs.s),
              Text(
                item.label,
                style: AppTypography.labelSmall.copyWith(color: colors.card),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
