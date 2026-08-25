import 'package:flutter/material.dart';
import 'package:keyva/core/theme/app_typography.dart';
import 'package:keyva/core/theme/extensions/theme_extentions.dart';

class AuthPrivacyConsentLink extends StatelessWidget {
  const AuthPrivacyConsentLink({
    super.key,
    required this.prefix,
    required this.linkLabel,
    required this.suffix,
    required this.onTap,
  });

  final String prefix;
  final String linkLabel;
  final String suffix;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bodyStyle = AppTypography.bodyMedium.copyWith(
      color: colors.textSecondary,
    );

    return Text.rich(
      TextSpan(
        text: prefix,
        style: bodyStyle,
        children: [
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: GestureDetector(
              onTap: onTap,
              child: Text(
                linkLabel,
                style: bodyStyle.copyWith(color: colors.info),
              ),
            ),
          ),
          TextSpan(text: suffix),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
