import 'package:flutter/material.dart';
import 'package:keyva/core/theme/app_sizes.dart';
import 'package:keyva/core/theme/app_spacing.dart';
import 'package:keyva/core/theme/extensions/responsive_extentions.dart';
import 'package:keyva/core/theme/extensions/theme_extentions.dart';
import 'package:keyva/feature/type/login/widget/login_circle_icon.dart';
import 'package:keyva/shared/widget/app_list_item_widget.dart';

class LoginDetailField extends StatelessWidget {
  const LoginDetailField({
    super.key,
    required this.label,
    required this.value,
    this.leadingIcon,
    this.onCopy,
    this.secondaryActionIcon,
    this.onSecondaryAction,
    this.maxLines = 1,
  });

  final String label;
  final String value;
  final Widget? leadingIcon;
  final VoidCallback? onCopy;
  final IconData? secondaryActionIcon;
  final VoidCallback? onSecondaryAction;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final displayValue = value.isEmpty ? '—' : value;

    Widget? actionIcons;
    if (onCopy != null || onSecondaryAction != null) {
      actionIcons = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onSecondaryAction != null && secondaryActionIcon != null)
            _ActionTap(
              icon: secondaryActionIcon!,
              onTap: onSecondaryAction!,
            ),
          if (onCopy != null)
            _ActionTap(icon: Icons.copy_rounded, onTap: onCopy!),
        ],
      );
    }

    return AppListItemWidget(
      title: displayValue,
      subtitle: label,
      trailingIcon: leadingIcon != null
          ? LoginCircleIcon(
              icon: SizedBox(
                width: AppSizes.iconMd.s,
                height: AppSizes.iconMd.s,
                child: leadingIcon,
              ),
            )
          : null,
      leadingIcon: actionIcons,
      height: maxLines > 1 ? null : AppSizes.itemHeight.h,
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.lg.s,
        vertical: AppSpacing.sm.s,
      ),
    );
  }
}

class _ActionTap extends StatelessWidget {
  const _ActionTap({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xs.s),
        child: Icon(
          icon,
          size: AppSizes.iconMd.s,
          color: colors.textSecondary,
        ),
      ),
    );
  }
}
