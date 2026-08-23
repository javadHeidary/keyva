import 'package:flutter/material.dart';
import 'package:keyva/core/theme/app_typography.dart';
import 'package:keyva/core/theme/extensions/responsive_extentions.dart';
import 'package:keyva/core/theme/extensions/theme_extentions.dart';
import 'package:keyva/shared/icons/app_icons.dart';

class AppSearchHeaderWidget extends StatelessWidget {
  const AppSearchHeaderWidget({
    super.key,
    this.controller,
    this.hintText = 'جستجو...',
    this.onChanged,
    this.onSubmitted,
    this.trailing,
    this.onTrailingTap,
    this.padding,
    this.readOnly = false,
    this.onTap,
    this.focusNode,
  });

  final TextEditingController? controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  final Widget? trailing;
  final VoidCallback? onTrailingTap;

  final EdgeInsetsGeometry? padding;

  final bool readOnly;
  final VoidCallback? onTap;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    // final colors = context.colors;

    return Padding(
      padding:
          padding ?? EdgeInsets.symmetric(horizontal: 16.s, vertical: 12.s),
      child: Row(
        children: [
          Expanded(
            child: _SearchField(
              controller: controller,
              hintText: hintText,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              readOnly: readOnly,
              onTap: onTap,
              focusNode: focusNode,
            ),
          ),

          if (trailing != null) ...[
            SizedBox(width: 12.s),
            _HeaderIconButton(onTap: onTrailingTap, child: trailing!),
          ],
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    this.controller,
    required this.hintText,
    this.onChanged,
    this.onSubmitted,
    this.readOnly = false,
    this.onTap,
    this.focusNode,
  });

  final TextEditingController? controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool readOnly;
  final VoidCallback? onTap;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return SizedBox(
      height: 48.s,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        readOnly: readOnly,
        onTap: onTap,
        style: AppTypography.bodyMedium.copyWith(color: colors.textPrimary),
        cursorColor: colors.primary,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: AppTypography.bodyMedium.copyWith(
            color: colors.textTertiary,
          ),
          prefixIcon: Icon(
            AppIcon.search,
            size: 22.s,
            color: colors.textSecondary,
          ),
          filled: true,
          fillColor: colors.input,
          contentPadding: EdgeInsets.symmetric(horizontal: 16.s, vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.s),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.s),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.s),
            borderSide: BorderSide(color: colors.borderFocus, width: 1.5),
          ),
        ),
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
