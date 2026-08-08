import 'package:flutter/material.dart';
import 'package:keyva/core/theme/app_radius.dart';
import 'package:keyva/core/theme/app_spacing.dart';
import 'package:keyva/core/theme/app_typography.dart';
import 'package:keyva/core/theme/extensions/responsive_extentions.dart';
import 'package:keyva/core/theme/extensions/theme_extentions.dart';

class DateInfoCardWidget extends StatelessWidget {
  const DateInfoCardWidget({
    super.key,
    required this.strengthLabel,
    required this.strengthValue,
    required this.dateLabel,
    required this.dateValue,
    this.strengthColor,
    this.icon,
  });

  final String strengthLabel;
  final String strengthValue;
  final String dateLabel;
  final String dateValue;
  final Color? strengthColor;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md.s,
        vertical: AppSpacing.sm.s + 2.s,
      ),
      decoration: BoxDecoration(
        color: colors.input,
        borderRadius: BorderRadius.circular(AppRadius.medium),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                if (icon != null) ...[
                  SizedBox(width: 18.s, height: 18.s, child: icon),
                  SizedBox(width: AppSpacing.sm.s),
                ],
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strengthLabel,
                      style: AppTypography.labelSmall.copyWith(
                        color: colors.textTertiary,
                      ),
                    ),
                    SizedBox(height: AppSpacing.xxs.s),
                    Text(
                      strengthValue,
                      style: AppTypography.titleSmall.copyWith(
                        color: strengthColor ?? colors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                dateLabel,
                style: AppTypography.labelSmall.copyWith(
                  color: colors.textTertiary,
                ),
              ),
              SizedBox(height: AppSpacing.xxs.s),
              Text(
                dateValue,
                style: AppTypography.titleSmall.copyWith(
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
