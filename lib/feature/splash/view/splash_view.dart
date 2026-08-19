import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keyva/core/gen/assets.gen.dart';
import 'package:keyva/core/theme/app_typography.dart';
import 'package:keyva/core/theme/extensions/responsive_extentions.dart';
import 'package:keyva/core/theme/extensions/theme_extentions.dart';
import 'package:keyva/feature/auth/view_model/auth_startup_viewmodel.dart';
import 'package:keyva/feature/onboarding/util/onboarding_precache.dart';
import 'package:keyva/shared/widget/app_loading_widger.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  static const _tagline = 'گاوصندوق امن شخصی شما';
  static const _charDelay = Duration(milliseconds: 80);
  static const _pauseBeforeNavigate = Duration(milliseconds: 600);

  String _visibleTagline = '';

  @override
  void initState() {
    super.initState();
    final typewriter = _runTypewriter();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _prepareThenGo(typewriter);
    });
  }

  Future<void> _runTypewriter() async {
    for (var i = 0; i < _tagline.length; i++) {
      await Future.delayed(_charDelay);
      if (!mounted) return;
      setState(() {
        _visibleTagline = _tagline.substring(0, i + 1);
      });
    }
  }

  Future<void> _prepareThenGo(Future<void> typewriter) async {
    await Future.wait([
      typewriter,
      precacheOnboardingAssets(context),
    ]);
    if (!mounted) return;
    await Future.delayed(_pauseBeforeNavigate);
    if (!mounted) return;
    final route = await Get.find<AuthStartupViewModel>().resolveInitialRoute();
    if (!mounted) return;
    Get.offNamed(route);
  }

  @override
  Widget build(BuildContext context) {
    final logo = context.isDark
        ? Assets.images.logoDarkMode
        : Assets.images.logoLightMode;

    return Scaffold(
      backgroundColor: context.colors.pageBackground,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  logo.image(width: 150.w, height: 150.h, fit: BoxFit.contain),
                  SizedBox(height: 24.h),
                  Text(
                    'کی وا',
                    style: AppTypography.displayMedium.copyWith(
                      color: context.colors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    _visibleTagline,
                    textAlign: TextAlign.center,
                    style: AppTypography.titleLarge.copyWith(
                      color: context.colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.only(bottom: 48.h),
              child: AppLoadingWidget.section(),
            ),
          ],
        ),
      ),
    );
  }
}
