import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:keyva/core/gen/assets.gen.dart';
import 'package:keyva/core/routes/app_routing.dart';
import 'package:keyva/core/theme/app_spacing.dart';
import 'package:keyva/core/theme/app_typography.dart';
import 'package:keyva/core/theme/extensions/responsive_extentions.dart';
import 'package:keyva/core/theme/extensions/theme_extentions.dart';
import 'package:keyva/feature/auth/view_model/auth_login_viewmodel.dart';
import 'package:keyva/shared/icons/app_icons.dart';
import 'package:keyva/shared/widget/app_buttom_widget.dart';
import 'package:keyva/shared/widget/app_textfield_widget.dart';

class AuthLoginView extends GetView<LoginController> {
  const AuthLoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.pagePadding.s,
              vertical: AppSpacing.pagePadding.h,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: SvgPicture.asset(Assets.icons.trashTest.path),
                ),

                const Spacer(flex: 1),

                Row(
                  children: [
                    Container(
                      width: 65.s,
                      height: 65.s,
                      decoration: BoxDecoration(
                        shape: BoxShape.rectangle,
                        color: context.colors.strengthBarBg,
                        borderRadius: BorderRadius.circular(18.s),
                      ),
                      child: Icon(AppIcon.lock),
                    ),
                    SizedBox(width: AppSpacing.xl.h),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ورود به کیوا', style: AppTypography.titleLarge),
                        SizedBox(height: AppSpacing.sm.h),
                        Text(
                          'رمز اکانت خود را وارد کنید',
                          style: AppTypography.bodyLarge,
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.xxl.h),

                Obx(() {
                  return Form(
                    key: controller.loginFormKey,
                    child: AppTextFieldWidget(
                      controller: controller.passwordController,
                      obscureText: !controller.isPasswordVisible.value,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => controller.login(),
                      labelText: 'رمز عبور',
                      hintText: 'رمز را وارد کنید',
                      prefixIcon: Icon(AppIcon.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          controller.isPasswordVisible.value
                              ? AppIcon.visibilityOff
                              : AppIcon.visibility,
                        ),
                        onPressed: controller.togglePasswordVisibility,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'رمز عبور الزامی است';
                        }
                        if (value.length < 8) {
                          return 'رمز عبور باید حداقل ۸ کاراکتر باشد';
                        }
                        return null;
                      },
                    ),
                  );
                }),

                SizedBox(height: AppSpacing.sectionGap.h),

                Obx(() {
                  return AppButtonWidget(
                    title: 'ورود',
                    isLoading: controller.isLoading.value,
                    onPressed: () {
                      if (controller.loginFormKey.currentState!.validate()) {
                        controller.login();
                      }
                    },
                  );
                }),
                SizedBox(height: AppSpacing.sectionGap.h),
                Align(
                  alignment: Alignment.center,
                  child: Text.rich(
                    TextSpan(
                      text: 'اکانتی ندارید؟ ',
                      style: AppTypography.bodyMedium.copyWith(
                        color: context.colors.textTertiary,
                      ),
                      children: [
                        TextSpan(
                          text: 'ثبت‌نام',
                          style: AppTypography.titleMedium.copyWith(
                            color: context.colors.primary,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              Get.toNamed(AppRoutes.authRegister);
                            },
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const Spacer(flex: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
