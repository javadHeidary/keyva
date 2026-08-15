import 'package:flutter/material.dart';
import 'package:keyva/core/theme/app_radius.dart';
import 'package:keyva/core/theme/app_spacing.dart';
import 'package:keyva/core/theme/app_typography.dart';
import 'package:keyva/core/theme/extensions/responsive_extentions.dart';
import 'package:keyva/core/theme/extensions/theme_extentions.dart';
import 'package:keyva/feature/settings/model/faq_item.dart';
import 'package:persian_number_utility/persian_number_utility.dart';

Future<void> showFaqGuideBottomSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.colors.card,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppRadius.modal),
      ),
    ),
    builder: (sheetContext) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          final colors = context.colors;

          return Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg.s,
              AppSpacing.md.s,
              AppSpacing.lg.s,
              AppSpacing.lg.s,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40.s,
                    height: 4.s,
                    decoration: BoxDecoration(
                      color: colors.divider,
                      borderRadius: BorderRadius.circular(AppRadius.ssm),
                    ),
                  ),
                ),
                SizedBox(height: AppSpacing.md.h),
                Text(
                  'سوالات متداول و راهنما',
                  textAlign: TextAlign.center,
                  style: AppTypography.titleMedium.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
                SizedBox(height: AppSpacing.lg.h),
                Expanded(
                  child: ListView.separated(
                    controller: scrollController,
                    itemCount: FaqContent.items.length,
                    separatorBuilder: (_, __) => SizedBox(height: AppSpacing.sm.h),
                    itemBuilder: (context, index) {
                      final item = FaqContent.items[index];
                      final number = (index + 1).toString().toPersianDigit();

                      return _FaqExpansionTile(
                        number: number,
                        item: item,
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

class _FaqExpansionTile extends StatelessWidget {
  const _FaqExpansionTile({required this.number, required this.item});

  final String number;
  final FaqItem item;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.symmetric(horizontal: AppSpacing.sm.s),
        childrenPadding: EdgeInsets.fromLTRB(
          AppSpacing.lg.s,
          0,
          AppSpacing.lg.s,
          AppSpacing.md.s,
        ),
        title: Text(
          '$number. ${item.question}',
          style: AppTypography.withFaNum(
            AppTypography.bodyMedium.copyWith(color: colors.textPrimary),
          ),
        ),
        iconColor: colors.textSecondary,
        collapsedIconColor: colors.textSecondary,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              item.answer,
              textAlign: TextAlign.right,
              style: AppTypography.bodySmall.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
