import 'package:flutter/material.dart';
import 'package:keyva/core/theme/app_typography.dart';
import 'package:keyva/core/theme/extensions/theme_extentions.dart';

class AuthFooterLink extends StatelessWidget {
  const AuthFooterLink({
    super.key,
    required this.prefix,
    required this.actionLabel,
    required this.onTap,
    this.prefixColor,
  });

  final String prefix;
  final String actionLabel;
  final VoidCallback onTap;
  final Color? prefixColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Text.rich(
        TextSpan(
          text: prefix,
          style: AppTypography.bodyMedium.copyWith(
            color: prefixColor ?? colors.textTertiary,
          ),
          children: [
            TextSpan(
              text: actionLabel,
              style: AppTypography.titleMedium.copyWith(color: colors.primary),
            ),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
