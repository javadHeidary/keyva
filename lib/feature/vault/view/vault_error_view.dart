import 'package:flutter/material.dart';
import 'package:keyva/core/theme/app_spacing.dart';
import 'package:keyva/core/theme/app_typography.dart';
import 'package:keyva/core/theme/extensions/responsive_extentions.dart';
import 'package:keyva/core/theme/extensions/theme_extentions.dart';
import 'package:keyva/shared/icons/app_icons.dart';
import 'package:keyva/shared/widget/app_buttom_widget.dart';
import 'package:keyva/shared/widget/app_empty_widget.dart';

class VaultErrorView extends StatelessWidget {
  const VaultErrorView({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl.s),
      child: Column(
        children: [
          const Spacer(flex: 2),
          AppEmptyWidget(
            icon: AppIcon.lock,
            title: 'بارگذاری گاوصندوق ممکن نشد',
            description: message,
            layout: AppEmptyLayout.content,
          ),
          const Spacer(flex: 2),
          AppButtonWidget(
            key: const Key('vault-home-retry'),
            title: 'تلاش دوباره',
            onPressed: onRetry,
          ),
          SizedBox(height: AppSpacing.xxl.h),
        ],
      ),
    );
  }
}

class VaultSubmitErrorText extends StatelessWidget {
  const VaultSubmitErrorText({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.only(bottom: AppSpacing.md.h),
      child: Text(
        message,
        key: const Key('vault-form-error'),
        textAlign: TextAlign.center,
        style: AppTypography.bodyMedium.copyWith(color: context.colors.error),
      ),
    );
  }
}
