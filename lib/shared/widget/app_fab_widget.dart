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
  const AppFabScaffoldLocation({required this.bottomInset});

  final double bottomInset;

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    final fabSize = scaffoldGeometry.floatingActionButtonSize;
    final scaffoldSize = scaffoldGeometry.scaffoldSize;

    return Offset(
      AppSpacing.pagePadding.s,
      scaffoldSize.height - fabSize.height - bottomInset,
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
  }) : assert(
         onPressed != null || children.isNotEmpty,
         'Provide onPressed or non-empty children',
       );

  final Widget? icon;
  final VoidCallback? onPressed;
  final List<Widget> children;
  final double bottomInset;
  final double? distance;
  final double fanAngle;
  final bool showOverlay;

  static const double _fabSize = 45;

  bool get _isExpandable => children.isNotEmpty;

  static FloatingActionButtonLocation get expandableLocation =>
      ExpandableFab.location;

  @override
  Widget build(BuildContext context) {
    if (!_isExpandable) {
      return _AppFabButton(
        icon: icon ?? const Icon(Icons.add_rounded),
        onTap: onPressed!,
      );
    }

    final colors = context.colors;
    final fabSize = _fabSize.s;

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
                ),
              );
            },
          );
        },
      );
    }

    return ExpandableFab(
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
          ? ExpandableFabOverlayStyle(color: colors.overlay.withValues(alpha: 0.45))
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
    this.backgroundColor,
    this.foregroundColor,
  });

  final Widget icon;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return _AppFabButton(
      icon: icon,
      onTap: onPressed,
      size: 40,
      backgroundColor: backgroundColor ?? colors.card,
      foregroundColor: foregroundColor ?? colors.primary,
    );
  }
}

class _AppFabButton extends StatelessWidget {
  const _AppFabButton({
    required this.icon,
    required this.onTap,
    this.size = AppFabWidget._fabSize,
    this.backgroundColor,
    this.foregroundColor,
  });

  final Widget icon;
  final VoidCallback onTap;
  final double size;
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
                size: AppSizes.iconLg.s,
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
