import 'package:flutter/material.dart';
import 'package:keyva/core/theme/app_radius.dart';
import 'package:keyva/core/theme/app_spacing.dart';
import 'package:keyva/core/theme/app_typography.dart';
import 'package:keyva/core/theme/extensions/responsive_extentions.dart';
import 'package:keyva/core/theme/extensions/theme_extentions.dart';
import 'package:keyva/feature/type/image/service/image_capture_service.dart';
import 'package:keyva/shared/icons/app_icons.dart';

Future<ImageCaptureSource?> showImageSourceSheet(BuildContext context) {
  return showModalBottomSheet<ImageCaptureSource>(
    context: context,
    backgroundColor: context.colors.card,
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
            children: [
              Container(
                width: 40.s,
                height: 4.s,
                decoration: BoxDecoration(
                  color: colors.divider,
                  borderRadius: BorderRadius.circular(AppRadius.ssm),
                ),
              ),
              SizedBox(height: AppSpacing.lg.h),
              Text(
                'افزودن تصویر',
                style: AppTypography.titleMedium.copyWith(
                  color: colors.textPrimary,
                ),
              ),
              SizedBox(height: AppSpacing.lg.h),
              ListTile(
                key: const Key('image-source-camera'),
                leading: Icon(AppIcon.camera, color: colors.textPrimary),
                title: Text(
                  'دوربین',
                  style: AppTypography.bodyLarge.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
                onTap: () => Navigator.pop(
                  sheetContext,
                  ImageCaptureSource.camera,
                ),
              ),
              ListTile(
                key: const Key('image-source-gallery'),
                leading: Icon(AppIcon.image, color: colors.textPrimary),
                title: Text(
                  'گالری',
                  style: AppTypography.bodyLarge.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
                onTap: () => Navigator.pop(
                  sheetContext,
                  ImageCaptureSource.gallery,
                ),
              ),
              SizedBox(height: AppSpacing.sm.h),
            ],
          ),
        ),
      );
    },
  );
}
