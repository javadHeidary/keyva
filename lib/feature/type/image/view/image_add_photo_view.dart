import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keyva/core/constants/layout_constants.dart';
import 'package:keyva/core/theme/app_radius.dart';
import 'package:keyva/core/theme/app_sizes.dart';
import 'package:keyva/core/theme/app_spacing.dart';
import 'package:keyva/core/theme/extensions/responsive_extentions.dart';
import 'package:keyva/core/theme/extensions/theme_extentions.dart';
import 'package:keyva/feature/type/image/viewmodel/image_add_photo_viewmodel.dart';
import 'package:keyva/feature/vault/view/vault_error_view.dart';
import 'package:keyva/shared/icons/app_icons.dart';
import 'package:keyva/shared/widget/app_buttom_widget.dart';
import 'package:keyva/shared/widget/app_header_widget.dart';
import 'package:keyva/shared/widget/app_textfield_widget.dart';
import 'package:keyva/shared/widget/login_section_card_widget.dart';

class ImageAddPhotoView extends GetView<ImageAddPhotoViewModel> {
  const ImageAddPhotoView({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      key: const Key('vault-image-add-photo'),
      resizeToAvoidBottomInset: LayoutConstants.resizeToAvoidBottomInset,
      backgroundColor: colors.pageBackground,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: AppHeaderWidget(
                title: 'افزودن تصویر',
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
                AppSpacing.lg.h,
              ),
              sliver: SliverToBoxAdapter(
                child: AppSectionCardWidget(
                  children: [
                    Obx(() {
                      final data = controller.captured.value;
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.medium),
                        child: AspectRatio(
                          aspectRatio: data.width / data.height,
                          child: Image.memory(
                            data.bytes,
                            fit: BoxFit.cover,
                            gaplessPlayback: true,
                          ),
                        ),
                      );
                    }),
                    SizedBox(height: AppSpacing.lg.h),
                    AppTextFieldWidget(
                      controller: controller.noteController,
                      labelText: 'یادداشت (اختیاری)',
                      labelAlwaysVisible: true,
                      hintText: 'توضیح کوتاه درباره این عکس',
                      maxLines: 3,
                      minLines: 1,
                      textInputAction: TextInputAction.done,
                      fillColor: colors.card,
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.pagePadding.s,
                AppSpacing.md.h,
                AppSpacing.pagePadding.s,
                AppSpacing.xxl.h,
              ),
              sliver: SliverToBoxAdapter(
                child: Obx(() {
                  final error = controller.submitError.value;
                  return Column(
                    children: [
                      if (error != null && error.isNotEmpty)
                        VaultSubmitErrorText(message: error),
                      AppButtonWidget(
                        key: const Key('vault-image-save-photo'),
                        title: 'ذخیره تصویر',
                        isLoading: controller.isSubmitting.value,
                        onPressed: controller.submit,
                      ),
                      SizedBox(height: AppSpacing.md.h),
                      AppButtonWidget(
                        key: const Key('vault-image-retake'),
                        title: 'انتخاب مجدد',
                        backgroundColor: colors.secondaryButton,
                        foregroundColor: colors.textPrimary,
                        onPressed: controller.isSubmitting.value
                            ? null
                            : () => controller.retake(context),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
