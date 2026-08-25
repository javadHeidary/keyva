import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keyva/core/theme/app_radius.dart';
import 'package:keyva/core/theme/app_spacing.dart';
import 'package:keyva/core/theme/app_typography.dart';
import 'package:keyva/core/theme/extensions/responsive_extentions.dart';
import 'package:keyva/core/theme/extensions/theme_extentions.dart';
import 'package:keyva/feature/home/model/item_type_guide_content.dart';
import 'package:keyva/shared/widget/app_buttom_widget.dart';

Future<void> showItemTypeGuideDialog(
  BuildContext context, {
  required ItemTypeGuideContent content,
  required RxBool isSubmitting,
  required Future<void> Function() onCreateSample,
  required Future<void> Function() onDontShowAgain,
  required Future<void> Function() onGotIt,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: context.colors.overlay,
    barrierDismissible: true,
    builder: (dialogContext) {
      return ItemTypeGuideDialog(
        content: content,
        isSubmitting: isSubmitting,
        onCreateSample: onCreateSample,
        onDontShowAgain: onDontShowAgain,
        onGotIt: onGotIt,
      );
    },
  );
}

class ItemTypeGuideDialog extends StatelessWidget {
  const ItemTypeGuideDialog({
    super.key,
    required this.content,
    required this.isSubmitting,
    required this.onCreateSample,
    required this.onDontShowAgain,
    required this.onGotIt,
  });

  final ItemTypeGuideContent content;
  final RxBool isSubmitting;
  final Future<void> Function() onCreateSample;
  final Future<void> Function() onDontShowAgain;
  final Future<void> Function() onGotIt;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Dialog(
      backgroundColor: colors.card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.modal),
      ),
      insetPadding: EdgeInsets.symmetric(horizontal: AppSpacing.xxl.s),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.xl.s,
          AppSpacing.xxl.s,
          AppSpacing.xl.s,
          AppSpacing.xl.s,
        ),
        child: Obx(() {
          final submitting = isSubmitting.value;
          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  content.title,
                  textAlign: TextAlign.center,
                  style: AppTypography.headlineSmall.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
                SizedBox(height: AppSpacing.sm.s),
                Text(
                  content.description,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                SizedBox(height: AppSpacing.lg.s),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final example in content.examples)
                        Padding(
                          padding: EdgeInsets.only(bottom: AppSpacing.xs.s),
                          child: Text(
                            '• $example',
                            style: AppTypography.bodyMedium.copyWith(
                              color: colors.textPrimary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                SizedBox(height: AppSpacing.xl.s),
                AppButtonWidget(
                  key: const Key('item-type-guide-create-sample'),
                  title: 'ساخت نمونه',
                  isLoading: submitting,
                  enabled: !submitting,
                  onPressed: submitting ? null : onCreateSample,
                ),
                SizedBox(height: AppSpacing.sm.s),
                TextButton(
                  key: const Key('item-type-guide-dont-show-again'),
                  onPressed: submitting ? null : onDontShowAgain,
                  child: Text(
                    'دیگر نشان نده',
                    style: AppTypography.button.copyWith(
                      color: submitting
                          ? colors.textTertiary
                          : colors.textSecondary,
                    ),
                  ),
                ),
                TextButton(
                  key: const Key('item-type-guide-got-it'),
                  onPressed: submitting ? null : onGotIt,
                  child: Text(
                    'متوجه شدم',
                    style: AppTypography.button.copyWith(
                      color: submitting
                          ? colors.textTertiary
                          : colors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
