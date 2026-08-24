import 'dart:async';

import 'package:flutter/material.dart';
import 'package:keyva/core/theme/app_radius.dart';
import 'package:keyva/core/theme/app_spacing.dart';
import 'package:keyva/core/theme/app_typography.dart';
import 'package:keyva/core/theme/extensions/responsive_extentions.dart';
import 'package:keyva/core/theme/extensions/theme_extentions.dart';

// ============================================================
// TOAST TYPE
// ============================================================

enum AppToastType { neutral, info, success, warning, error }

// ============================================================
// TOAST POSITION
// ============================================================

enum AppToastPosition { top, right }

// ============================================================
// TOAST CONFIG
// ============================================================

class AppToastConfig {
  final String title;
  final String? message;
  final AppToastType type;
  final AppToastPosition position;
  final Duration duration;
  final VoidCallback? onClose;
  final bool showCloseButton;

  const AppToastConfig({
    required this.title,
    this.message,
    this.type = AppToastType.neutral,
    this.position = AppToastPosition.top,
    this.duration = const Duration(seconds: 4),
    this.onClose,
    this.showCloseButton = true,
  });
}

// ============================================================
// TOAST SERVICE (Overlay based)
// ============================================================

class AppToast {
  static OverlayEntry? _currentEntry;
  static Timer? _timer;

  /// Show a toast. If another toast is already visible, it will be
  /// dismissed first and the new one will appear.
  ///
  /// [title] is the short operation heading. [message] is the description
  /// of what happened or what the user should do next.
  static void show(
    BuildContext context, {
    required String title,
    String? message,
    AppToastType type = AppToastType.neutral,
    AppToastPosition position = AppToastPosition.top,
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onClose,
    bool showCloseButton = true,
  }) {
    // Dismiss previous if exists
    dismiss();

    final overlay = Overlay.of(context, rootOverlay: true);

    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) {
        return _ToastOverlay(
          config: AppToastConfig(
            title: title,
            message: message,
            type: type,
            position: position,
            duration: duration,
            onClose: onClose,
            showCloseButton: showCloseButton,
          ),
          onDismiss: () {
            entry.remove();
            _currentEntry = null;
            _timer?.cancel();
            _timer = null;
            onClose?.call();
          },
        );
      },
    );

    _currentEntry = entry;
    overlay.insert(entry);

    // Auto dismiss
    _timer = Timer(duration, () {
      dismiss();
    });
  }

  /// Dismiss the currently visible toast (if any)
  static void dismiss() {
    _timer?.cancel();
    _timer = null;
    _currentEntry?.remove();
    _currentEntry = null;
  }

  // Convenience methods
  static void neutral(
    BuildContext context, {
    required String title,
    String? message,
    AppToastPosition position = AppToastPosition.top,
    Duration duration = const Duration(seconds: 4),
  }) {
    show(
      context,
      title: title,
      message: message,
      type: AppToastType.neutral,
      position: position,
      duration: duration,
    );
  }

  static void info(
    BuildContext context, {
    required String title,
    String? message,
    AppToastPosition position = AppToastPosition.top,
    Duration duration = const Duration(seconds: 4),
  }) {
    show(
      context,
      title: title,
      message: message,
      type: AppToastType.info,
      position: position,
      duration: duration,
    );
  }

  static void success(
    BuildContext context, {
    required String title,
    required String message,
    AppToastPosition position = AppToastPosition.top,
    Duration duration = const Duration(seconds: 4),
  }) {
    show(
      context,
      title: title,
      message: message,
      type: AppToastType.success,
      position: position,
      duration: duration,
    );
  }

  static void warning(
    BuildContext context, {
    required String title,
    String? message,
    AppToastPosition position = AppToastPosition.top,
    Duration duration = const Duration(seconds: 4),
  }) {
    show(
      context,
      title: title,
      message: message,
      type: AppToastType.warning,
      position: position,
      duration: duration,
    );
  }

  static void error(
    BuildContext context, {
    required String title,
    String? message,
    AppToastPosition position = AppToastPosition.top,
    Duration duration = const Duration(seconds: 4),
  }) {
    show(
      context,
      title: title,
      message: message,
      type: AppToastType.error,
      position: position,
      duration: duration,
    );
  }
}

