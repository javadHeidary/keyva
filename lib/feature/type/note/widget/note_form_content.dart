import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keyva/core/theme/app_sizes.dart';
import 'package:keyva/core/theme/app_spacing.dart';
import 'package:keyva/core/theme/extensions/responsive_extentions.dart';
import 'package:keyva/core/theme/extensions/theme_extentions.dart';
import 'package:keyva/feature/type/login/widget/login_section_card.dart';
import 'package:keyva/feature/type/note/viewmodel/note_form_viewmodel.dart';
import 'package:keyva/shared/widget/app_dropdown_widget.dart';
import 'package:keyva/shared/widget/app_textfield_widget.dart';

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
      child: LoginSectionCard(
        children: [
          Obx(() {
            final categories = controller.selectableCategories;
            final items = [
              const AppDropdownItem<String?>(
                value: null,
                label: 'بدون دسته‌بندی',
                icon: Icon(Icons.label_off_outlined),
              ),
              ...categories.map(
                (category) => AppDropdownItem<String?>(
                  value: category.id,
                  label: category.name,
                ),
              ),
            ];

            return AppDropdownWidget<String?>(
              value: controller.selectedCategoryId.value,
              hint: 'بدون دسته‌بندی',
              items: items,
              labelText: 'دسته‌بندی',
              labelAlwaysVisible: true,
              useOutlinedStyle: true,
              fillColor: fieldFill,
              leadingIcon: Icon(
                Icons.folder_outlined,
                size: AppSizes.iconMd.s,
                color: colors.textSecondary,
              ),
              onChanged: controller.onCategoryChanged,
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
