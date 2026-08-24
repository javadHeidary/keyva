import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keyva/core/theme/app_sizes.dart';
import 'package:keyva/core/theme/app_spacing.dart';
import 'package:keyva/core/theme/extensions/responsive_extentions.dart';
import 'package:keyva/core/theme/extensions/theme_extentions.dart';
import 'package:keyva/feature/type/bank_card/viewmodel/bank_card_details_viewmodel.dart';
import 'package:keyva/feature/type/login/widget/login_detail_credential_card.dart';
import 'package:keyva/feature/vault/share/vault_item_share_ui.dart';
import 'package:keyva/feature/vault/view/vault_item_pin_ui.dart';
import 'package:keyva/shared/icons/app_icons.dart';
import 'package:keyva/shared/widget/app_buttom_widget.dart';
import 'package:keyva/shared/widget/app_header_widget.dart';
import 'package:keyva/shared/widget/app_title_item_widget.dart';
import 'package:keyva/shared/widget/bank_card_widger.dart';
import 'package:keyva/shared/widget/login_section_card_widget.dart';
import 'package:keyva/shared/widget/split_date_info.dart';

class BankCardDetailsView extends GetView<BankCardDetailsViewModel> {
  const BankCardDetailsView({super.key});

  static const _cardGap = AppSpacing.md;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      key: const Key('vault-bank-card-details'),
      backgroundColor: colors.pageBackground,
      body: SafeArea(
        child: Obx(() {
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
                    AppIcon.arrowBack,
                    size: AppSizes.iconLg.s,
                    color: colors.textPrimary,
                  ),
                  onLeadingTap: Get.back,
                  trailingActions: [
                    vaultShareHeaderAction(
                      color: colors.textSecondary,
                      onTap: () => controller.shareItem(context),
                    ),
                    vaultPinHeaderAction(
                      isPinned: card.isPinned,
                      color: card.isPinned
                          ? colors.primary
                          : colors.textSecondary,
                      onTap: () => controller.togglePin(context),
                    ),
                  ],
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
                        expiryDate: card.expiryDate,
                        cvv: cvvOnCard,
                        backgroundColor: bankInfo?.primaryColor,
                        textColor: bankInfo?.onPrimaryColor,
                        accentColor: bankInfo?.lighterColor,
                        rightLogo: bankInfo?.logoBuilder(
                          width: 40.s,
                          height: 40.s,
                        ),
                      ),
                      SizedBox(height: AppSpacing.sectionGap.h),
                      const AppTitleItemWidget(title: 'مشخصات کارت'),
                      LoginDetailCredentialCard(
                        icon: AppIcon.folder,
                        label: 'دسته‌بندی',
                        value: controller.categoryLabel,
                      ),
                      SizedBox(height: _cardGap.h),
                      LoginDetailCredentialCard(
                        icon: AppIcon.creditCard,
                        label: 'عنوان',
                        value: card.title,
                        trailing: LoginDetailActionIcon(
                          icon: AppIcon.copy,
                          tooltip: 'کپی',
                          onTap: () => controller.copyValue(
                            context,
                            card.title,
                            'کپی',
                            'عنوان کپی شد',
                          ),
                        ),
                      ),
                      SizedBox(height: _cardGap.h),
                      LoginDetailCredentialCard(
                        icon: AppIcon.accountCircle,
                        label: 'نام دارنده',
                        value: card.cardHolder,
                        trailing: LoginDetailActionIcon(
                          icon: AppIcon.copy,
                          tooltip: 'کپی',
                          onTap: () => controller.copyValue(
                            context,
                            card.cardHolder,
                            'کپی',
                            'نام دارنده کپی شد',
                          ),
                        ),
                      ),
                      SizedBox(height: _cardGap.h),
                      LoginDetailCredentialCard(
                        icon: AppIcon.hash,
                        label: 'شماره کارت',
                        value: controller.formattedCardNumber,
                        trailing: LoginDetailActionIcon(
                          icon: AppIcon.copy,
                          tooltip: 'کپی',
                          onTap: () => controller.copyValue(
                            context,
                            card.cardNumber,
                            'کپی',

                            'شماره کارت کپی شد',
                          ),
                        ),
                      ),
                      SizedBox(height: _cardGap.h),
                      LoginDetailCredentialCard(
                        key: const Key('vault-bank-card-bank-name'),
                        icon: bankInfo == null ? AppIcon.building : null,
                        leading: bankInfo?.logoBuilder(
                          width: 44.s,
                          height: 44.s,
                        ),
                        label: 'بانک',
                        value: controller.displayBankTitle,
                      ),
                      SizedBox(height: _cardGap.h),
                      AppSectionCardWidget(
                        padding: EdgeInsets.all(AppSpacing.md.s),
                        children: [
                          SplitDateInfoWidget(
                            leftLabel: 'ماه',
                            leftValue: controller.expiryMonth,
                            rightLabel: 'سال',
                            rightValue: controller.expiryYear,
                            leftCopyKey: const Key(
                              'vault-bank-card-copy-month',
                            ),
                            rightCopyKey: const Key(
                              'vault-bank-card-copy-year',
                            ),
                            onLeftCopy: () => controller.copyValue(
                              context,
                              controller.expiryMonth,
                              'کپی',
                              'ماه کپی شد',
                            ),
                            onRightCopy: () => controller.copyValue(
                              context,
                              controller.expiryYear,
                              'کپی',
                              'سال کپی شد',
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: _cardGap.h),
                      LoginDetailCredentialCard(
                        icon: AppIcon.lock,
                        label: 'CVV2',
                        value: cvvDetail,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            LoginDetailActionIcon(
                              icon: controller.isCvvVisible.value
                                  ? AppIcon.visibilityOff
                                  : AppIcon.visibility,
                              tooltip: 'نمایش CVV',
                              onTap: controller.toggleCvvVisibility,
                            ),
                            LoginDetailActionIcon(
                              icon: AppIcon.copy,
                              tooltip: 'کپی',
                              onTap: () => controller.copyValue(
                                context,
                                card.cvv,
                                'کپی',

                                'CVV2 کپی شد',
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: _cardGap.h),
                      LoginDetailCredentialCard(
                        icon: AppIcon.calendar,
                        label: 'تاریخ ایجاد',
                        value: controller.createdAtLabel,
                        useFaNumValue: true,
                      ),
                      if (card.notes != null && card.notes!.isNotEmpty) ...[
                        SizedBox(height: AppSpacing.sectionGap.h),
                        const AppTitleItemWidget(title: 'یادداشت'),
                        LoginDetailCredentialCard(
                          icon: AppIcon.note,
                          label: 'یادداشت',
                          value: card.notes!,
                          maxLines: 4,
                          trailing: LoginDetailActionIcon(
                            icon: AppIcon.copy,
                            tooltip: 'کپی',
                            onTap: () => controller.copyValue(
                              context,
                              card.notes!,
                              'کپی',

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
                          key: const Key('vault-item-edit'),
                          title: 'ویرایش',
                          icon: Icon(AppIcon.edit, size: AppSizes.iconMd.s),
                          onPressed: controller.navigateToEdit,
                        ),
                      ),
                      SizedBox(width: AppSpacing.md.s),
                      Expanded(
                        child: AppButtonWidget(
                          title: 'حذف',
                          icon: Icon(AppIcon.delete, size: AppSizes.iconMd.s),
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
