import 'package:flutter/gestures.dart';
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
                Obx(() {
                  if (!controller.canSwitchAccount.value) {
                    return SizedBox(height: AppSizes.iconLg.s);
                  }
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      key: const Key('auth-unlock-change-account'),
                      onPressed: controller.changeAccount,
                      child: Text(
                        'تغییر حساب',
                        style: AppTypography.titleMedium.copyWith(
                          color: context.colors.primary,
                        ),
                      ),
                    ),
                  );
                }),
                const Spacer(flex: 1),
                Obx(() => _header(context)),
                SizedBox(height: AppSpacing.xxl.h),
                Obx(() {
                  if (controller.showMethodPicker.value) {
                    return _methodPicker(context);
                  }
                  return _unlockForm(context);
                }),
                Obx(() {
                  if (controller.errorMessage.value.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: EdgeInsets.only(top: AppSpacing.md.h),
                    child: Text(
                      controller.errorMessage.value,
                      key: const Key('auth-login-error'),
                      style: AppTypography.bodyMedium.copyWith(
                        color: context.colors.error,
                      ),
                    ),
                  );
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
                const Align(alignment: Alignment.center, child: _RegisterText()),
                const Spacer(flex: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    final username = controller.selectedUsername.value;
    return Row(
      children: [
        Container(
          width: 65.s,
          height: 65.s,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.rectangle,
            color: context.colors.strengthBarBg,
            borderRadius: BorderRadius.circular(18.s),
          ),
          child: username.isEmpty
              ? const Icon(AppIcon.lock)
              : Text(
                  String.fromCharCodes(username.trim().runes.take(1)),
                  style: AppTypography.titleLarge,
                ),
        ),
        SizedBox(width: AppSpacing.xl.s),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                username.isEmpty ? 'ورود به حساب' : username,
                key: const Key('auth-unlock-username'),
                style: AppTypography.titleLarge,
              ),
              SizedBox(height: AppSpacing.sm.h),
              Text(
                controller.showMethodPicker.value
                    ? 'روش ورود را انتخاب کنید'
                    : _subtitle(controller.unlockMethod.value),
                style: AppTypography.bodyLarge,
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
        return 'با اثر انگشت یا چهره وارد شوید';
      case UnlockMethod.masterPassword:
        return 'رمز اکانت خود را وارد کنید';
    }
  }

  Widget _methodPicker(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppButtonWidget(
          key: const Key('auth-unlock-method-master'),
          title: 'رمز اصلی',
          onPressed: controller.chooseMasterPassword,
        ),
        if (controller.pinAvailable) ...[
          SizedBox(height: AppSpacing.md.h),
          AppButtonWidget(
            key: const Key('auth-unlock-method-pin'),
            title: 'پین کد',
            onPressed: controller.choosePin,
          ),
        ],
        if (controller.biometricOptionAvailable) ...[
          SizedBox(height: AppSpacing.md.h),
          AppButtonWidget(
            key: const Key('auth-unlock-method-biometric'),
            title: 'ورود با بیومتریک',
            isLoading: controller.isLoading.value,
            onPressed: controller.chooseBiometric,
          ),
        ],
      ],
    );
  }

  Widget _unlockForm(BuildContext context) {
    switch (controller.unlockMethod.value) {
      case UnlockMethod.pin:
        return Form(
          key: controller.loginFormKey,
          child: AppTextFieldWidget(
            key: const Key('auth-login-pin'),
            controller: controller.pinController,
            obscureText: !controller.isPinVisible.value,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            textDirection: TextDirection.ltr,
            enableInteractiveSelection: false,
            onFieldSubmitted: (_) => controller.unlockWithPin(),
            labelText: 'کد PIN',
            hintText: 'PIN را وارد کنید',
            prefixIcon: const Icon(AppIcon.pin),
            suffixIcon: IconButton(
              icon: Icon(
                controller.isPinVisible.value
                    ? AppIcon.visibilityOff
                    : AppIcon.visibility,
              ),
              onPressed: controller.togglePinVisibility,
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
            obscureText: !controller.isPasswordVisible.value,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => controller.login(),
            labelText: 'رمز عبور',
            hintText: 'رمز را وارد کنید',
            prefixIcon: const Icon(AppIcon.lock),
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
    }
  }

  Widget _primaryAction() {
    switch (controller.unlockMethod.value) {
      case UnlockMethod.pin:
        return AppButtonWidget(
          key: const Key('auth-login-pin-submit'),
          title: 'ورود',
          isLoading: controller.isLoading.value,
          onPressed: controller.unlockWithPin,
        );
      case UnlockMethod.biometric:
        return AppButtonWidget(
          key: const Key('auth-login-biometric'),
          title: 'ورود با اثر انگشت یا چهره',
          isLoading: controller.isLoading.value,
          onPressed: controller.unlockWithBiometric,
        );
      case UnlockMethod.masterPassword:
        return AppButtonWidget(
          key: const Key('auth-login-submit'),
          title: 'ورود',
          isLoading: controller.isLoading.value,
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
          onPressed: controller.backToMethods,
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
          onPressed: controller.useMasterPassword,
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
          onPressed: controller.usePin,
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

class _RegisterText extends StatefulWidget {
  const _RegisterText();

  @override
  State<_RegisterText> createState() => _RegisterTextState();
}

class _RegisterTextState extends State<_RegisterText> {
  late final TapGestureRecognizer _recognizer;

  @override
  void initState() {
    super.initState();
    _recognizer = TapGestureRecognizer()
      ..onTap = () {
        Get.toNamed(AppRoutes.authRegister);
      };
  }

  @override
  void dispose() {
    _recognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text.rich(
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
            recognizer: _recognizer,
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
