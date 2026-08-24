import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keyva/core/theme/app_radius.dart';
import 'package:keyva/core/theme/app_sizes.dart';
import 'package:keyva/core/theme/app_spacing.dart';
import 'package:keyva/core/theme/app_typography.dart';
import 'package:keyva/core/theme/extensions/responsive_extentions.dart';
import 'package:keyva/core/theme/extensions/theme_extentions.dart';
import 'package:keyva/feature/auth/model/account_summary.dart';
import 'package:keyva/feature/auth/view_model/account_selection_viewmodel.dart';
import 'package:keyva/feature/auth/widget/auth_error_toast_binder.dart';
import 'package:keyva/feature/auth/widget/auth_footer_link.dart';
import 'package:keyva/shared/icons/app_icons.dart';
import 'package:keyva/shared/widget/app_buttom_widget.dart';
import 'package:keyva/shared/widget/app_empty_widget.dart';
import 'package:keyva/shared/widget/app_loading_widger.dart';
import 'package:keyva/shared/widget/keyva_logo.dart';

class AccountSelectionView extends GetView<AccountSelectionViewModel> {
  const AccountSelectionView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AuthErrorToastBinder(
        message: controller.errorMessage,
        child: SafeArea(
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.pagePadding.s,
                vertical: AppSpacing.pagePadding.h,
              ),
              child: Obx(() => _body(context)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context) {
    switch (controller.status.value) {
      case AccountSelectionStatus.initial:
      case AccountSelectionStatus.loading:
        return AppLoadingWidget(
          key: const Key('auth-accounts-loading'),
          layout: AppLoadingLayout.page,
        );
      case AccountSelectionStatus.error:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Center(
                child: AppEmptyWidget(
                  key: const Key('auth-accounts-error'),
                  icon: AppIcon.warning,
                  title: controller.errorMessage.value,
                  description: 'لطفاً دوباره تلاش کنید.',
                  layout: AppEmptyLayout.content,
                ),
              ),
            ),
            AppButtonWidget(
              key: const Key('auth-accounts-retry'),
              title: 'تلاش دوباره',
              onPressed: controller.loadAccounts,
            ),
          ],
        );
      case AccountSelectionStatus.empty:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Center(
                child: AppEmptyWidget(
                  key: const Key('auth-accounts-empty'),
                  icon: AppIcon.accountCircle,
                  title: 'حسابی روی این دستگاه وجود ندارد.',
                  description:
                      'یک حساب جدید بسازید یا از فایل پشتیبان بازیابی کنید.',
                  layout: AppEmptyLayout.content,
                ),
              ),
            ),
            AppButtonWidget(
              key: const Key('auth-accounts-register'),
              title: 'ایجاد حساب',
              onPressed: controller.openRegister,
            ),
            SizedBox(height: AppSpacing.md.h),
            TextButton(
              key: const Key('auth-accounts-restore'),
              onPressed: controller.openRestore,
              child: Text(
                'بازیابی پشتیبان',
                style: AppTypography.titleMedium.copyWith(
                  color: context.colors.primary,
                ),
              ),
            ),
          ],
        );
      case AccountSelectionStatus.loaded:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'حساب‌های شما',
              style: AppTypography.headlineMedium.copyWith(
                color: context.colors.textPrimary,
              ),
            ),
            SizedBox(height: AppSpacing.sm.h),
            Text(
              'حساب مورد نظر را برای ورود انتخاب کنید',
              style: AppTypography.bodyMedium.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
            SizedBox(height: AppSpacing.sectionGap.h),
            Expanded(
              child: ListView.separated(
                key: const Key('auth-accounts-list'),
                itemCount: controller.accounts.length,
                separatorBuilder: (_, _) => SizedBox(height: AppSpacing.md.h),
                itemBuilder: (context, index) {
                  return _AccountTile(account: controller.accounts[index]);
                },
              ),
            ),
            AuthFooterLink(
              prefix: 'حسابی ندارید؟ ',
              actionLabel: 'ایجاد حساب',
              onTap: controller.openRegister,
            ),
            SizedBox(height: AppSpacing.md.h),
            AuthFooterLink(
              prefix: 'فایل پشتیبان دارید؟ ',
              actionLabel: 'بازیابی',
              onTap: controller.openRestore,
            ),
          ],
        );
    }
  }
}

class _AccountTile extends StatelessWidget {
  const _AccountTile({required this.account});

  final AccountSummary account;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.card,
      borderRadius: BorderRadius.circular(AppRadius.card.s),
      child: InkWell(
        key: Key('auth-account-item-${account.id}'),
        borderRadius: BorderRadius.circular(AppRadius.card.s),
        onTap: () =>
            Get.find<AccountSelectionViewModel>().selectAccount(account.id),
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg.s),
          child: Row(
            children: [
              KeyvaLogo(size: AppSizes.appBarHeight.s),
              SizedBox(width: AppSpacing.lg.s),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.username,
                      style: AppTypography.titleMedium.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                    SizedBox(height: AppSpacing.xs.h),
                    Text(
                      'ادامه برای ورود',
                      style: AppTypography.bodyMedium.copyWith(
                        color: colors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                AppIcon.chevronLeft,
                size: AppSizes.iconMd.s,
                color: colors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
