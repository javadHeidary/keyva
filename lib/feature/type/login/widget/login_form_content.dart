import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keyva/core/theme/app_sizes.dart';
import 'package:keyva/core/theme/app_spacing.dart';
import 'package:keyva/core/theme/app_typography.dart';
import 'package:keyva/core/theme/extensions/responsive_extentions.dart';
import 'package:keyva/core/theme/extensions/theme_extentions.dart';
import 'package:keyva/feature/type/login/viewmodel/login_form_viewmodel.dart';
import 'package:keyva/feature/type/login/widget/login_favicon_widget.dart';
import 'package:keyva/shared/widget/app_dropdown_widget.dart';
import 'package:keyva/shared/widget/app_textfield_widget.dart';
import 'package:keyva/shared/widget/app_title_item_widget.dart';
import 'package:keyva/shared/widget/login_section_card_widget.dart';
import 'package:keyva/shared/widget/password_strengthbar_widget.dart';

class LoginFormContent extends StatelessWidget {
  const LoginFormContent({super.key, required this.controller});

  final LoginFormViewModel controller;

  static const _fieldGap = AppSpacing.lg;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final fieldFill = colors.card;

    return Form(
      key: controller.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTitleItemWidget(title: 'مشخصات ورود'),
          AppSectionCardWidget(
            children: [
              Padding(
                padding: EdgeInsets.only(
                  right: AppSpacing.xs.s,
                  bottom: AppSpacing.sm.h,
                ),
                child: Text(
                  'عنوان ',
                  style: AppTypography.titleMedium.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
              ),
              AppTextFieldWidget(
                controller: controller.titleController,
                labelText: 'نام اپلیکیشن',
                labelAlwaysVisible: false,
                hintText: 'مثلاً Netflix، GitHub',
                textInputAction: TextInputAction.next,
                fillColor: fieldFill,
                prefixIcon: Icon(
                  Icons.apps_rounded,
                  size: AppSizes.iconMd.s,
                  color: colors.textSecondary,
                ),
                validator: controller.validateTitle,
              ),
              SizedBox(height: _fieldGap.h),
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
            ],
          ),
          SizedBox(height: AppSpacing.lg.h),
          AppTitleItemWidget(title: 'اطلاعات ورودی'),
          AppSectionCardWidget(
            children: [
              Obx(() {
                final fields = controller.websiteFields;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < fields.length; i++) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Obx(
                              () => AppTextFieldWidget(
                                key: ValueKey(fields[i].id),
                                controller: fields[i].controller,
                                labelText: fields.length > 1
                                    ? 'آدرس وب ${i + 1}'
                                    : 'آدرس وب',
                                labelAlwaysVisible: true,
                                hintText: 'https://example.com',
                                keyboardType: TextInputType.url,
                                textInputAction: TextInputAction.next,
                                fillColor: fieldFill,
                                prefixIcon: fields[i].preview.value.isNotEmpty
                                    ? LoginFaviconWidget(
                                        website: fields[i].preview.value,
                                        size: 28.s,
                                      )
                                    : Icon(
                                        Icons.language_rounded,
                                        size: AppSizes.iconMd.s,
                                        color: colors.textSecondary,
                                      ),
                                validator: controller.validateWebsite,
                              ),
                            ),
                          ),
                          if (fields.length > 1) ...[
                            SizedBox(width: AppSpacing.xs.s),
                            GestureDetector(
                              onTap: () => controller.removeWebsiteField(i),
                              child: Icon(
                                Icons.delete,
                                size: AppSizes.iconLg.s,
                                color: colors.error,
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (i < fields.length - 1) SizedBox(height: _fieldGap.h),
                    ],
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: TextButton.icon(
                        onPressed: controller.addWebsiteField,
                        icon: Icon(
                          Icons.add_rounded,
                          size: AppSizes.iconMd.s,
                          color: colors.primary,
                        ),
                        label: Text(
                          'افزودن وب‌سایت',
                          style: TextStyle(color: colors.primary),
                        ),
                      ),
                    ),
                  ],
                );
              }),
              SizedBox(height: _fieldGap.h),
              AppTextFieldWidget(
                controller: controller.usernameController,
                labelText: 'نام کاربری / ایمیل',
                labelAlwaysVisible: true,
                hintText: 'نام کاربری یا ایمیل',
                textInputAction: TextInputAction.next,
                fillColor: fieldFill,
                prefixIcon: Icon(
                  Icons.person_outline_rounded,
                  size: AppSizes.iconMd.s,
                  color: colors.textSecondary,
                ),
                validator: controller.validateUsername,
              ),
              SizedBox(height: _fieldGap.h),
              Obx(() {
                return AppTextFieldWidget(
                  controller: controller.passwordController,
                  labelText: 'رمز عبور',
                  labelAlwaysVisible: true,
                  hintText: 'رمز عبور را وارد کنید',
                  obscureText: !controller.isPasswordVisible.value,
                  textInputAction: TextInputAction.next,
                  fillColor: fieldFill,
                  prefixIcon: Icon(
                    Icons.lock_outline_rounded,
                    size: AppSizes.iconMd.s,
                    color: colors.textSecondary,
                  ),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.auto_awesome_rounded,
                          size: AppSizes.iconMd.s,
                          color: colors.primary,
                        ),
                        onPressed: controller.generatePassword,
                        tooltip: 'تولید رمز عبور',
                      ),
                      IconButton(
                        icon: Icon(
                          controller.isPasswordVisible.value
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                          size: AppSizes.iconMd.s,
                        ),
                        onPressed: controller.togglePasswordVisibility,
                      ),
                    ],
                  ),
                  validator: controller.validatePassword,
                );
              }),
              SizedBox(height: AppSpacing.sm.h),
              Obx(
                () => PasswordStrengthBarWidget(
                  strength: controller.passwordStrength.value,
                  showLabel: controller.hasPasswordInput.value,
                  useSegmentedBars: true,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.lg.h),
          AppSectionCardWidget(
            children: [
              AppTextFieldWidget(
                controller: controller.notesController,
                labelText: 'یادداشت',
                labelAlwaysVisible: true,
                hintText: 'توضیحات اضافی...',
                textInputAction: TextInputAction.done,
                fillColor: fieldFill,
                maxLines: 4,
                minLines: 3,
                prefixIcon: Icon(
                  Icons.description_outlined,
                  size: AppSizes.iconMd.s,
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
