import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keyva/core/constants/layout_constants.dart';
import 'package:keyva/core/theme/app_sizes.dart';
import 'package:keyva/core/theme/app_spacing.dart';
import 'package:keyva/core/theme/extensions/responsive_extentions.dart';
import 'package:keyva/core/theme/extensions/theme_extentions.dart';
import 'package:keyva/feature/category/viewmodel/category_form_viewmodel.dart';
import 'package:keyva/feature/category/widget/category_form_content.dart';
import 'package:keyva/feature/vault/view/vault_error_view.dart';
import 'package:keyva/shared/widget/app_buttom_widget.dart';
import 'package:keyva/shared/widget/app_header_widget.dart';

class CategoryFormScaffold extends StatelessWidget {
  const CategoryFormScaffold({super.key, required this.controller});

  final CategoryFormViewModel controller;

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
                AppSpacing.xxl.h,
              ),
              sliver: SliverToBoxAdapter(
                child: CategoryFormContent(controller: controller),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg.s),
          child: Obx(() {
            final error = controller.submitError.value;
            return Column(
              mainAxisSize: MainAxisSize.min,
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
    );
  }
}
