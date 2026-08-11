import 'package:flutter/material.dart';
import 'package:keyva/core/theme/app_sizes.dart';
import 'package:keyva/core/theme/app_spacing.dart';
import 'package:keyva/core/theme/extensions/responsive_extentions.dart';

/// Bottom layout metrics for the floating shell nav. Keep in sync with
/// [KeyvaBottomNavigationBar] padding and height.
abstract final class MainShellLayout {
  /// Full height of the floating nav block (safe area + outer/inner padding + bar).
  static double navOverlayExtent(BuildContext context) {
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    return safeBottom +
        AppSpacing.md.h +
        AppSpacing.sm.h * 2 +
        AppSizes.bottomNavHeight.h;
  }

  /// FAB sits just above the nav with a tight [AppSpacing.xs] gap.
  static double fabBottomInset(BuildContext context) {
    return navOverlayExtent(context) + AppSpacing.xs.h;
  }

  /// Scroll/content inset so lists clear FAB + nav.
  static double contentBottomGap(BuildContext context) {
    return fabBottomInset(context);
  }
}
