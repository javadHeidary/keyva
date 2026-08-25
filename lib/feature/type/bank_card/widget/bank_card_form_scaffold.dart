import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keyva/core/constants/layout_constants.dart';
import 'package:keyva/core/theme/app_sizes.dart';
import 'package:keyva/core/theme/app_spacing.dart';
import 'package:keyva/core/theme/extensions/responsive_extentions.dart';
import 'package:keyva/core/theme/extensions/theme_extentions.dart';
import 'package:keyva/feature/type/bank_card/viewmodel/bank_card_form_viewmodel.dart';
import 'package:keyva/feature/type/bank_card/widget/bank_card_form_content.dart';
import 'package:keyva/shared/icons/app_icons.dart';
import 'package:keyva/shared/widget/app_buttom_widget.dart';
import 'package:keyva/shared/widget/app_header_widget.dart';
import 'package:keyva/feature/vault/view/vault_error_view.dart';

class BankCardFormScaffold extends StatelessWidget {
  const BankCardFormScaffold({super.key, required this.controller});

  final BankCardFormViewModel controller;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      resizeToAvoidBottomInset: LayoutConstants.resizeToAvoidBottomInset,
      backgroundColor: colors.pageBackground,
      body: SafeArea(
        child: CustomScrollView(
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
                trailingActions: controller.showDeleteAction
                    ? [
                        AppHeaderTrailingAction(
                          child: Icon(
                            AppIcon.delete,
                            size: AppSizes.iconLg.s,
                            color: colors.error,
                          ),
                          onTap: controller.handleDelete,
                        ),
                      ]
                    : null,
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.sm.s,
                AppSpacing.sm.h,
                AppSpacing.lg.s,
                AppSpacing.lg.h,
              ),
              sliver: SliverToBoxAdapter(
                child: BankCardFormContent(controller: controller),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.sm.s,
                AppSpacing.xxl.h,
                AppSpacing.lg.s,
                AppSpacing.xxl.h,
              ),
              sliver: SliverToBoxAdapter(
                child: Obx(() {
                  final error = controller.submitError.value;
                  return Column(
                    children: [
                      if (error != null && error.isNotEmpty)
                        VaultSubmitErrorText(message: error),
                      AppButtonWidget(
                        key: const Key('vault-form-submit'),
                        title: controller.submitLabel,
                        isLoading: controller.isSubmitting.value,
                        onPressed: controller.submit,
                      ),
                    ],
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
