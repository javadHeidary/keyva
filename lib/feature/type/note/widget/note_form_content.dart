import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keyva/core/theme/app_sizes.dart';
import 'package:keyva/core/theme/app_spacing.dart';
import 'package:keyva/core/theme/extensions/responsive_extentions.dart';
import 'package:keyva/core/theme/extensions/theme_extentions.dart';
import 'package:keyva/feature/category/widget/category_selector_field.dart';
import 'package:keyva/feature/type/note/viewmodel/note_form_viewmodel.dart';
import 'package:keyva/shared/widget/app_textfield_widget.dart';
import 'package:keyva/shared/widget/login_section_card_widget.dart';

class NoteFormContent extends StatelessWidget {
  const NoteFormContent({super.key, required this.controller});

  final NoteFormViewModel controller;

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
            labelText: 'عنوان',
            labelAlwaysVisible: true,
            hintText: 'مثلاً کدهای بازیابی',
            textInputAction: TextInputAction.next,
            fillColor: fieldFill,
            prefixIcon: Icon(
              Icons.title_rounded,
              size: AppSizes.iconMd.s,
              color: colors.textSecondary,
            ),
            validator: controller.validateTitle,
          ),
          SizedBox(height: _fieldGap.h),
          AppTextFieldWidget(
            controller: controller.notesController,
            labelText: 'یادداشت',
            labelAlwaysVisible: true,
            hintText: 'متن یادداشت را وارد کنید',
            textInputAction: TextInputAction.newline,
            fillColor: fieldFill,
            minLines: 6,
            maxLines: 16,
            prefixIcon: Icon(
              Icons.notes_rounded,
              size: AppSizes.iconMd.s,
              color: colors.textSecondary,
            ),
            validator: controller.validateNotes,
          ),
        ],
      ),
    );
  }
}
