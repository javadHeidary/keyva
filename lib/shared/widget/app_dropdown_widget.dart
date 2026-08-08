import 'package:flutter/material.dart';
import 'package:keyva/core/theme/app_radius.dart';
import 'package:keyva/core/theme/app_sizes.dart';
import 'package:keyva/core/theme/app_spacing.dart';
import 'package:keyva/core/theme/app_typography.dart';
import 'package:keyva/core/theme/extensions/responsive_extentions.dart';
import 'package:keyva/core/theme/extensions/theme_extentions.dart';

class AppDropdownItem<T> {
  const AppDropdownItem({required this.value, required this.label, this.icon});

  final T value;
  final String label;
  final Widget? icon;
}

class AppDropdownWidget<T> extends StatelessWidget {
  const AppDropdownWidget({
    super.key,
    required this.items,
    required this.onChanged,
    this.value,
    this.hint,
    this.trailingIcon,
    this.height,
    this.padding,
  });

  final List<AppDropdownItem<T>> items;
  final ValueChanged<T?> onChanged;
  final T? value;
  final String? hint;
  final Widget? trailingIcon;
  final double? height;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final selectedItem = items.cast<AppDropdownItem<T>?>().firstWhere(
      (item) => item?.value == value,
      orElse: () => null,
    );

    return SizedBox(
      height: height ?? AppSizes.itemHeight.s,
      child: PopupMenuButton<T>(
        onSelected: onChanged,
        offset: const Offset(0, 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium.s),
        ),
        itemBuilder: (context) {
          return items.map((item) {
            return PopupMenuItem<T>(
              value: item.value,
              child: Row(
                children: [
                  if (item.icon != null) ...[
                    item.icon!,
                    SizedBox(width: AppSpacing.md.s),
                  ],
                  Expanded(
                    child: Text(
                      item.label,
                      style: AppTypography.bodyMedium.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList();
        },
        child: Padding(
          padding:
              padding ??
              EdgeInsets.symmetric(
                horizontal: AppSpacing.lg.s,
                vertical: AppSpacing.sm.s,
              ),
          child: Row(
            children: [
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: colors.textSecondary,
                size: AppSizes.iconMd.s,
              ),
              SizedBox(width: AppSpacing.md.s),
              Expanded(
                child: Text(
                  selectedItem?.label ?? hint ?? '',
                  style: AppTypography.titleMedium.copyWith(
                    color: selectedItem != null
                        ? colors.textPrimary
                        : colors.textTertiary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (trailingIcon != null) ...[
                SizedBox(width: AppSpacing.md.s),
                trailingIcon!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
