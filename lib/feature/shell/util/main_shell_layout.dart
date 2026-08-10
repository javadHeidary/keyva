import 'package:flutter/material.dart';
import 'package:keyva/core/theme/app_sizes.dart';
import 'package:keyva/core/theme/app_spacing.dart';
import 'package:keyva/core/theme/extensions/responsive_extentions.dart';

/// Layout metrics for the floating main-shell bottom navigation overlay.
abstract final class MainShellLayout {
  /// Vertical size of the nav bar row (must match [KeyvaBottomNavigationBar]).
  static double navBarContentHeight(BuildContext context) {
    return AppSizes.bottomNavHeight.h;
  }

  /// Full bottom overlay: safe area + margins + nav bar block.
  static double bottomOverlayExtent(BuildContext context) {
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    return safeBottom +
        AppSpacing.md.h +
        AppSpacing.sm.h * 2 +
        navBarContentHeight(context);
  }

  /// Scroll/content inset so lists clear the floating nav bar.
  static double contentBottomGap(BuildContext context) {
    return bottomOverlayExtent(context) + AppSpacing.sm.h;
  }

  /// Estimate used where [BuildContext] is unavailable (e.g. FAB location).
  static double estimatedOverlayExtent(double safeAreaBottom) {
    return safeAreaBottom;
  }
}

/// Positions FAB above the main-shell bottom navigation overlay.
class MainShellFabLocation extends FloatingActionButtonLocation {
  const MainShellFabLocation();

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    final fabSize = scaffoldGeometry.floatingActionButtonSize;
    final scaffoldSize = scaffoldGeometry.scaffoldSize;
    final bottomInset = scaffoldGeometry.minInsets.bottom;
    final navClearance = MainShellLayout.estimatedOverlayExtent(bottomInset);

    final double end = scaffoldGeometry.textDirection == TextDirection.ltr
        ? scaffoldSize.width - fabSize.width - kFloatingActionButtonMargin
        : kFloatingActionButtonMargin;

    final double y =
        scaffoldSize.height -
        fabSize.height -
        kFloatingActionButtonMargin -
        (navClearance - bottomInset);

    return Offset(end, y);
  }
}
