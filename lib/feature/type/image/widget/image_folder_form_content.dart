import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keyva/core/theme/app_sizes.dart';
import 'package:keyva/core/theme/app_spacing.dart';
import 'package:keyva/core/theme/extensions/responsive_extentions.dart';
import 'package:keyva/core/theme/extensions/theme_extentions.dart';
import 'package:keyva/feature/category/widget/category_selector_field.dart';
import 'package:keyva/feature/type/image/viewmodel/image_folder_form_viewmodel.dart';
import 'package:keyva/shared/icons/app_icons.dart';
import 'package:keyva/shared/widget/app_textfield_widget.dart';
import 'package:keyva/shared/widget/login_section_card_widget.dart';

class ImageFolderFormContent extends StatelessWidget {
  const ImageFolderFormContent({super.key, required this.controller});

  final ImageFolderFormViewModel controller;

  static const _fieldGap = AppSpacing.lg;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final fieldFill = colors.card;

    return Form(
      key: controller.formKey,
      child: AppSectionCardWidget(
        children: [
          Obx(() {
            return CategorySelectorField(
              selectedId: controller.selectedCategoryId.value,
              categories: controller.selectableCategories,
              onChanged: controller.onCategoryChanged,
              onCreate: controller.createInlineCategory,
              fillColor: fieldFill,
            );
          }),
          SizedBox(height: _fieldGap.h),
          AppTextFieldWidget(
            controller: controller.titleController,
            labelText: 'عنوان پوشه',
            labelAlwaysVisible: true,
            hintText: 'مثلاً عکس‌های شناسنامه',
            textInputAction: TextInputAction.done,
            fillColor: fieldFill,
            prefixIcon: Icon(
              AppIcon.images,
              size: AppSizes.iconMd.s,
              color: colors.textSecondary,
            ),
            validator: controller.validateTitle,
          ),
        ],
      ),
    );
  }
}
