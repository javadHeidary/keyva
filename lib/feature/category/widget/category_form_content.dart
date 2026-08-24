import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:keyva/core/theme/app_spacing.dart';
import 'package:keyva/core/theme/app_typography.dart';
import 'package:keyva/core/theme/extensions/responsive_extentions.dart';
import 'package:keyva/core/theme/extensions/theme_extentions.dart';
import 'package:keyva/feature/category/model/category_constants.dart';
import 'package:keyva/feature/category/viewmodel/category_form_viewmodel.dart';
import 'package:keyva/feature/category/widget/category_icon_picker.dart';
import 'package:keyva/shared/widget/app_textfield_widget.dart';
import 'package:keyva/shared/widget/app_title_item_widget.dart';
import 'package:keyva/shared/widget/login_section_card_widget.dart';

class CategoryFormContent extends StatelessWidget {
  const CategoryFormContent({super.key, required this.controller});

  final CategoryFormViewModel controller;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final fieldFill = colors.card;

    return Form(
      key: controller.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppTitleItemWidget(title: 'مشخصات دسته'),
          AppSectionCardWidget(
            children: [
              AppTextFieldWidget(
                controller: controller.nameController,
                labelText: 'نام دسته‌بندی',
                labelAlwaysVisible: true,
                hintText: 'مثلاً کاری، شخصی',
                textInputAction: TextInputAction.done,
                fillColor: fieldFill,
                validator: controller.validateName,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(CategoryConstants.maxNameLength),
                ],
              ),
              SizedBox(height: AppSpacing.lg.h),
              Text(
                'آیکون دسته',
                style: AppTypography.labelLarge.copyWith(
                  color: colors.textPrimary,
                ),
              ),
              SizedBox(height: AppSpacing.sm.h),
              Obx(
                () => CategoryIconPicker(
                  selectedIconId: controller.selectedIconId.value,
                  onSelected: controller.selectIcon,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
