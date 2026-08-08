import 'package:flutter/material.dart';
import 'package:keyva/core/theme/app_sizes.dart';
import 'package:keyva/core/theme/app_spacing.dart';
import 'package:keyva/core/theme/extensions/responsive_extentions.dart';
import 'package:keyva/core/theme/extensions/theme_extentions.dart';
import 'package:keyva/shared/widget/app_dropdown_widget.dart';
import 'package:keyva/shared/widget/app_list_item_widget.dart';
import 'package:keyva/shared/widget/app_password_display_widget.dart';

class WidgetBuilderTest extends StatelessWidget {
  const WidgetBuilderTest({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            AppListItemWidget(
              leadingIcon: Icon(
                Icons.more_vert,
                color: context.colors.textSecondary,
              ),
              onLeadingPressed: () {},
              title: 'عنوان آیتم',
              subtitle: 'توضیحات فرعی',
              trailingIcon: Icon(
                Icons.lock_outline,
                color: context.colors.textTertiary,
              ),
              onTap: () {},
            ),
            SizedBox(height: AppSpacing.md.h),
            AppDropdownWidget<String>(
              // value: controller.selectedCategory.value,
              hint: 'دسته‌بندی را انتخاب کنید',
              items: [
                AppDropdownItem(
                  value: 'work',
                  label: 'کاری',
                  icon: Icon(Icons.work_outline, size: AppSizes.iconMd.s),
                ),
                AppDropdownItem(
                  value: 'personal',
                  label: 'شخصی',
                  icon: Icon(Icons.person_outline, size: AppSizes.iconMd.s),
                ),
              ],
              onChanged: (value) {
                // controller.selectedCategory.value = value;
              },
              trailingIcon: Icon(
                Icons.folder_outlined,
                size: AppSizes.iconMd.s,
              ),
            ),

            AppListItemWidget(
              title: 'متن مورد نظر',
              trailingIcon: Icon(
                Icons.folder_outlined,
                size: AppSizes.iconMd.s,
              ), // یا leadingIcon
              onTap: () {},
            ),

            AppPasswordDisplayWiget(
              leadingIcon: Icon(Icons.lock_outline, size: AppSizes.iconMd.s),
              password: '1234567890',
              isVisible: true,
              onToggleVisibility: () {},
              onCopy: () {},
            ),
          ],
        ),
      ),
    );
  }
}