// ============================================================
// INTERNAL OVERLAY WIDGET
// ============================================================

class _ToastOverlay extends StatefulWidget {
  final AppToastConfig config;
  final VoidCallback onDismiss;

  const _ToastOverlay({required this.config, required this.onDismiss});

  @override
  State<_ToastOverlay> createState() => _ToastOverlayState();
}

class _ToastOverlayState extends State<_ToastOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
      reverseDuration: const Duration(milliseconds: 220),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    final isRight = widget.config.position == AppToastPosition.right;

    _slideAnimation =
        Tween<Offset>(
          begin: isRight ? Offset(1.0.s, 0.0) : Offset(0.0, -0.35.s),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _controller,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          ),
        );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    await _controller.reverse();
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final isRight = widget.config.position == AppToastPosition.right;

    return Positioned(
      top: media.padding.top + AppSpacing.lg,
      right: isRight ? media.padding.right + AppSpacing.md : AppSpacing.md,
      left: isRight ? null : AppSpacing.md,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Material(
            color: Colors.transparent,
            child: _ToastCard(config: widget.config, onClose: _dismiss),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// TOAST CARD (Visual)
// ============================================================

class _ToastCard extends StatelessWidget {
  final AppToastConfig config;
  final VoidCallback onClose;

  const _ToastCard({required this.config, required this.onClose});

  Color _accentColor(AppColorsExtension colors) {
    switch (config.type) {
      case AppToastType.neutral:
        return colors.neutral;
      case AppToastType.info:
        return colors.info;
      case AppToastType.success:
        return colors.success;
      case AppToastType.warning:
        return colors.warning;
      case AppToastType.error:
        return colors.error;
    }
  }

  IconData _icon() {
    switch (config.type) {
      case AppToastType.neutral:
        return Icons.info_rounded;
      case AppToastType.info:
        return Icons.notifications_rounded;
      case AppToastType.success:
        return Icons.check_rounded;
      case AppToastType.warning:
        return Icons.warning_amber_rounded;
      case AppToastType.error:
        return Icons.block_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = _accentColor(colors);
    final isDark = context.isDark;

    // Soft colored glow under the card (matches the design)
    final List<BoxShadow> shadows = [
      BoxShadow(
        color: accent.withValues(alpha: isDark ? 0.28 : 0.18),
        blurRadius: AppRadius.xLarge,
        offset: Offset(0, 6.s),
        spreadRadius: -2,
      ),
      BoxShadow(
        color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
        blurRadius: AppRadius.medium,
        offset: Offset(0, 3.s),
      ),
    ];

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 380.s),
      child: Container(
        padding: EdgeInsetsDirectional.fromSTEB(
          AppSpacing.md.s,
          AppSpacing.md.s,
          AppSpacing.md.s,
          AppSpacing.md.s,
        ),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(AppRadius.card),
          boxShadow: shadows,
          border: Border.all(
            color: colors.border.withValues(alpha: 0.6),
            width: 0.8.w,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon circle
            Container(
              width: 36.s,
              height: 36.s,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: isDark ? 0.18 : 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(_icon(), size: 20, color: accent),
            ),

            SizedBox(width: AppSpacing.md.s),

            // Texts
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    config.title,
                    style: AppTypography.titleMedium.copyWith(
                      color: colors.textPrimary,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (config.message != null && config.message!.isNotEmpty) ...[
                    SizedBox(height: AppSpacing.xxs.s),
                    Text(
                      config.message!,
                      style: AppTypography.bodySmall.copyWith(
                        color: colors.textSecondary,
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            // Close button
            if (config.showCloseButton) ...[
              SizedBox(width: AppSpacing.xs.s),
              GestureDetector(
                onTap: onClose,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.xs.s),
                  child: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: colors.textTertiary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
