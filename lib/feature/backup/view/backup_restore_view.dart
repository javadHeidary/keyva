import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keyva/core/routes/app_routing.dart';
import 'package:keyva/core/theme/app_sizes.dart';
import 'package:keyva/core/theme/app_spacing.dart';
import 'package:keyva/core/theme/app_typography.dart';
import 'package:keyva/core/theme/extensions/responsive_extentions.dart';
import 'package:keyva/core/theme/extensions/theme_extentions.dart';
import 'package:keyva/feature/backup/viewmodel/restore_viewmodel.dart';
import 'package:keyva/feature/backup/widget/create_backup_dialog.dart';
import 'package:keyva/feature/backup/widget/restore_backup_password_dialog.dart';
import 'package:keyva/feature/backup/widget/restore_confirm_dialog.dart';
import 'package:keyva/feature/backup/widget/restore_progress_overlay.dart';
import 'package:keyva/feature/settings/widget/settings_group_card.dart';
import 'package:keyva/feature/settings/widget/settings_row.dart';
import 'package:keyva/shared/icons/app_icons.dart';
import 'package:keyva/shared/widget/app_header_widget.dart';
import 'package:keyva/shared/widget/app_title_item_widget.dart';

class BackupRestoreView extends StatelessWidget {
  const BackupRestoreView({super.key, this.createAccountMode = false});

  final bool createAccountMode;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.pageBackground,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: AppHeaderWidget(
                title: 'پشتیبان‌گیری و بازیابی',
                titleAlign: TextAlign.center,
                leading: Icon(
                  AppIcon.arrowBack,
                  size: AppSizes.iconLg.s,
                  color: colors.textPrimary,
                ),
                onLeadingTap: Get.back,
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.pagePadding.s,
                AppSpacing.sm.h,
                AppSpacing.pagePadding.s,
                AppSpacing.hugePlus.h,
              ),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!createAccountMode) ...[
                      const AppTitleItemWidget(title: 'پشتیبان‌گیری'),
                      Text(
                        'یک فایل رمزنگاری‌شده از اطلاعات Vault ایجاد کنید.',
                        textAlign: TextAlign.right,
                        style: AppTypography.bodySmall.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                      SizedBox(height: AppSpacing.sm.h),
                      SettingsGroupCard(
                        children: [
                          KeyedSubtree(
                            key: const Key('backup-restore-create'),
                            child: SettingsRow.nav(
                              title: 'ایجاد پشتیبان',
                              icon: AppIcon.backup,
                              onTap: () => showCreateBackupDialog(context),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: AppSpacing.sectionGap.h),
                    ],
                    const AppTitleItemWidget(title: 'بازیابی پشتیبان'),
                    Text(
                      createAccountMode
                          ? 'فایل پشتیبان را انتخاب کنید. سپس برای این دستگاه یک رمز اصلی جدید می‌سازید.'
                          : 'اطمینان حاصل کنید که فایل پشتیبان متعلق به Keyva است.',
                      textAlign: TextAlign.right,
                      style: AppTypography.bodySmall.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                    SizedBox(height: AppSpacing.sm.h),
                    SettingsGroupCard(
                      children: [
                        KeyedSubtree(
                          key: const Key('backup-restore-restore'),
                          child: SettingsRow.nav(
                            title: 'بازیابی پشتیبان',
                            icon: AppIcon.restore,
                            onTap: () => _startRestore(context),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startRestore(BuildContext context) async {
    final restore = Get.find<RestoreViewModel>();
    final selected = await restore.pickBackup(context);
    if (!selected || !context.mounted) {
      return;
    }

    await showRestoreBackupPasswordDialog(context);
    if (!context.mounted) {
      restore.cancelRestore();
      return;
    }
    if (!restore.hasPendingRestore) {
      restore.cancelRestore();
      return;
    }

    final preview = restore.pendingPreview;
    if (preview == null) {
      restore.cancelRestore();
      return;
    }

    final confirmed = await showRestoreConfirmDialog(
      context,
      title: restore.createsNewAccount ? 'بازیابی پشتیبان' : 'هشدار',
      description: restore.createsNewAccount
          ? preview.newAccountDescription
          : preview.confirmationDescription,
      confirmText: restore.createsNewAccount ? 'ادامه' : 'جایگزینی',
    );
    if (!context.mounted) {
      restore.cancelRestore();
      return;
    }
    if (!confirmed) {
      restore.cancelRestore();
      return;
    }
    if (restore.createsNewAccount) {
      Get.toNamed(AppRoutes.authRestoreSetup);
      return;
    }
    await runRestoreWithProgressOverlay(
      context: context,
      restore: restore,
      action: () => restore.confirmRestore(context),
    );
  }
}
