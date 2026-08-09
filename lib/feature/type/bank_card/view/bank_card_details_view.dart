import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keyva/core/theme/app_sizes.dart';
import 'package:keyva/core/theme/app_spacing.dart';
import 'package:keyva/core/theme/extensions/responsive_extentions.dart';
import 'package:keyva/core/theme/extensions/theme_extentions.dart';
import 'package:keyva/feature/type/bank_card/viewmodel/bank_card_details_viewmodel.dart';
import 'package:keyva/feature/type/login/widget/login_detail_credential_card.dart';
import 'package:keyva/feature/type/login/widget/login_section_card.dart';
import 'package:keyva/shared/widget/app_buttom_widget.dart';
import 'package:keyva/shared/widget/app_header_widget.dart';
import 'package:keyva/shared/widget/app_title_item_widget.dart';
import 'package:keyva/shared/widget/bank_card_widger.dart';
import 'package:keyva/shared/widget/split_date_info.dart';

class BankCardDetailsView extends GetView<BankCardDetailsViewModel> {
  const BankCardDetailsView({super.key});

  static const _cardGap = AppSpacing.md;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.pageBackground,
      body: SafeArea(
        child: Obx(() {
          controller.storeItems;
          controller.isCvvVisible.value;
          final card = controller.item;
          if (card == null) {
            return const SizedBox.shrink();
          }

          final bankInfo = controller.bankInfo;
          final cvvOnCard = '****';
          final cvvDetail = controller.isCvvVisible.value
              ? card.cvv
              : '•' * card.cvv.length;

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: AppHeaderWidget(
                  title: controller.headerTitle,
                  titleAlign: TextAlign.center,
                  leading: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: AppSizes.iconMd.s,
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
                  0,
                ),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      BankCardWidget(
                        bankName: controller.displayBankTitle,
                        cardType: 'کارت بانکی',
                        cardNumber: card.cardNumber,
                        expiryDate: card.expiry,
                        cvv: cvvOnCard,
                        backgroundColor: bankInfo?.primaryColor,
                        textColor: bankInfo?.onPrimaryColor,
                        accentColor: bankInfo?.lighterColor,
                        rightLogo: bankInfo?.logoBuilder(width: 36.s, height: 32.s),
                      ),
                      SizedBox(height: AppSpacing.sectionGap.h),
                      const AppTitleItemWidget(title: 'مشخصات کارت'),
                      LoginDetailCredentialCard(
                        icon: Icons.folder_outlined,
                        label: 'دسته‌بندی',
                        value: controller.categoryLabel,
                      ),
                      SizedBox(height: _cardGap.h),
                      LoginDetailCredentialCard(
                        icon: Icons.credit_card_rounded,
                        label: 'عنوان',
                        value: card.title,
                        trailing: LoginDetailActionIcon(
                          icon: Icons.copy_rounded,
                          tooltip: 'کپی',
                          onTap: () => controller.copyValue(
                            context,
                            card.title,
                            'عنوان کپی شد',
                          ),
                        ),
                      ),
                      SizedBox(height: _cardGap.h),
                      LoginDetailCredentialCard(
                        icon: Icons.numbers_rounded,
                        label: 'شماره کارت',
                        value: controller.formattedCardNumber,
                        trailing: LoginDetailActionIcon(
                          icon: Icons.copy_rounded,
                          tooltip: 'کپی',
                          onTap: () => controller.copyValue(
                            context,
                            card.cardNumber,
                            'شماره کارت کپی شد',
                          ),
                        ),
                      ),
                      SizedBox(height: _cardGap.h),
                      LoginSectionCard(
                        padding: EdgeInsets.all(AppSpacing.md.s),
                        children: [
                          SplitDateInfoWidget(
                            leftLabel: 'بانک',
                            leftValue: controller.displayBankTitle,
                            rightLabel: 'تاریخ انقضا',
                            rightValue: card.expiry,
                            icon: bankInfo != null
                                ? bankInfo.logoBuilder(width: 18.s, height: 18.s)
                                : Icon(
                                    Icons.account_balance_rounded,
                                    size: AppSizes.iconSm.s,
                                    color: colors.textSecondary,
                                  ),
                            onLeftCopy: () => controller.copyValue(
                              context,
                              controller.displayBankTitle,
                              'نام بانک کپی شد',
                            ),
                            onRightCopy: () => controller.copyValue(
                              context,
                              card.expiry,
                              'تاریخ انقضا کپی شد',
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: _cardGap.h),
                      LoginDetailCredentialCard(
                        icon: Icons.lock_outline_rounded,
                        label: 'CVV2',
                        value: cvvDetail,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            LoginDetailActionIcon(
                              icon: controller.isCvvVisible.value
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                              tooltip: 'نمایش CVV',
                              onTap: controller.toggleCvvVisibility,
                            ),
                            LoginDetailActionIcon(
                              icon: Icons.copy_rounded,
                              tooltip: 'کپی',
                              onTap: () => controller.copyValue(
                                context,
                                card.cvv,
                                'CVV2 کپی شد',
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: _cardGap.h),
                      LoginDetailCredentialCard(
                        icon: Icons.event_rounded,
                        label: 'تاریخ ایجاد',
                        value: controller.createdAtLabel,
                      ),
                      if (card.notes != null && card.notes!.isNotEmpty) ...[
                        SizedBox(height: AppSpacing.sectionGap.h),
                        const AppTitleItemWidget(title: 'یادداشت'),
                        LoginDetailCredentialCard(
                          icon: Icons.description_outlined,
                          label: 'یادداشت',
                          value: card.notes!,
                          maxLines: 4,
                          trailing: LoginDetailActionIcon(
                            icon: Icons.copy_rounded,
                            tooltip: 'کپی',
                            onTap: () => controller.copyValue(
                              context,
                              card.notes!,
                              'یادداشت کپی شد',
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.pagePadding.s,
                  AppSpacing.hugePlus.h,
                  AppSpacing.pagePadding.s,
                  AppSpacing.xxl.h,
                ),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      Expanded(
                        child: AppButtonWidget(
                          title: 'ویرایش',
                          icon: Icon(
                            Icons.edit_rounded,
                            size: AppSizes.iconMd.s,
                          ),
                          onPressed: controller.navigateToEdit,
                        ),
                      ),
                      SizedBox(width: AppSpacing.md.s),
                      Expanded(
                        child: AppButtonWidget(
                          title: 'حذف',
                          icon: Icon(
                            Icons.delete_outline_rounded,
                            size: AppSizes.iconMd.s,
                          ),
                          backgroundColor: colors.error.withValues(alpha: 0.3),
                          foregroundColor: colors.error,
                          onPressed: () => controller.confirmDelete(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
