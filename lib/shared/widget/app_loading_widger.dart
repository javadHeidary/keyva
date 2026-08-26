import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:keyva/core/theme/app_sizes.dart';
import 'package:keyva/core/theme/app_spacing.dart';
import 'package:keyva/core/theme/app_typography.dart';
import 'package:keyva/core/theme/extensions/responsive_extentions.dart';
import 'package:keyva/core/theme/extensions/theme_extentions.dart';

enum AppLoadingLayout { page, section, inline }

class AppLoadingWidget extends StatelessWidget {
  const AppLoadingWidget({
    super.key,
    this.layout = AppLoadingLayout.section,
    this.color,
    this.size,
    this.message,
  });

  final AppLoadingLayout layout;
  final Color? color;
  final double? size;
  final String? message;

  factory AppLoadingWidget.page({String? message, Color? color}) {
    return AppLoadingWidget(
      layout: AppLoadingLayout.page,
      message: message,
      color: color,
    );
  }

  factory AppLoadingWidget.section({Color? color}) {
    return AppLoadingWidget(
      layout: AppLoadingLayout.section,
      color: color,
    );
  }

  factory AppLoadingWidget.inline({Color? color, double? size}) {
    return AppLoadingWidget(
      layout: AppLoadingLayout.inline,
      color: color,
      size: size,
    );
  }

  static Widget indicator({
    required BuildContext context,
    required AppLoadingLayout layout,
    Color? color,
    double? size,
  }) {
    final colors = context.colors;
    final effectiveColor = color ?? switch (layout) {
      AppLoadingLayout.inline => colors.onPrimary,
      AppLoadingLayout.page || AppLoadingLayout.section => colors.primary,
    };
    final effectiveSize = size ?? switch (layout) {
      AppLoadingLayout.page => AppSizes.loadingPage.s,
      AppLoadingLayout.section => AppSizes.loadingSection.s,
      AppLoadingLayout.inline => AppSizes.loadingInline.s,
    };

    return switch (layout) {
      AppLoadingLayout.inline => SpinKitCircle(
          color: effectiveColor,
          size: effectiveSize,
        ),
      AppLoadingLayout.page || AppLoadingLayout.section => SpinKitFadingFour(
          color: effectiveColor,
          size: effectiveSize,
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    return switch (layout) {
      AppLoadingLayout.page => _buildPageLayout(context),
      AppLoadingLayout.section => _buildSectionLayout(context),
      AppLoadingLayout.inline => indicator(
          context: context,
          layout: layout,
          color: color,
          size: size,
        ),
    };
  }

  Widget _buildPageLayout(BuildContext context) {
    final colors = context.colors;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.pagePadding.s,
          vertical: AppSpacing.xl.s,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            indicator(
              context: context,
              layout: AppLoadingLayout.page,
              color: color,
              size: size,
            ),
            if (message != null) ...[
              SizedBox(height: AppSpacing.md.h),
              Text(
                message!,
                textAlign: TextAlign.center,
                softWrap: true,
                style: AppTypography.bodyMedium.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLayout(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(AppSpacing.lg.s),
      child: Center(
        child: indicator(
          context: context,
          layout: AppLoadingLayout.section,
          color: color,
          size: size,
        ),
      ),
    );
  }
}
