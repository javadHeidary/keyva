import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keyva/core/theme/app_radius.dart';
import 'package:keyva/core/theme/app_sizes.dart';
import 'package:keyva/core/theme/app_spacing.dart';
import 'package:keyva/core/theme/app_typography.dart';
import 'package:keyva/core/theme/extensions/responsive_extentions.dart';
import 'package:keyva/core/theme/extensions/theme_extentions.dart';
import 'package:keyva/feature/settings/viewmodel/settings_viewmodel.dart';
import 'package:keyva/shared/icons/app_icons.dart';

Future<void> showContactUsBottomSheet(BuildContext context) {
  final controller = Get.find<SettingsViewModel>();

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.colors.pageBackground,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppRadius.modal),
      ),
    ),
    builder: (sheetContext) {
      final colors = sheetContext.colors;

      return SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg.s,
            AppSpacing.md.s,
            AppSpacing.lg.s,
            AppSpacing.lg.s,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ارتباط با ما',
                          style: AppTypography.titleMedium.copyWith(
                            color: colors.textPrimary,
                          ),
                        ),
                        SizedBox(height: AppSpacing.xs.h),
                        Text(
                          'برای ارتباط با ما یکی از راه‌های زیر را انتخاب کنید.',
                          style: AppTypography.bodySmall.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    key: const Key('contact-close'),
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    icon: Icon(
                      AppIcon.close,
                      size: AppSizes.iconMd.s,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.md.h),
              _ContactOptionCard(
                key: const Key('contact-telegram'),
                icon: AppIcon.send,
                title: 'تلگرام',
                description:
                    'ارتباط مستقیم برای پیگیری سریع‌تر مسائل و پرسش‌های شما.',
                onTap: () async {
                  final opened = await controller.openTelegram(sheetContext);
                  if (opened && sheetContext.mounted) {
                    Navigator.of(sheetContext).pop();
                  }
                },
              ),
              SizedBox(height: AppSpacing.sm.h),
              _ContactOptionCard(
                key: const Key('contact-bale'),
                icon: AppIcon.messageSquare,
                title: 'بله',
                description:
                    'ارتباط مستقیم برای پیگیری سریع‌تر مسائل و پرسش‌های شما.',
                onTap: () async {
                  final opened = await controller.openBale(sheetContext);
                  if (opened && sheetContext.mounted) {
                    Navigator.of(sheetContext).pop();
                  }
                },
              ),
              SizedBox(height: AppSpacing.sm.h),
              _ContactOptionCard(
                key: const Key('contact-email'),
                icon: AppIcon.mail,
                title: 'ایمیل',
                description:
                    'ارسال درخواست، گزارش مشکل یا دریافت پاسخ از تیم پشتیبانی کیوا.',
                onTap: () async {
                  final opened = await controller.openSupportEmail(
                    sheetContext,
                  );
                  if (opened && sheetContext.mounted) {
                    Navigator.of(sheetContext).pop();
                  }
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _ContactOptionCard extends StatelessWidget {
  const _ContactOptionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Material(
      color: colors.card,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.md.s),
          child: Row(
            children: [
              Container(
                width: 40.s,
                height: 40.s,
                decoration: BoxDecoration(
                  color: colors.backgroundInput,
                  borderRadius: BorderRadius.circular(AppRadius.medium),
                ),
                child: Icon(
                  icon,
                  size: AppSizes.iconMd.s,
                  color: colors.primary,
                ),
              ),
              SizedBox(width: AppSpacing.md.s),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.titleSmall.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2.s),
                    Text(
                      description,
                      style: AppTypography.bodySmall.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                AppIcon.externalLink,
                size: AppSizes.iconSm.s,
                color: colors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
