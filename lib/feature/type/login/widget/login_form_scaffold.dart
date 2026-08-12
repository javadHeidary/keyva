import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keyva/core/theme/app_sizes.dart';
import 'package:keyva/core/theme/app_spacing.dart';
import 'package:keyva/core/theme/extensions/responsive_extentions.dart';
import 'package:keyva/core/theme/extensions/theme_extentions.dart';
import 'package:keyva/feature/type/login/viewmodel/login_form_viewmodel.dart';
import 'package:keyva/feature/type/login/widget/login_form_content.dart';
import 'package:keyva/shared/icons/app_icons.dart';
import 'package:keyva/shared/widget/app_buttom_widget.dart';
import 'package:keyva/shared/widget/app_header_widget.dart';

class LoginFormScaffold extends StatelessWidget {
  const LoginFormScaffold({super.key, required this.controller});

  final LoginFormViewModel controller;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
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
                          onTap: () => controller.handleDelete(),
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
                child: LoginFormContent(controller: controller),
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
                  final isLoading = controller.isSubmitting.value;
                  return AppButtonWidget(
                    title: controller.submitLabel,
                    isLoading: isLoading,
                    onPressed: controller.submit,
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
