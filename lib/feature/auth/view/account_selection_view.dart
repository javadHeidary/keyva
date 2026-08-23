import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keyva/core/theme/app_spacing.dart';
import 'package:keyva/core/theme/app_typography.dart';
import 'package:keyva/core/theme/extensions/responsive_extentions.dart';
import 'package:keyva/core/theme/extensions/theme_extentions.dart';
import 'package:keyva/feature/auth/model/account_summary.dart';
import 'package:keyva/feature/auth/view_model/account_selection_viewmodel.dart';
import 'package:keyva/shared/widget/app_buttom_widget.dart';

class AccountSelectionView extends GetView<AccountSelectionViewModel> {
  const AccountSelectionView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
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
    );
  }

  Widget _body(BuildContext context) {
    switch (controller.status.value) {
      case AccountSelectionStatus.initial:
      case AccountSelectionStatus.loading:
        return const Center(
          child: CircularProgressIndicator(key: Key('auth-accounts-loading')),
        );
      case AccountSelectionStatus.error:
        return _messageState(
          context,
          key: const Key('auth-accounts-error'),
          message: controller.errorMessage.value,
          action: AppButtonWidget(
            key: const Key('auth-accounts-retry'),
            title: 'تلاش دوباره',
            onPressed: controller.loadAccounts,
          ),
        );
      case AccountSelectionStatus.empty:
        return _messageState(
          context,
          key: const Key('auth-accounts-empty'),
          message: 'حسابی روی این دستگاه وجود ندارد.',
          action: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppButtonWidget(
                key: const Key('auth-accounts-register'),
                title: 'ثبت‌نام',
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
          ),
        );
      case AccountSelectionStatus.loaded:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('حساب‌های شما', style: AppTypography.titleLarge),
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
            _RegisterHint(onRegister: controller.openRegister),
            SizedBox(height: AppSpacing.md.h),
            _RestoreHint(onRestore: controller.openRestore),
          ],
        );
    }
  }

  Widget _messageState(
    BuildContext context, {
    required Key key,
    required String message,
    required Widget action,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Spacer(),
        Text(
          message,
          key: key,
          style: AppTypography.bodyLarge,
          textAlign: TextAlign.center,
        ),
        SizedBox(height: AppSpacing.sectionGap.h),
        action,
        const Spacer(flex: 2),
      ],
    );
  }
}

class _AccountTile extends StatelessWidget {
  const _AccountTile({required this.account});

  final AccountSummary account;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colors.card,
      borderRadius: BorderRadius.circular(18.s),
      child: InkWell(
        key: Key('auth-account-item-${account.id}'),
        borderRadius: BorderRadius.circular(18.s),
        onTap: () => Get.find<AccountSelectionViewModel>().selectAccount(
          account.id,
        ),
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg.s),
          child: Row(
            children: [
              Container(
                width: 56.s,
                height: 56.s,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: context.colors.strengthBarBg,
                  borderRadius: BorderRadius.circular(16.s),
                ),
                child: Text(account.initial, style: AppTypography.titleLarge),
              ),
              SizedBox(width: AppSpacing.lg.s),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(account.username, style: AppTypography.titleMedium),
                    SizedBox(height: AppSpacing.xs.h),
                    Text(
                      'ورود به حساب',
                      style: AppTypography.bodyMedium.copyWith(
                        color: context.colors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RegisterHint extends StatefulWidget {
  const _RegisterHint({required this.onRegister});

  final VoidCallback onRegister;

  @override
  State<_RegisterHint> createState() => _RegisterHintState();
}

class _RegisterHintState extends State<_RegisterHint> {
  late final TapGestureRecognizer _recognizer;

  @override
  void initState() {
    super.initState();
    _recognizer = TapGestureRecognizer()..onTap = widget.onRegister;
  }

  @override
  void dispose() {
    _recognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: Text.rich(
        TextSpan(
          text: 'اکانتی ندارید؟ ',
          style: AppTypography.bodyMedium.copyWith(
            color: context.colors.textTertiary,
          ),
          children: [
            TextSpan(
              text: 'ثبت‌نام',
              style: AppTypography.titleMedium.copyWith(
                color: context.colors.primary,
              ),
              recognizer: _recognizer,
            ),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _RestoreHint extends StatefulWidget {
  const _RestoreHint({required this.onRestore});

  final VoidCallback onRestore;

  @override
  State<_RestoreHint> createState() => _RestoreHintState();
}

class _RestoreHintState extends State<_RestoreHint> {
  late final TapGestureRecognizer _recognizer;

  @override
  void initState() {
    super.initState();
    _recognizer = TapGestureRecognizer()..onTap = widget.onRestore;
  }

  @override
  void dispose() {
    _recognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: Text.rich(
        TextSpan(
          text: 'فایل پشتیبان دارید؟ ',
          style: AppTypography.bodyMedium.copyWith(
            color: context.colors.textTertiary,
          ),
          children: [
            TextSpan(
              text: 'بازیابی',
              style: AppTypography.titleMedium.copyWith(
                color: context.colors.primary,
              ),
              recognizer: _recognizer,
            ),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
