import 'package:flutter/material.dart';
import 'package:keyva/core/theme/app_radius.dart';
import 'package:keyva/core/theme/app_sizes.dart';
import 'package:keyva/core/theme/app_spacing.dart';
import 'package:keyva/core/theme/app_typography.dart';
import 'package:keyva/core/theme/extensions/responsive_extentions.dart';
import 'package:keyva/core/theme/extensions/theme_extentions.dart';

class SplitDateInfoWidget extends StatelessWidget {
  const SplitDateInfoWidget({
    super.key,
    required this.leftLabel,
    required this.leftValue,
    required this.rightLabel,
    required this.rightValue,
    this.icon,
    this.onLeftCopy,
    this.onRightCopy,
    this.leftCopyKey,
    this.rightCopyKey,
  });

  final String leftLabel;
  final String leftValue;
  final String rightLabel;
  final String rightValue;
  final Widget? icon;
  final VoidCallback? onLeftCopy;
  final VoidCallback? onRightCopy;
  final Key? leftCopyKey;
  final Key? rightCopyKey;

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
          if (icon != null) ...[
            SizedBox(width: 18.s, height: 18.s, child: icon),
            SizedBox(width: AppSpacing.sm.s),
          ],
          Expanded(
            child: _DateSection(
              label: leftLabel,
              value: leftValue,
              onCopy: onLeftCopy,
              copyKey: leftCopyKey,
            ),
          ),
          Container(
            width: 1.w,
            height: 28.s,
            color: colors.divider,
            margin: EdgeInsets.symmetric(horizontal: AppSpacing.sm.s),
          ),
          Expanded(
            child: _DateSection(
              label: rightLabel,
              value: rightValue,
              onCopy: onRightCopy,
              copyKey: rightCopyKey,
            ),
          ),
        ],
      ),
    );
  }
}

class _DateSection extends StatelessWidget {
  const _DateSection({
    required this.label,
    required this.value,
    this.onCopy,
    this.copyKey,
  });

  final String label;
  final String value;
  final VoidCallback? onCopy;
  final Key? copyKey;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final valueStyle = AppTypography.withFaNum(
      AppTypography.titleSmall.copyWith(color: colors.textPrimary),
    );

    return Column(
      children: [
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(color: colors.textTertiary),
        ),
        SizedBox(height: 2.s),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: valueStyle,
              ),
            ),
            if (onCopy != null) ...[
              SizedBox(width: AppSpacing.xs.s),
              GestureDetector(
                key: copyKey,
                onTap: onCopy,
                behavior: HitTestBehavior.opaque,
                child: Icon(
                  Icons.copy_rounded,
                  size: AppSizes.iconSm.s,
                  color: colors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
