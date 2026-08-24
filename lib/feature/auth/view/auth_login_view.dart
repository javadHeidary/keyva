import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:keyva/core/constants/security_constants.dart';
import 'package:keyva/core/routes/app_routing.dart';
import 'package:keyva/core/security/pin_policy.dart';
import 'package:keyva/core/theme/app_sizes.dart';
import 'package:keyva/core/theme/app_spacing.dart';
import 'package:keyva/core/theme/app_typography.dart';
import 'package:keyva/core/theme/extensions/responsive_extentions.dart';
import 'package:keyva/core/theme/extensions/theme_extentions.dart';
import 'package:keyva/feature/auth/view_model/auth_login_viewmodel.dart';
import 'package:keyva/feature/auth/widget/auth_error_toast_binder.dart';
import 'package:keyva/feature/auth/widget/auth_footer_link.dart';
import 'package:keyva/feature/auth/widget/auth_method_tile.dart';
import 'package:keyva/shared/icons/app_icons.dart';
import 'package:keyva/shared/widget/app_buttom_widget.dart';
import 'package:keyva/shared/widget/app_header_widget.dart';
import 'package:keyva/shared/widget/app_page_loading_overlay.dart';
import 'package:keyva/shared/widget/app_textfield_widget.dart';
import 'package:keyva/shared/widget/keyva_logo.dart';

