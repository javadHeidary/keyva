import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:keyva/core/theme/app_radius.dart';
import 'package:keyva/core/theme/app_sizes.dart';
import 'package:keyva/core/theme/app_spacing.dart';
import 'package:keyva/core/theme/extensions/responsive_extentions.dart';
import 'package:keyva/core/theme/extensions/theme_extentions.dart';

/// Bottom-left FAB placement using page padding and a caller-provided bottom inset.
class AppFabScaffoldLocation extends FloatingActionButtonLocation {
  const AppFabScaffoldLocation({
    required this.bottomInset,
    this.buttonSize = AppSizes.fabButtonSize,
  });

  final double bottomInset;
  final double buttonSize;

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    final scaffoldSize = scaffoldGeometry.scaffoldSize;
    final fabHeight = buttonSize.s;

    return Offset(
      AppSpacing.pagePadding.s,
      scaffoldSize.height - fabHeight - bottomInset,
    );
  }
}

/// Reusable fan-style expandable FAB.
///
/// Pass [children] for a speed-dial menu; each child can be any [Widget].
/// When [children] is empty, a single FAB is shown and [onPressed] is required.
class AppFabWidget extends StatelessWidget {
  AppFabWidget({
    super.key,
    this.icon,
    this.onPressed,
    this.children = const [],
    this.bottomInset = 0,
    this.distance,
    this.fanAngle = 90,
    this.showOverlay = true,
    this.buttonSize = AppSizes.fabButtonSize,
    this.iconSize = AppSizes.iconLg,
    this.expandableKey,
  }) : assert(
         onPressed != null || children.isNotEmpty,
         'Provide onPressed or non-empty children',
       );

  final Widget? icon;
  final VoidCallback? onPressed;
  final GlobalKey<ExpandableFabState>? expandableKey;
  final List<Widget> children;
  final double bottomInset;
  final double? distance;
  final double fanAngle;
  final bool showOverlay;
  final double buttonSize;
  final double iconSize;

  bool get isExpandable => children.isNotEmpty;

  /// Use with [AppFabWidget] — pass [expandable] when [children] is non-empty.
  static FloatingActionButtonLocation scaffoldLocation({
    required double bottomInset,
    required bool expandable,
    double buttonSize = AppSizes.fabButtonSize,
  }) {
    if (expandable) return ExpandableFab.location;
    return AppFabScaffoldLocation(
      bottomInset: bottomInset,
      buttonSize: buttonSize,
    );
  }

  @Deprecated('Use scaffoldLocation(expandable: true) instead')
  static FloatingActionButtonLocation get expandableLocation =>
      ExpandableFab.location;

  @override
  Widget build(BuildContext context) {
    if (!isExpandable) {
      return _AppFabButton(
        icon: icon ?? const Icon(Icons.add_rounded),
        onTap: onPressed!,
        size: buttonSize,
        iconSize: iconSize,
      );
    }

    final colors = context.colors;
    final fabSize = buttonSize.s;

    FloatingActionButtonBuilder fabBuilder({
      required Widget child,
      required double angle,
    }) {
      return FloatingActionButtonBuilder(
        size: fabSize,
        builder: (context, onPressed, progress) {
          return AnimatedBuilder(
            animation: progress,
            builder: (context, _) {
              return Transform.rotate(
                angle: progress.value * angle,
                child: _AppFabButton(
                  icon: child,
                  onTap: onPressed ?? () {},
                  size: buttonSize,
                  iconSize: iconSize,
                ),
              );
            },
          );
        },
      );
    }

    return ExpandableFab(
      key: expandableKey,
      type: ExpandableFabType.fan,
      pos: ExpandableFabPos.left,
      fanAngle: fanAngle,
      distance: distance ?? 64.s,
      duration: const Duration(milliseconds: 220),
      childrenAnimation: ExpandableFabAnimation.rotate,
      margin: EdgeInsets.only(
        left: AppSpacing.pagePadding.s - kFloatingActionButtonMargin,
        bottom: bottomInset,
      ),
      overlayStyle: showOverlay
          ? ExpandableFabOverlayStyle(
              color: colors.overlay.withValues(alpha: 0.45),
            )
          : null,
      openButtonBuilder: fabBuilder(
        angle: math.pi / 4,
        child: icon ?? const Icon(Icons.add_rounded),
      ),
      closeButtonBuilder: fabBuilder(
        angle: 0,
        child: const Icon(Icons.close_rounded),
      ),
      children: children,
    );
  }
}

/// Styled child button for [AppFabWidget] menus.
class AppFabChildButton extends StatelessWidget {
  const AppFabChildButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.buttonSize = AppSizes.fabChildButtonSize,
    this.iconSize = AppSizes.iconLg,
    this.backgroundColor,
    this.foregroundColor,
  });

  final Widget icon;
  final VoidCallback onPressed;
  final double buttonSize;
  final double iconSize;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return _AppFabButton(
      icon: icon,
      onTap: onPressed,
      size: buttonSize,
      iconSize: iconSize,
      backgroundColor: backgroundColor ?? colors.card,
      foregroundColor: foregroundColor ?? colors.primary,
    );
  }
}

class _AppFabButton extends StatelessWidget {
  const _AppFabButton({
    required this.icon,
    required this.onTap,
    required this.size,
    required this.iconSize,
    this.backgroundColor,
    this.foregroundColor,
  });

  final Widget icon;
  final VoidCallback onTap;
  final double size;
  final double iconSize;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Material(
      color: backgroundColor ?? colors.primary,
      elevation: 2,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.medium.s),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: size.s,
          height: size.s,
          child: Center(
            child: IconTheme(
              data: IconThemeData(
                size: iconSize.s,
                color: foregroundColor ?? colors.onPrimary,
              ),
              child: icon,
            ),
          ),
        ),
      ),
    );
  }
}
