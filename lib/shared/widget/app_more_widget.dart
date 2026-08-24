import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:keyva/core/theme/app_radius.dart';
import 'package:keyva/core/theme/app_sizes.dart';
import 'package:keyva/core/theme/app_spacing.dart';
import 'package:keyva/core/theme/app_typography.dart';
import 'package:keyva/core/theme/extensions/responsive_extentions.dart';
import 'package:keyva/core/theme/extensions/theme_extentions.dart';
import 'package:keyva/shared/icons/app_icons.dart';
import 'package:keyva/shared/widget/app_buttom_widget.dart';
import 'package:keyva/shared/widget/toast_widget.dart';

class AppMoreAction {
  const AppMoreAction({
    required this.label,
    this.value = '',
    this.toastMessage = '',
    this.onPressed,
    this.isDestructive = false,
    this.icon,
  });

  final String label;
  final String value;
  final String toastMessage;
  final VoidCallback? onPressed;
  final bool isDestructive;
  final IconData? icon;
}

class AppMoreWidget extends StatelessWidget {
  const AppMoreWidget({
    super.key,
    required this.dialogTitle,
    required this.actions,
    this.icon = AppIcon.ellipsis,
    this.iconSize,
    this.iconColor,
  });

  final String dialogTitle;
  final List<AppMoreAction> actions;
  final IconData icon;
  final double? iconSize;
  final Color? iconColor;

  static Future<void> show(
    BuildContext context, {
    required String title,
    required List<AppMoreAction> actions,
  }) {
    return showDialog<void>(
      context: context,
      barrierColor: context.colors.overlay,
      builder: (dialogContext) {
        return _AppMoreDialog(title: title, actions: actions);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return GestureDetector(
      onTap: () => show(context, title: dialogTitle, actions: actions),
      behavior: HitTestBehavior.opaque,
      child: Icon(
        icon,
        size: iconSize ?? AppSizes.iconMd.s,
        color: iconColor ?? colors.textSecondary,
      ),
    );
  }
}

class _AppMoreDialog extends StatelessWidget {
  const _AppMoreDialog({required this.title, required this.actions});

  final String title;
  final List<AppMoreAction> actions;

  void _copyAction(BuildContext context, AppMoreAction action) {
    if (action.value.isEmpty) return;
    Clipboard.setData(ClipboardData(text: action.value));
    AppToast.success(context, title: 'کپی', message: action.toastMessage);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Dialog(
      backgroundColor: colors.card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.modal),
      ),
      insetPadding: EdgeInsets.symmetric(horizontal: AppSpacing.xl.s),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg.s,
          AppSpacing.xl.s,
          AppSpacing.lg.s,
          AppSpacing.lg.s,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.titleMedium.copyWith(
                color: colors.textPrimary,
              ),
            ),
            if (actions.isNotEmpty) ...[
              SizedBox(height: AppSpacing.lg.s),
              for (var i = 0; i < actions.length; i++) ...[
                if (i > 0) SizedBox(height: AppSpacing.sm.s),
                AppButtonWidget(
                  title: actions[i].label,
                  icon: Icon(
                    actions[i].icon ??
                        (actions[i].onPressed != null
                            ? AppIcon.delete
                            : AppIcon.copy),
                    size: AppSizes.iconSm.s,
                  ),
                  backgroundColor: actions[i].isDestructive
                      ? colors.error.withValues(alpha: 0.12)
                      : colors.input,
                  foregroundColor: actions[i].isDestructive
                      ? colors.error
                      : colors.textPrimary,
                  onPressed: () {
                    final action = actions[i];
                    if (action.onPressed != null) {
                      Navigator.of(context).pop();
                      action.onPressed!();
                      return;
                    }
                    _copyAction(context, action);
                  },
                ),
              ],
            ],
            SizedBox(height: AppSpacing.lg.s),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'برگشت',
                  style: AppTypography.button.copyWith(color: colors.primary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
