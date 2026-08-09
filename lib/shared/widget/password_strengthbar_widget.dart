import 'package:flutter/material.dart';
import 'package:keyva/core/theme/app_radius.dart';
import 'package:keyva/core/theme/app_spacing.dart';
import 'package:keyva/core/theme/app_typography.dart';
import 'package:keyva/core/theme/extensions/responsive_extentions.dart';
import 'package:keyva/core/theme/extensions/theme_extentions.dart';

enum PasswordStrength { veryWeak, weak, medium, strong, veryStrong }

class PasswordStrengthBarWidget extends StatelessWidget {
  const PasswordStrengthBarWidget({
    super.key,
    required this.strength,
    this.showLabel = true,
    this.duration = const Duration(milliseconds: 400),
    this.useSegmentedBars = false,
  });

  final double strength;
  final bool showLabel;
  final Duration duration;
  final bool useSegmentedBars;

  PasswordStrength get _level {
    if (strength < 0.2) return PasswordStrength.veryWeak;
    if (strength < 0.4) return PasswordStrength.weak;
    if (strength < 0.6) return PasswordStrength.medium;
    if (strength < 0.8) return PasswordStrength.strong;
    return PasswordStrength.veryStrong;
  }

  String get _label {
    switch (_level) {
      case PasswordStrength.veryWeak:
        return 'خیلی ضعیف';
      case PasswordStrength.weak:
        return 'ضعیف';
      case PasswordStrength.medium:
        return 'متوسط';
      case PasswordStrength.strong:
        return 'قوی';
      case PasswordStrength.veryStrong:
        return 'خیلی قوی';
    }
  }

  Color _color(BuildContext context) {
    final colors = context.colors;
    switch (_level) {
      case PasswordStrength.veryWeak:
        return colors.error;
      case PasswordStrength.weak:
        return colors.error.withValues(alpha: 0.8);
      case PasswordStrength.medium:
        return colors.warning;
      case PasswordStrength.strong:
        return colors.success;
      case PasswordStrength.veryStrong:
        return colors.success;
    }
  }

  int get _activeSegments {
    if (strength < 0.2) return 1;
    if (strength < 0.4) return 2;
    if (strength < 0.6) return 3;
    if (strength < 0.8) return 4;
    return 4;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final barColor = _color(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLabel)
          Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.sm.s),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  useSegmentedBars ? 'قدرت امنیتی' : 'قدرت رمز',
                  style: AppTypography.labelMedium.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                Text(
                  _label,
                  style: AppTypography.labelMedium.copyWith(
                    color: barColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        if (useSegmentedBars)
          Row(
            children: [
              for (var i = 0; i < 4; i++) ...[
                Expanded(
                  child: Container(
                    height: 6.s,
                    decoration: BoxDecoration(
                      color: i < _activeSegments
                          ? barColor
                          : colors.strengthBarBg,
                      borderRadius: BorderRadius.circular(AppRadius.small),
                    ),
                  ),
                ),
                if (i < 3) SizedBox(width: AppSpacing.xs.s),
              ],
            ],
          )
        else
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: strength.clamp(0.0, 1.0)),
            duration: duration,
            curve: Curves.easeInOut,
            builder: (context, value, child) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.small),
                child: LinearProgressIndicator(
                  value: value,
                  minHeight: 6.s,
                  backgroundColor: colors.strengthBarBg,
                  color: barColor,
                ),
              );
            },
          ),
      ],
    );
  }
}
