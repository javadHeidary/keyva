import 'package:flutter/material.dart';
import 'package:keyva/core/theme/app_radius.dart';
import 'package:keyva/core/theme/app_sizes.dart';
import 'package:keyva/core/theme/app_spacing.dart';
import 'package:keyva/core/theme/app_typography.dart';
import 'package:keyva/core/theme/extensions/responsive_extentions.dart';
import 'package:keyva/core/theme/extensions/theme_extentions.dart';

class AppFabSpeedDialAction {
  const AppFabSpeedDialAction({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
}

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

class AppFloatingActionButton extends StatefulWidget {
  AppFloatingActionButton({
    super.key,
    this.onPressed,
    this.icon = Icons.add_rounded,
    this.actions,
  }) : assert(
         onPressed != null || (actions != null && actions.isNotEmpty),
         'Provide onPressed or non-empty actions',
       );

  final VoidCallback? onPressed;
  final IconData icon;
  final List<AppFabSpeedDialAction>? actions;

  bool get _isSpeedDial => actions != null && actions!.isNotEmpty;

  @override
  State<AppFloatingActionButton> createState() =>
      _AppFloatingActionButtonState();
}

class _AppFloatingActionButtonState extends State<AppFloatingActionButton>
    with SingleTickerProviderStateMixin {
  static const _duration = Duration(milliseconds: 220);
  static const _staggerFraction = 0.1;

  final _fabKey = GlobalKey();
  late final AnimationController _controller;
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _duration);
    _controller.addListener(_markOverlayNeedsBuild);
  }

  @override
  void dispose() {
    _controller.removeListener(_markOverlayNeedsBuild);
    _removeOverlay();
    _controller.dispose();
    super.dispose();
  }

  void _markOverlayNeedsBuild() {
    final entry = _overlayEntry;
    if (entry == null) return;
    entry.markNeedsBuild();
  }

  void _toggle() {
    if (_isOpen) {
      _close();
    } else {
      _open();
    }
  }

  void _open() {
    setState(() => _isOpen = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_isOpen) return;
      _insertOverlay();
      _controller.forward(from: 0);
    });
  }

  void _close() {
    if (!_isOpen) return;
    setState(() => _isOpen = false);
    _controller.reverse().whenComplete(() {
      if (!mounted) return;
      _removeOverlay();
    });
  }

  void _closeAndRun(VoidCallback action) {
    if (!_isOpen) {
      action();
      return;
    }
    setState(() => _isOpen = false);
    _controller.stop();
    _controller.value = 0;
    _removeOverlay();
    // Defer navigation so Overlay teardown does not conflict with route build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      action();
    });
  }

  void _insertOverlay() {
    if (_overlayEntry != null) return;
    final overlay = Overlay.of(context);
    _overlayEntry = OverlayEntry(
      builder: (context) => _SpeedDialOverlay(
        fabKey: _fabKey,
        actions: widget.actions!,
        animation: _controller,
        onActionTap: _onActionTap,
        onDismiss: _close,
      ),
    );
    overlay.insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _onActionTap(AppFabSpeedDialAction action) {
    _closeAndRun(action.onPressed);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget._isSpeedDial) {
      return _FabButton(
        icon: widget.icon,
        onTap: widget.onPressed!,
      );
    }

    return _FabButton(
      key: _fabKey,
      icon: _isOpen ? Icons.close_rounded : Icons.add_rounded,
      onTap: _toggle,
      animatedIcon: true,
    );
  }
}

class _FabButton extends StatelessWidget {
  const _FabButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.animatedIcon = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool animatedIcon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 45.s,
        height: 45.s,
        decoration: BoxDecoration(
          color: colors.primary,
          borderRadius: BorderRadius.circular(AppRadius.medium),
        ),
        child: Center(
          child: animatedIcon
              ? AnimatedSwitcher(
                  duration: _AppFloatingActionButtonState._duration,
                  child: Icon(
                    icon,
                    key: ValueKey(icon),
                    size: AppSizes.iconLg.s,
                    color: colors.onPrimary,
                  ),
                )
              : Icon(
                  icon,
                  size: AppSizes.iconLg.s,
                  color: colors.onPrimary,
                ),
        ),
      ),
    );
  }
}

class _SpeedDialOverlay extends StatelessWidget {
  const _SpeedDialOverlay({
    required this.fabKey,
    required this.actions,
    required this.animation,
    required this.onActionTap,
    required this.onDismiss,
  });

  final GlobalKey fabKey;
  final List<AppFabSpeedDialAction> actions;
  final Animation<double> animation;
  final ValueChanged<AppFabSpeedDialAction> onActionTap;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final renderBox = fabKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) {
      return const SizedBox.shrink();
    }

    final fabOffset = renderBox.localToGlobal(Offset.zero);
    final screenSize = MediaQuery.sizeOf(context);
    // Column sits just above the FAB with AppSpacing.md gap.
    final actionsBottom =
        screenSize.height - fabOffset.dy + AppSpacing.md.h;

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: onDismiss,
            behavior: HitTestBehavior.translucent,
          ),
        ),
        Positioned(
          left: fabOffset.dx,
          bottom: actionsBottom,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = actions.length - 1; i >= 0; i--) ...[
                _SpeedDialAction(
                  action: actions[i],
                  animation: animation,
                  staggerIndex: actions.length - 1 - i,
                  onTap: () => onActionTap(actions[i]),
                ),
                if (i > 0) SizedBox(height: AppSpacing.md.h),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SpeedDialAction extends StatelessWidget {
  const _SpeedDialAction({
    required this.action,
    required this.animation,
    required this.staggerIndex,
    required this.onTap,
  });

  final AppFabSpeedDialAction action;
  final Animation<double> animation;
  final int staggerIndex;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final shadows = context.shadows;
    final start = staggerIndex * _AppFloatingActionButtonState._staggerFraction;
    final end = (start + 0.75).clamp(0.0, 1.0);

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final t = Interval(start, end, curve: Curves.easeOutCubic).transform(
          animation.value,
        );
        return Transform.translate(
          offset: Offset(0, (1 - t) * AppSpacing.md.h),
          child: Opacity(opacity: t, child: child),
        );
      },
      // LTR + fixed icon column so all three icons stack exactly above the FAB.
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 45.s,
              height: 45.s,
              child: _FabButton(icon: action.icon, onTap: onTap),
            ),
            SizedBox(width: AppSpacing.sm.s),
            DecoratedBox(
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: BorderRadius.circular(AppRadius.medium),
                border: Border.all(
                  color: colors.border,
                  width: AppSizes.inputBorderWidth,
                ),
                boxShadow: shadows.card,
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.md.s,
                  vertical: AppSpacing.sm.s,
                ),
                child: Text(
                  action.label,
                  style: AppTypography.labelLarge.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
