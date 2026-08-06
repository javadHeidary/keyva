import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get_navigation/get_navigation.dart';
import 'package:get/utils.dart';
import 'package:keyva/core/gen/assets.gen.dart';
import 'package:keyva/core/routes/app_routing.dart';
import 'package:keyva/core/theme/app_typography.dart';
import 'package:keyva/core/theme/extensions/responsive_extentions.dart';

class SplashView extends StatelessWidget {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () => Get.toNamed(AppRoutes.onBoarding),
                      child: SvgPicture.asset(
                        Assets.images.logoTest.path,
                        width: 100.w,
                        height: 100.h,
                      ),
                    ),
                    SizedBox(height: 35.h),
                    Text(
                      'کیوا مدیرت پسورت , امنیت بی نظیر',
                      style: AppTypography.titleLarge,
                    ),
                    SizedBox(height: 20.h),
                    Text('کیوا مدیرت پسورت ,امنیت بی نظیر ,کیوا مدیرت پسورت'),
                  ],
                ),
              ),
              SizedBox(
                width: 220.w,
                child: LinearProgressIndicator(
                  value: 0.5,
                  minHeight: 10.h,
                  borderRadius: BorderRadius.all(Radius.circular(12.s)),
                ),
              ),
              SizedBox(height: 80.h),
            ],
          ),
        ),
      ),
    );
  }
}
