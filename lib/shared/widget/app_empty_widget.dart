import 'package:flutter/material.dart';
import 'package:keyva/core/theme/app_radius.dart';
import 'package:keyva/core/theme/app_sizes.dart';
import 'package:keyva/core/theme/app_spacing.dart';
import 'package:keyva/core/theme/app_typography.dart';
import 'package:keyva/core/theme/extensions/responsive_extentions.dart';
import 'package:keyva/core/theme/extensions/theme_extentions.dart';
import 'package:keyva/feature/home/model/vault_models.dart';
import 'package:keyva/shared/icons/app_icons.dart';
import 'package:keyva/shared/widget/app_buttom_widget.dart';

enum AppEmptyLayout { page, card, content }

class AppEmptyWidget extends StatelessWidget {
  const AppEmptyWidget({
    super.key,
    required this.icon,
    required this.title,
    this.description,
    this.actionLabel,
    this.onAction,
    this.layout = AppEmptyLayout.card,
    this.illustration,
  });

  final IconData icon;
  final String title;
  final String? description;
  final String? actionLabel;
  final VoidCallback? onAction;
  final AppEmptyLayout layout;
  final Widget? illustration;

  factory AppEmptyWidget.vault({Key? key, VoidCallback? onAction}) {
    return AppEmptyWidget(
      key: key,
      icon: AppIcon.lock,
      title: 'هنوز چیزی اضافه نکرده‌اید',
      description: 'اولین اطلاعات خود را به کیوا اضافه کنید.',
      actionLabel: onAction == null ? null : 'افزودن آیتم',
      onAction: onAction,
      layout: AppEmptyLayout.card,
    );
  }

  factory AppEmptyWidget.filteredResults() {
    return const AppEmptyWidget(
      icon: AppIcon.search,
      title: 'موردی یافت نشد',
      description: 'با این فیلترها آیتمی وجود ندارد.',
      layout: AppEmptyLayout.card,
    );
  }

  factory AppEmptyWidget.typeList(VaultItemType type) {
    switch (type) {
      case VaultItemType.login:
        return const AppEmptyWidget(
          icon: AppIcon.lock,
          title: 'هنوز ورودی ثبت نشده',
          description: 'اولین ورود خود را اضافه کنید.',
          layout: AppEmptyLayout.card,
        );
      case VaultItemType.bankCard:
        return const AppEmptyWidget(
          icon: AppIcon.creditCard,
          title: 'هنوز کارت بانکی ثبت نشده',
          description: 'اولین کارت بانکی خود را اضافه کنید.',
          layout: AppEmptyLayout.card,
        );
      case VaultItemType.secureNote:
        return const AppEmptyWidget(
          icon: AppIcon.stickyNote,
          title: 'هنوز یادداشتی ثبت نشده',
          description: 'اولین یادداشت امن خود را اضافه کنید.',
          layout: AppEmptyLayout.card,
        );
    }
  }

  factory AppEmptyWidget.categories() {
    return const AppEmptyWidget(
      icon: AppIcon.folder,
      title: 'هنوز دسته‌بندی ندارید',
      description: 'اولین دسته را با دکمه + بسازید.',
      layout: AppEmptyLayout.content,
    );
  }

  factory AppEmptyWidget.passwordHistory() {
    return const AppEmptyWidget(
      icon: AppIcon.history,
      title: 'تاریخچه خالی است',
      description: 'با کپی رمز از تولیدکننده، اینجا ذخیره می‌شود.',
      layout: AppEmptyLayout.card,
    );
  }

  factory AppEmptyWidget.searchIdle({String? typeLabel}) {
    final description = typeLabel == null
        ? 'عنوان یا توضیحات آیتم را جستجو کنید.'
        : 'عنوان یا توضیحات $typeLabel را جستجو کنید.';
    return AppEmptyWidget(
      icon: AppIcon.search,
      title: 'برای جستجو تایپ کنید',
      description: description,
      layout: AppEmptyLayout.content,
    );
  }

  factory AppEmptyWidget.searchNoResults() {
    return const AppEmptyWidget(
      icon: AppIcon.search,
      title: 'موردی یافت نشد',
      description: 'عبارت دیگری را امتحان کنید.',
      layout: AppEmptyLayout.content,
    );
  }

  @override
  Widget build(BuildContext context) {
    return switch (layout) {
      AppEmptyLayout.page => _buildPageLayout(context),
      AppEmptyLayout.card => _buildCardLayout(context),
      AppEmptyLayout.content => _buildContentLayout(context),
    };
  }

  Widget _buildPageLayout(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl.s),
      child: Column(
        children: [
          const Spacer(flex: 2),
          if (illustration != null)
            SizedBox(width: 220.w, height: 220.h, child: illustration),
          SizedBox(height: AppSpacing.xl.h),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTypography.titleLarge.copyWith(color: colors.textPrimary),
          ),
          if (description != null) ...[
            SizedBox(height: AppSpacing.md.h),
            Text(
              description!,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ],
          const Spacer(flex: 3),
          if (actionLabel != null && onAction != null)
            AppButtonWidget(
              title: actionLabel!,
              icon: Icon(AppIcon.add, size: AppSizes.iconMd.s),
              onPressed: onAction,
            ),
          SizedBox(height: AppSpacing.xxl.h),
        ],
      ),
    );
  }

  Widget _buildCardLayout(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(AppSpacing.lg.s),
      child: _buildCoreContent(context, titleStyle: AppTypography.titleMedium),
    );
  }

  Widget _buildContentLayout(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(AppSpacing.xl.s),
      child: _buildCoreContent(context, titleStyle: AppTypography.titleMedium),
    );
  }

  Widget _buildCoreContent(
    BuildContext context, {
    required TextStyle titleStyle,
  }) {
    final colors = context.colors;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _EmptyIconCircle(icon: icon),
        SizedBox(height: AppSpacing.md.h),
        Text(
          title,
          textAlign: TextAlign.center,
          style: titleStyle.copyWith(color: colors.textPrimary),
        ),
        if (description != null) ...[
          SizedBox(height: AppSpacing.sm.h),
          Text(
            description!,
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ],
        if (actionLabel != null && onAction != null) ...[
          SizedBox(height: AppSpacing.lg.h),
          AppButtonWidget(
            key: const Key('vault-home-empty-cta'),
            title: actionLabel!,
            icon: Icon(AppIcon.add, size: AppSizes.iconMd.s),
            onPressed: onAction,
          ),
        ],
      ],
    );
  }
}

class _EmptyIconCircle extends StatelessWidget {
  const _EmptyIconCircle({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      width: 56.s,
      height: 56.s,
      decoration: BoxDecoration(
        color: colors.input,
        borderRadius: BorderRadius.circular(AppRadius.medium),
      ),
      child: Icon(icon, size: AppSizes.iconXl.s, color: colors.textSecondary),
    );
  }
}
