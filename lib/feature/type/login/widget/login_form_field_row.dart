import 'package:flutter/material.dart';
import 'package:keyva/core/theme/app_spacing.dart';
import 'package:keyva/core/theme/extensions/responsive_extentions.dart';

class LoginFormFieldRow extends StatelessWidget {
  const LoginFormFieldRow({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.lg.s,
        vertical: AppSpacing.sm.s,
      ),
      child: child,
    );
  }
}
