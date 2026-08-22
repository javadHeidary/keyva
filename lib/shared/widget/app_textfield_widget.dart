import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:keyva/core/theme/app_radius.dart';
import 'package:keyva/core/theme/app_spacing.dart';
import 'package:keyva/core/theme/app_typography.dart';
import 'package:keyva/core/theme/extensions/theme_extentions.dart';

class AppTextFieldWidget extends StatefulWidget {
  const AppTextFieldWidget({
    super.key,
    this.controller,
    this.focusNode,
    this.labelText,
    this.hintText,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.keyboardType,
    this.textInputAction,
    this.textDirection,
    this.onChanged,
    this.onFieldSubmitted,
    this.onTap,
    this.validator,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.inputFormatters,
    this.autovalidateMode,
    this.textAlign = TextAlign.start,
    this.labelAlwaysVisible = false,
    this.fillColor,
    this.enableInteractiveSelection,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? labelText;
  final String? hintText;
  final String? errorText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final bool enabled;
  final bool readOnly;
  final bool autofocus;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextDirection? textDirection;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final VoidCallback? onTap;
  final FormFieldValidator<String>? validator;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final AutovalidateMode? autovalidateMode;
  final TextAlign textAlign;
  final bool labelAlwaysVisible;
  final Color? fillColor;
  final bool? enableInteractiveSelection;

  @override
  State<AppTextFieldWidget> createState() => _AppTextFieldWidgetState();
}

class _AppTextFieldWidgetState extends State<AppTextFieldWidget> {
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(covariant AppTextFieldWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNode != oldWidget.focusNode) {
      _focusNode.removeListener(_handleFocusChange);
      _focusNode = widget.focusNode ?? FocusNode();
      _focusNode.addListener(_handleFocusChange);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _handleFocusChange() {
    if (_isFocused != _focusNode.hasFocus) {
      setState(() => _isFocused = _focusNode.hasFocus);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bool hasError =
        widget.errorText != null && widget.errorText!.isNotEmpty;

    final Color fillColor = widget.fillColor ??
        (!widget.enabled
            ? colors.disabled
            : _isFocused
            ? colors.inputFocus
            : colors.input);

    final Color borderColor = hasError
        ? colors.borderError
        : _isFocused
        ? colors.borderFocus
        : colors.border;

    final double borderWidth = (_isFocused || hasError) ? 1.5 : 1.0;

    final field = TextFormField(
      controller: widget.controller,
      focusNode: _focusNode,
      obscureText: widget.obscureText,
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      autofocus: widget.autofocus,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      textDirection: widget.textDirection,
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onFieldSubmitted,
      onTap: widget.onTap,
      validator: widget.validator,
      maxLines: widget.obscureText ? 1 : widget.maxLines,
      minLines: widget.minLines,
      maxLength: widget.maxLength,
      inputFormatters: widget.inputFormatters,
      autovalidateMode: widget.autovalidateMode,
      textAlign: widget.textAlign,
      enableInteractiveSelection: widget.enableInteractiveSelection,
      style: AppTypography.bodyMedium.copyWith(
        color: widget.enabled ? colors.textPrimary : colors.textTertiary,
      ),
      cursorColor: colors.primary,
      decoration: InputDecoration(
        labelText: widget.labelAlwaysVisible ? null : widget.labelText,
        hintText: widget.hintText,
        errorText: widget.errorText,
        floatingLabelBehavior: widget.labelAlwaysVisible
            ? FloatingLabelBehavior.never
            : null,
        prefixIcon: widget.prefixIcon != null
            ? Padding(
                padding: const EdgeInsetsDirectional.only(
                  start: AppSpacing.lg,
                  end: AppSpacing.sm,
                ),
                child: widget.prefixIcon,
              )
            : null,
        suffixIcon: widget.suffixIcon != null
            ? Padding(
                padding: const EdgeInsetsDirectional.only(
                  start: AppSpacing.sm,
                  end: AppSpacing.lg,
                ),
                child: widget.suffixIcon,
              )
            : null,
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        filled: true,
        fillColor: fillColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide(color: borderColor, width: borderWidth),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide(color: borderColor, width: borderWidth),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide(color: borderColor, width: borderWidth),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide(color: colors.borderError, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide(color: colors.borderError, width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide(color: colors.border, width: 1),
        ),
        labelStyle: AppTypography.bodyMedium.copyWith(
          color: colors.textSecondary,
        ),
        floatingLabelStyle: AppTypography.bodyMedium.copyWith(
          color: hasError
              ? colors.borderError
              : _isFocused
              ? colors.borderFocus
              : colors.textSecondary,
        ),
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: colors.textTertiary,
        ),
        errorStyle: AppTypography.bodySmall.copyWith(color: colors.error),
      ),
    );

    if (!widget.labelAlwaysVisible || widget.labelText == null) {
      return field;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.labelText!,
          style: AppTypography.labelLarge.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        field,
      ],
    );
  }
}
