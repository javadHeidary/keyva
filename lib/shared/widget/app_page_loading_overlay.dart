import 'package:flutter/material.dart';
import 'package:keyva/core/theme/extensions/theme_extentions.dart';
import 'package:keyva/shared/widget/app_loading_widger.dart';

class AppPageLoadingOverlay extends StatefulWidget {
  const AppPageLoadingOverlay({
    super.key,
    required this.visible,
    required this.child,
    this.message,
  });

  static const overlayKey = Key('app-page-loading');
  static const barrierKey = Key('app-page-loading-barrier');

  final bool visible;
  final Widget child;
  final String? message;

  @override
  State<AppPageLoadingOverlay> createState() => _AppPageLoadingOverlayState();
}

class _AppPageLoadingOverlayState extends State<AppPageLoadingOverlay> {
  @override
  void initState() {
    super.initState();
    if (widget.visible) {
      _unfocus();
    }
  }

  @override
  void didUpdateWidget(covariant AppPageLoadingOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible && !oldWidget.visible) {
      _unfocus();
    }
  }

  void _unfocus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusManager.instance.primaryFocus?.unfocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !widget.visible,
      child: Stack(
        fit: StackFit.expand,
        children: [
          AbsorbPointer(absorbing: widget.visible, child: widget.child),
          if (widget.visible) ...[
            ModalBarrier(
              key: AppPageLoadingOverlay.barrierKey,
              dismissible: false,
              color: context.colors.overlay,
            ),
            IgnorePointer(
              child: AppLoadingWidget(
                key: AppPageLoadingOverlay.overlayKey,
                layout: AppLoadingLayout.page,
                message: widget.message,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
