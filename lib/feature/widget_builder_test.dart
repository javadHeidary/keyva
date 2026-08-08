import 'package:flutter/material.dart';
import 'package:keyva/core/theme/app_sizes.dart';
import 'package:keyva/core/theme/app_spacing.dart';
import 'package:keyva/core/theme/extensions/responsive_extentions.dart';
import 'package:keyva/core/theme/extensions/theme_extentions.dart';
import 'package:keyva/shared/widget/app_dropdown_widget.dart';
import 'package:keyva/shared/widget/app_header_widget.dart';
import 'package:keyva/shared/widget/app_list_item_widget.dart';
import 'package:keyva/shared/widget/app_password_display_widget.dart';
import 'package:keyva/shared/widget/app_search_header_widger.dart';
import 'package:keyva/shared/widget/category_widget.dart';

class WidgetBuilderTest extends StatelessWidget {
  const WidgetBuilderTest({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
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
              SizedBox(height: AppSpacing.md.h),

              AppListItemWidget(
                title: 'متن مورد نظر',
                trailingIcon: Icon(
                  Icons.folder_outlined,
                  size: AppSizes.iconMd.s,
                ), // یا leadingIcon
                onTap: () {},
              ),
              SizedBox(height: AppSpacing.md.h),

              AppPasswordDisplayWiget(
                leadingIcon: Icon(Icons.lock_outline, size: AppSizes.iconMd.s),
                password: '1234567890',
                isVisible: true,
                onToggleVisibility: () {},
                onCopy: () {},
              ),
              SizedBox(height: AppSpacing.md.h),
              AppHeaderWidget(
                title: 'تنظیمات',
                titleAlign: TextAlign.right,
                leading: Icon(Icons.arrow_back_ios_new_rounded, size: 20.s),
                onLeadingTap: () => Navigator.pop(context),
              ),
              AppHeaderWidget(
                title: 'افزودن رمز عبور',
                titleAlign: TextAlign.center,
                leading: Icon(
                  Icons.close_rounded,
                  size: 24.s,
                  color: context.colors.textPrimary,
                ),
                onLeadingTap: () => Navigator.pop(context),
                trailing: Icon(
                  Icons.more_horiz_rounded,
                  size: 24.s,
                  color: context.colors.textPrimary,
                ),
                onTrailingTap: () {},
              ),
              AppHeaderWidget(
                leading: Icon(
                  Icons.close_rounded,
                  size: 24.s,
                  color: context.colors.textPrimary,
                ),
                onLeadingTap: () => Navigator.pop(context),
              ),

              AppSearchHeaderWidget(
                controller: TextEditingController(),
                hintText: 'جستجو در رمزها...',
                onChanged: (value) {},
                trailing: Icon(
                  Icons.menu_rounded,
                  size: 24.s,
                  color: context.colors.textPrimary,
                ),
                onTrailingTap: () {},
              ),
              SizedBox(
                width: 150.w,
                child: CategoryCardWidget(
                  title: 'بانک',
                  itemCount: 12,
                  icon: Icon(
                    Icons.account_balance_rounded,
                    color: context.colors.primary,
                  ),
                  onEdit: () {},
                  onDelete: () {},
                  onTap: () {},
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