class AuthLoginView extends GetView<LoginController> {
  const AuthLoginView({super.key});

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: AuthErrorToastBinder(
        message: controller.errorMessage,
        errorTitle: LoginController.errorTitle,
        successMessage: controller.successMessage,
        successTitle: LoginController.successTitle,
        child: Obx(() {
          return AppPageLoadingOverlay(
            visible: controller.isLoading.value,
            message: LoginController.loadingMessage,
            child: SafeArea(
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Column(
                  children: [
                    Obx(() => _navigationHeader(context)),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return SingleChildScrollView(
                            padding: EdgeInsets.fromLTRB(
                              AppSpacing.pagePadding.s,
                              AppSpacing.pagePadding.h,
                              AppSpacing.pagePadding.s,
                              AppSpacing.pagePadding.h + bottomInset,
                            ),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight:
                                    constraints.maxHeight -
                                    AppSpacing.pagePadding.h * 2 -
                                    bottomInset,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Obx(() => _header(context)),
                                  SizedBox(height: AppSpacing.xxl.h),
                                  Obx(() {
                                    if (controller.showMethodPicker.value) {
                                      return _methodPicker();
                                    }
                                    return _unlockForm(context);
                                  }),
                                  SizedBox(height: AppSpacing.sectionGap.h),
                                  Obx(() {
                                    if (controller.showMethodPicker.value) {
                                      return const SizedBox.shrink();
                                    }
                                    return _primaryAction();
                                  }),
                                  SizedBox(height: AppSpacing.md.h),
                                  Obx(() => _secondaryActions(context)),
                                  SizedBox(height: AppSpacing.sectionGap.h),
                                  AuthFooterLink(
                                    prefix: 'حسابی ندارید؟ ',
                                    actionLabel: 'ایجاد حساب',
                                    onTap: () =>
                                        Get.toNamed(AppRoutes.authRegister),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _navigationHeader(BuildContext context) {
    if (!controller.canSwitchAccount.value) {
      return const SizedBox.shrink();
    }
    return AppHeaderWidget(
      leading: Icon(
        AppIcon.arrowBack,
        key: const Key('auth-unlock-back'),
        size: AppSizes.iconLg.s,
        color: context.colors.textPrimary,
      ),
      onLeadingTap: controller.isLoading.value
          ? null
          : controller.changeAccount,
    );
  }

  Widget _header(BuildContext context) {
    final username = controller.selectedUsername.value;
    return Row(
      children: [
        KeyvaLogo(size: AppSizes.itemHeight.s),
        SizedBox(width: AppSpacing.lg.s),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                username.isEmpty ? 'ورود به حساب' : username,
                key: const Key('auth-unlock-username'),
                style: AppTypography.titleLarge.copyWith(
                  color: context.colors.textPrimary,
                ),
              ),
              SizedBox(height: AppSpacing.sm.h),
              Text(
                controller.showMethodPicker.value
                    ? 'روش ورود را انتخاب کنید'
                    : _subtitle(controller.unlockMethod.value),
                style: AppTypography.bodyMedium.copyWith(
                  color: context.colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _subtitle(UnlockMethod method) {
    switch (method) {
      case UnlockMethod.pin:
        return 'کد PIN خود را وارد کنید';
      case UnlockMethod.biometric:
        return 'با اثرانگشت وارد شوید';
      case UnlockMethod.masterPassword:
        return 'رمز اصلی خود را وارد کنید';
    }
  }

  Widget _methodPicker() {
    final loading = controller.isLoading.value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (controller.biometricOptionAvailable) ...[
          AuthMethodTile(
            key: const Key('auth-unlock-method-biometric'),
            icon: AppIcon.fingerprint,
            title: 'ورود با اثرانگشت',
            enabled: !loading,
            onTap: controller.chooseBiometric,
          ),
          SizedBox(height: AppSpacing.md.h),
        ],
        if (controller.pinAvailable) ...[
          AuthMethodTile(
            key: const Key('auth-unlock-method-pin'),
            icon: AppIcon.hash,
            title: 'کد PIN',
            enabled: !loading,
            onTap: controller.choosePin,
          ),
          SizedBox(height: AppSpacing.md.h),
        ],
        AuthMethodTile(
          key: const Key('auth-unlock-method-master'),
          icon: AppIcon.lock,
          title: 'رمز اصلی',
          enabled: !loading,
          onTap: controller.chooseMasterPassword,
        ),
      ],
    );
  }

  Widget _unlockForm(BuildContext context) {
    final loading = controller.isLoading.value;
    switch (controller.unlockMethod.value) {
      case UnlockMethod.pin:
        return Form(
          key: controller.loginFormKey,
          child: AppTextFieldWidget(
            key: const Key('auth-login-pin'),
            controller: controller.pinController,
            enabled: !loading,
            obscureText: !controller.isPinVisible.value,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            textDirection: TextDirection.ltr,
            enableInteractiveSelection: false,
            onFieldSubmitted: (_) => controller.unlockWithPin(),
            labelText: 'کد PIN',
            hintText: 'کد PIN را وارد کنید',
            prefixIcon: const Icon(AppIcon.hash),
            suffixIcon: IconButton(
              onPressed: controller.togglePinVisibility,
              icon: Icon(
                controller.isPinVisible.value
                    ? AppIcon.visibilityOff
                    : AppIcon.visibility,
              ),
            ),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(SecurityConstants.pinMaxLength),
            ],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'کد PIN الزامی است';
              }
              if (!PinPolicy.isValid(value)) {
                return PinPolicy.userMessage;
              }
              return null;
            },
          ),
        );
      case UnlockMethod.biometric:
        return const SizedBox.shrink();
      case UnlockMethod.masterPassword:
        return Form(
          key: controller.loginFormKey,
          child: AppTextFieldWidget(
            key: const Key('auth-login-password'),
            controller: controller.passwordController,
            enabled: !loading,
            obscureText: !controller.isPasswordVisible.value,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => controller.login(),
            labelText: 'رمز اصلی',
            hintText: 'رمز اصلی را وارد کنید',
            prefixIcon: const Icon(AppIcon.lock),
            suffixIcon: IconButton(
              onPressed: controller.togglePasswordVisibility,
              icon: Icon(
                controller.isPasswordVisible.value
                    ? AppIcon.visibilityOff
                    : AppIcon.visibility,
              ),
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
    }
  }

  Widget _primaryAction() {
    switch (controller.unlockMethod.value) {
      case UnlockMethod.pin:
        return AppButtonWidget(
          key: const Key('auth-login-pin-submit'),
          title: 'ورود',
          onPressed: controller.unlockWithPin,
        );
      case UnlockMethod.biometric:
        return AppButtonWidget(
          key: const Key('auth-login-biometric'),
          title: 'ورود با اثرانگشت',
          onPressed: controller.unlockWithBiometric,
        );
      case UnlockMethod.masterPassword:
        return AppButtonWidget(
          key: const Key('auth-login-submit'),
          title: 'ورود',
          onPressed: controller.login,
        );
    }
  }

  Widget _secondaryActions(BuildContext context) {
    if (controller.showMethodPicker.value) {
      return const SizedBox.shrink();
    }
    final method = controller.unlockMethod.value;
    final canPickMethods =
        controller.pinAvailable || controller.biometricOptionAvailable;
    final children = <Widget>[
      if (canPickMethods)
        TextButton(
          key: const Key('auth-unlock-back-methods'),
          onPressed: controller.isLoading.value
              ? null
              : controller.backToMethods,
          child: Text(
            'روش‌های ورود',
            style: AppTypography.titleMedium.copyWith(
              color: context.colors.primary,
            ),
          ),
        ),
    ];
    if (method != UnlockMethod.masterPassword &&
        (controller.pinEnabled.value || controller.biometricEnabled.value)) {
      children.add(
        TextButton(
          key: const Key('auth-login-use-master-password'),
          onPressed: controller.isLoading.value
              ? null
              : controller.useMasterPassword,
          child: Text(
            'ورود با رمز اصلی',
            style: AppTypography.titleMedium.copyWith(
              color: context.colors.primary,
            ),
          ),
        ),
      );
    }
    if (method != UnlockMethod.pin && controller.pinAvailable) {
      children.add(
        TextButton(
          key: const Key('auth-login-use-pin'),
          onPressed: controller.isLoading.value ? null : controller.usePin,
          child: Text(
            'ورود با PIN',
            style: AppTypography.titleMedium.copyWith(
              color: context.colors.primary,
            ),
          ),
        ),
      );
    }
    return Column(children: children);
  }
}
