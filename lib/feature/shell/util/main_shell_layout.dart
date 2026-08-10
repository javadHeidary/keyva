import 'package:flutter/material.dart';
import 'package:keyva/core/theme/app_sizes.dart';
import 'package:keyva/core/theme/app_spacing.dart';
import 'package:keyva/core/theme/extensions/responsive_extentions.dart';

/// Bottom inset for tab content. Keep in sync with [KeyvaBottomNavigationBar].
abstract final class MainShellLayout {
  static double contentBottomGap(BuildContext context) {
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    return safeBottom +
        AppSpacing.md.h +
        AppSizes.bottomNavHeight.h +
        AppSpacing.sm.h;
  }
}
