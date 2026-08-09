import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:keyva/core/gen/assets.gen.dart';
import 'package:keyva/core/theme/app_sizes.dart';
import 'package:keyva/core/theme/app_spacing.dart';
import 'package:keyva/core/theme/extensions/responsive_extentions.dart';
import 'package:keyva/core/theme/extensions/theme_extentions.dart';
import 'package:keyva/shared/widget/app_buttom_widget.dart';
import 'package:keyva/shared/widget/app_dialog_widget.dart';
import 'package:keyva/shared/widget/app_dropdown_widget.dart';
import 'package:keyva/shared/widget/app_header_widget.dart';
import 'package:keyva/shared/widget/app_list_item_widget.dart';
import 'package:keyva/shared/widget/app_password_display_widget.dart';
import 'package:keyva/shared/widget/app_search_header_widger.dart';
import 'package:keyva/shared/widget/bank_card_widger.dart';
import 'package:keyva/shared/widget/category_widget.dart';
import 'package:keyva/shared/widget/date_info_card_widget.dart';
import 'package:keyva/shared/widget/password_strengthbar_widget.dart';
import 'package:keyva/shared/widget/split_date_info.dart';
import 'package:keyva/shared/widget/toast_widget.dart';
import 'package:keyva/shared/widget/toggle_item_widget.dart';
import 'package:keyva/shared/widget/user_info_widger.dart';

class WidgetBuilderTest extends StatelessWidget {
  const WidgetBuilderTest({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsetsGeometry.symmetric(horizontal: AppSpacing.md.s),
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
                  leadingIcon: Icon(
                    Icons.lock_outline,
                    size: AppSizes.iconMd.s,
                  ),
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
                SizedBox(height: AppSpacing.md.h),

                DateInfoCardWidget(
                  icon: Icon(Icons.shield_rounded, size: 18.s),
                  strengthLabel: 'قدرت',
                  strengthValue: 'قوی',
                  strengthColor: context.colors.success,
                  dateLabel: 'آخرین بروزرسانی',
                  dateValue: '۱۲ اسفند ۱۴۰۲',
                ),
                SizedBox(height: AppSpacing.md.h),

                DateInfoCardWidget(
                  icon: Icon(Icons.shield_rounded, size: 18.s),
                  strengthLabel: 'قدرت',
                  strengthValue: 'قوی',
                  strengthColor: context.colors.success,
                  dateLabel: 'آخرین بروزرسانی',
                  dateValue: '۱۲ اسفند ۱۴۰۲',
                ),
                SizedBox(height: AppSpacing.md.h),

                SplitDateInfoWidget(
                  icon: Icon(Icons.calendar_today_rounded, size: 18.s),
                  leftLabel: 'تاریخ صدور',
                  leftValue: '۰۱/۰۲',
                  onLeftCopy: () {},
                  rightLabel: 'تاریخ انقضا',
                  rightValue: '۱۲/۲۸',
                  onRightCopy: () {},
                ),
                SizedBox(height: AppSpacing.md.h),

                Row(
                  children: [
                    Expanded(
                      child: AppButtonWidget(
                        title: 'ویرایش',
                        icon: Icon(Icons.edit_rounded, size: 18.s),
                        backgroundColor: context.colors.secondaryButton,
                        foregroundColor: context.colors.textPrimary,
                        onPressed: () {},
                      ),
                    ),
                    SizedBox(width: AppSpacing.md.s),
                    Expanded(
                      child: AppButtonWidget(
                        title: 'حذف',
                        icon: Icon(Icons.delete_rounded, size: 18.s),
                        backgroundColor: context.colors.secondaryButton,
                        foregroundColor: context.colors.textPrimary,
                        onPressed: () {},
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.md.h),

                BankCardWidget(
                  bankName: 'بانک پاسارگاد',
                  cardType: 'کارت نقدی',
                  cardNumber: '6037997456739790',
                  expiryDate: '۰۵/۰۱',
                  cvv: '****',
                  backgroundColor: const Color(0xFF0D0D0D),
                  textColor: const Color(0xFFF5E6C8),
                  accentColor: const Color(0xFFD4AF37),
                  leftLogo: SvgPicture.asset(
                    Assets.images.logoTest.path,
                    fit: BoxFit.contain,
                  ),
                  rightLogo: SvgPicture.asset(
                    Assets.images.logoTest.path,
                    fit: BoxFit.contain,
                  ),
                  onTap: () => AppDialogWidget.show(
                    context,
                    type: AppDialogType.success,
                    title: 'عملیات موفق',
                    description: 'اطلاعات با موفقیت ذخیره شد.',
                  ),
                ),
                SizedBox(height: AppSpacing.md.h),
                UserInfoWidget(
                  name: 'علی رضایی',
                  avatar: SvgPicture.asset(
                    Assets.images.logoTest.path,
                    fit: BoxFit.cover,
                  ),
                  onEdit: () {},
                ),
                SizedBox(height: AppSpacing.md.h),
                ToggleItemWidget(
                  icon: Icon(Icons.fingerprint_rounded, size: 18.s),
                  title: 'ورود با اثر انگشت',
                  value: true,
                  onChanged: (val) => AppToast.error(
                    context,
                    title: 'ذخیره شد',
                    message: 'رمز عبور با موفقیت ذخیره شد',
                  ),
                ),
                SizedBox(height: AppSpacing.md.h),
                PasswordStrengthBarWidget(strength: 0.8, showLabel: true),
                SizedBox(height: AppSpacing.md.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
