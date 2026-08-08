import 'package:flutter/material.dart';
import 'package:keyva/core/theme/app_typography.dart';
import 'package:keyva/core/theme/extensions/responsive_extentions.dart';
import 'package:keyva/core/theme/extensions/theme_extentions.dart';

class AppHeaderWidget extends StatelessWidget {
  const AppHeaderWidget({
    super.key,
    this.title,
    this.leading,
    this.trailing,
    this.onLeadingTap,
    this.onTrailingTap,
    this.titleAlign = TextAlign.center,
    this.showBottomBorder = false,
    this.padding,
  });

  final String? title;

  final Widget? leading;

  final Widget? trailing;

  final VoidCallback? onLeadingTap;
  final VoidCallback? onTrailingTap;

  final TextAlign titleAlign;

  final bool showBottomBorder;

  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding:
          padding ?? EdgeInsets.symmetric(horizontal: 16.s, vertical: 12.s),
      decoration: showBottomBorder
          ? BoxDecoration(
              border: Border(
                bottom: BorderSide(color: colors.divider, width: 1),
              ),
            )
          : null,
      child: Row(
        children: [
          if (leading != null)
            _HeaderIconButton(onTap: onLeadingTap, child: leading!)
          else
            SizedBox(width: 40.s),

          Expanded(
            child: title != null
                ? Text(
                    title!,
                    textAlign: titleAlign,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.titleLarge.copyWith(
                      color: colors.textPrimary,
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          if (trailing != null)
            _HeaderIconButton(onTap: onTrailingTap, child: trailing!)
          else
            SizedBox(width: 40.s),
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20.s),
        child: SizedBox(
          width: 40.s,
          height: 40.s,
          child: Center(child: child),
        ),
      ),
    );
  }
}
