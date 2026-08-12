import 'package:flutter/material.dart';
import 'package:keyva/core/theme/app_spacing.dart';
import 'package:keyva/core/theme/app_typography.dart';
import 'package:keyva/core/theme/extensions/responsive_extentions.dart';
import 'package:keyva/core/theme/extensions/theme_extentions.dart';

class ToggleItemWidget extends StatelessWidget {
  const ToggleItemWidget({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.icon,
    this.subtitle,
    this.titleColor,
  });

  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Widget? icon;
  final String? subtitle;
  final Color? titleColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return GestureDetector(
      onTap: () => onChanged(!value),
      behavior: HitTestBehavior.opaque,

      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md.s,
          vertical: AppSpacing.sm.s + 4.s,
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              SizedBox(width: 24.s, height: 24.s, child: icon),
              SizedBox(width: AppSpacing.md.s),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodyMedium.copyWith(
                      color: titleColor ?? colors.textPrimary,
                    ),
                  ),
                  if (subtitle != null) ...[
                    SizedBox(height: 2.s),
                    Text(
                      subtitle!,
                      style: AppTypography.labelSmall.copyWith(
                        color: colors.textTertiary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(width: AppSpacing.sm.s),
            Switch(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}
