import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keyva/core/theme/app_sizes.dart';
import 'package:keyva/core/theme/app_spacing.dart';
import 'package:keyva/core/theme/app_typography.dart';
import 'package:keyva/core/theme/extensions/responsive_extentions.dart';
import 'package:keyva/core/theme/extensions/theme_extentions.dart';
import 'package:keyva/feature/type/bank_card/util/bank_card_util.dart';
import 'package:keyva/feature/type/bank_card/viewmodel/bank_card_form_viewmodel.dart';
import 'package:keyva/feature/type/login/widget/login_section_card.dart';
import 'package:keyva/shared/widget/app_dropdown_widget.dart';
import 'package:keyva/shared/widget/app_textfield_widget.dart';
import 'package:keyva/shared/widget/app_title_item_widget.dart';

class BankCardFormContent extends StatelessWidget {
  const BankCardFormContent({super.key, required this.controller});

  final BankCardFormViewModel controller;

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
          LoginSectionCard(
            children: [
              Padding(
                padding: EdgeInsets.only(
                  right: AppSpacing.xs.s,
                  bottom: AppSpacing.sm.h,
                ),
                child: Text(
                  'عنوان',
                  style: AppTypography.titleMedium.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
              ),
              AppTextFieldWidget(
                controller: controller.titleController,
                labelText: 'عنوان کارت',
                labelAlwaysVisible: true,
                hintText: 'مثلاً کارت بانک ملت',
                textInputAction: TextInputAction.next,
                fillColor: fieldFill,
                prefixIcon: Icon(
                  Icons.credit_card_rounded,
                  size: AppSizes.iconMd.s,
                  color: colors.textSecondary,
                ),
                validator: controller.validateTitle,
              ),
            ],
          ),
          SizedBox(height: AppSpacing.lg.h),
          AppTitleItemWidget(title: 'اطلاعات کارت'),
          LoginSectionCard(
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
                controller: controller.cardNumberController,
                labelText: 'شماره کارت',
                labelAlwaysVisible: true,
                hintText: '0000 0000 0000 0000',
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                fillColor: fieldFill,
                inputFormatters: [BankCardNumberInputFormatter()],
                prefixIcon: Icon(
                  Icons.numbers_rounded,
                  size: AppSizes.iconMd.s,
                  color: colors.textSecondary,
                ),
                validator: controller.validateCardNumber,
              ),
              SizedBox(height: _fieldGap.h),
              Obx(() {
                final bank = controller.detectedBank.value;
                final bankError = controller.bankFieldError.value;
                return AppTextFieldWidget(
                  controller: controller.bankController,
                  labelText: 'بانک',
                  labelAlwaysVisible: true,
                  hintText: 'پس از وارد کردن شماره کارت',
                  readOnly: true,
                  fillColor: fieldFill,
                  prefixIcon: bank != null
                      ? SizedBox(
                          width: 28.s,
                          height: 28.s,
                          child: bank.logoBuilder(),
                        )
                      : Icon(
                          Icons.account_balance_rounded,
                          size: AppSizes.iconMd.s,
                          color: colors.textSecondary,
                        ),
                  validator: controller.validateBankDisplay,
                  errorText: bankError,
                );
              }),
              SizedBox(height: _fieldGap.h),
              AppTextFieldWidget(
                controller: controller.expiryController,
                labelText: 'تاریخ انقضا',
                labelAlwaysVisible: true,
                hintText: 'MM/YY',
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                fillColor: fieldFill,
                inputFormatters: [BankCardExpiryInputFormatter()],
                prefixIcon: Icon(
                  Icons.calendar_today_outlined,
                  size: AppSizes.iconMd.s,
                  color: colors.textSecondary,
                ),
                validator: controller.validateExpiry,
              ),
              SizedBox(height: _fieldGap.h),
              Obx(() {
                return AppTextFieldWidget(
                  controller: controller.cvvController,
                  labelText: 'CVV2',
                  labelAlwaysVisible: true,
                  hintText: '۳ یا ۴ رقم',
                  obscureText: !controller.isCvvVisible.value,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  fillColor: fieldFill,
                  inputFormatters: [BankCardCvvInputFormatter()],
                  prefixIcon: Icon(
                    Icons.lock_outline_rounded,
                    size: AppSizes.iconMd.s,
                    color: colors.textSecondary,
                  ),
                  suffixIcon: IconButton(
                    onPressed: controller.toggleCvvVisibility,
                    icon: Icon(
                      controller.isCvvVisible.value
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      size: AppSizes.iconMd.s,
                      color: colors.textSecondary,
                    ),
                  ),
                  validator: controller.validateCvv,
                );
              }),
            ],
          ),
          SizedBox(height: AppSpacing.lg.h),
          AppTitleItemWidget(title: 'یادداشت'),
          LoginSectionCard(
            children: [
              AppTextFieldWidget(
                controller: controller.notesController,
                labelText: 'یادداشت',
                labelAlwaysVisible: true,
                hintText: 'یادداشت اختیاری',
                maxLines: 4,
                textInputAction: TextInputAction.newline,
                fillColor: fieldFill,
                prefixIcon: Icon(
                  Icons.notes_rounded,
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
