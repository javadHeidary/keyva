import 'package:flutter/material.dart';
import 'package:keyva/core/theme/app_colors.dart';
import 'package:keyva/core/theme/app_radius.dart';
import 'package:keyva/core/theme/app_shadows.dart';
import 'package:keyva/core/theme/app_spacing.dart';

import '../app_sizes.dart';

// ============================================================
// COLORS EXTENSION
// ============================================================

class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  final Color primary;
  final Color primaryHover;
  final Color onPrimary;

  final Color pageBackground;
  final Color card;
  final Color elevated;
  final Color input;
  final Color inputFocus;
  final Color disabled;

  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;

  final Color border;
  final Color borderFocus;
  final Color borderError;

  final Color success;
  final Color warning;
  final Color error;
  final Color strengthBarBg;

  final Color accent;

  final Color divider;
  final Color overlay;

  final Color secondaryButton;

  const AppColorsExtension({
    required this.primary,
    required this.primaryHover,
    required this.onPrimary,
    required this.pageBackground,
    required this.card,
    required this.elevated,
    required this.input,
    required this.inputFocus,
    required this.disabled,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.border,
    required this.borderFocus,
    required this.borderError,
    required this.success,
    required this.warning,
    required this.error,
    required this.strengthBarBg,
    required this.accent,
    required this.divider,
    required this.overlay,
    required this.secondaryButton,
  });

  static const light = AppColorsExtension(
    primary: AppColors.primaryLight,
    primaryHover: AppColors.primaryHoverLight,
    onPrimary: AppColors.onPrimaryLight,
    pageBackground: AppColors.pageBackgroundLight,
    card: AppColors.cardLight,
    elevated: AppColors.elevatedLight,
    input: AppColors.inputLight,
    inputFocus: AppColors.inputFocusLight,
    disabled: AppColors.disabledLight,
    textPrimary: AppColors.textPrimaryLight,
    textSecondary: AppColors.textSecondaryLight,
    textTertiary: AppColors.textTertiaryLight,
    border: AppColors.borderLight,
    borderFocus: AppColors.borderFocusLight,
    borderError: AppColors.borderErrorLight,
    success: AppColors.successLight,
    warning: AppColors.warningLight,
    error: AppColors.errorLight,
    strengthBarBg: AppColors.strengthBarBgLight,
    accent: AppColors.accent,
    divider: AppColors.dividerLight,
    overlay: AppColors.overlayLight,
    secondaryButton: AppColors.secondaryButtonLight,
  );

  static const dark = AppColorsExtension(
    primary: AppColors.primaryDark,
    primaryHover: AppColors.primaryHoverDark,
    onPrimary: AppColors.onPrimaryDark,
    pageBackground: AppColors.pageBackgroundDark,
    card: AppColors.cardDark,
    elevated: AppColors.elevatedDark,
    input: AppColors.inputDark,
    inputFocus: AppColors.inputFocusDark,
    disabled: AppColors.disabledDark,
    textPrimary: AppColors.textPrimaryDark,
    textSecondary: AppColors.textSecondaryDark,
    textTertiary: AppColors.textTertiaryDark,
    border: AppColors.borderDark,
    borderFocus: AppColors.borderFocusDark,
    borderError: AppColors.borderErrorDark,
    success: AppColors.successDark,
    warning: AppColors.warningDark,
    error: AppColors.errorDark,
    strengthBarBg: AppColors.strengthBarBgDark,
    accent: AppColors.accent,
    divider: AppColors.dividerDark,
    overlay: AppColors.overlayDark,
    secondaryButton: AppColors.secondaryButtonDark,
  );

  @override
  AppColorsExtension copyWith({
    Color? primary,
    Color? primaryHover,
    Color? onPrimary,
    Color? pageBackground,
    Color? card,
    Color? elevated,
    Color? input,
    Color? inputFocus,
    Color? disabled,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? border,
    Color? borderFocus,
    Color? borderError,
    Color? success,
    Color? warning,
    Color? error,
    Color? strengthBarBg,
    Color? accent,
    Color? divider,
    Color? overlay,
    Color? secondaryButton,
  }) {
    return AppColorsExtension(
      primary: primary ?? this.primary,
      primaryHover: primaryHover ?? this.primaryHover,
      onPrimary: onPrimary ?? this.onPrimary,
      pageBackground: pageBackground ?? this.pageBackground,
      card: card ?? this.card,
      elevated: elevated ?? this.elevated,
      input: input ?? this.input,
      inputFocus: inputFocus ?? this.inputFocus,
      disabled: disabled ?? this.disabled,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      border: border ?? this.border,
      borderFocus: borderFocus ?? this.borderFocus,
      borderError: borderError ?? this.borderError,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      strengthBarBg: strengthBarBg ?? this.strengthBarBg,
      accent: accent ?? this.accent,
      divider: divider ?? this.divider,
      overlay: overlay ?? this.overlay,
      secondaryButton: secondaryButton ?? this.secondaryButton,
    );
  }

  @override
  AppColorsExtension lerp(ThemeExtension<AppColorsExtension>? other, double t) {
    if (other is! AppColorsExtension) return this;

    return AppColorsExtension(
      primary: Color.lerp(primary, other.primary, t)!,
      primaryHover: Color.lerp(primaryHover, other.primaryHover, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      pageBackground: Color.lerp(pageBackground, other.pageBackground, t)!,
      card: Color.lerp(card, other.card, t)!,
      elevated: Color.lerp(elevated, other.elevated, t)!,
      input: Color.lerp(input, other.input, t)!,
      inputFocus: Color.lerp(inputFocus, other.inputFocus, t)!,
      disabled: Color.lerp(disabled, other.disabled, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderFocus: Color.lerp(borderFocus, other.borderFocus, t)!,
      borderError: Color.lerp(borderError, other.borderError, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      error: Color.lerp(error, other.error, t)!,
      strengthBarBg: Color.lerp(strengthBarBg, other.strengthBarBg, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      overlay: Color.lerp(overlay, other.overlay, t)!,
      secondaryButton: Color.lerp(secondaryButton, other.secondaryButton, t)!,
    );
  }
}

// ============================================================
// SHADOWS EXTENSION
// ============================================================

class AppShadowsExtension extends ThemeExtension<AppShadowsExtension> {
  final List<BoxShadow> card;
  final List<BoxShadow> elevated;

  const AppShadowsExtension({required this.card, required this.elevated});

  static final light = AppShadowsExtension(
    card: AppShadows.cardLight,
    elevated: AppShadows.elevatedLight,
  );

  static final dark = AppShadowsExtension(
    card: AppShadows.cardDark,
    elevated: AppShadows.elevatedDark,
  );

  @override
  AppShadowsExtension copyWith({
    List<BoxShadow>? card,
    List<BoxShadow>? elevated,
  }) {
    return AppShadowsExtension(
      card: card ?? this.card,
      elevated: elevated ?? this.elevated,
    );
  }

  @override
  AppShadowsExtension lerp(
    ThemeExtension<AppShadowsExtension>? other,
    double t,
  ) {
    if (other is! AppShadowsExtension) return this;
    return t < 0.5 ? this : other;
  }
}

// ============================================================
// BUILD CONTEXT EXTENSIONS (Easy Access)
// ============================================================

extension ThemeContextExtension on BuildContext {
  /// Access theme-aware colors
  /// Example: context.colors.primary
  AppColorsExtension get colors =>
      Theme.of(this).extension<AppColorsExtension>()!;

  /// Access theme-aware shadows
  /// Example: context.shadows.card
  AppShadowsExtension get shadows =>
      Theme.of(this).extension<AppShadowsExtension>()!;

  /// Spacing tokens (constant)
  AppSpacing get spacing => AppSpacing();

  /// Radius tokens (constant)
  AppRadius get radius => AppRadius();

  /// Size tokens (constant)
  AppSizes get sizes => AppSizes();

  /// Quick brightness check
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  bool get isLight => Theme.of(this).brightness == Brightness.light;
}

// Keep these simple classes accessible if needed without context
