import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:keyva/core/theme/app_radius.dart';
import 'package:keyva/core/theme/app_spacing.dart';
import 'package:keyva/core/theme/app_typography.dart';
import 'package:keyva/core/theme/extensions/responsive_extentions.dart';
import 'package:keyva/core/theme/extensions/theme_extentions.dart';
import 'package:keyva/feature/onboarding/viewmodel/onboarding_viewmodel.dart';

class OnboardingView extends GetView<OnboardingController> {
  const OnboardingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: controller.pageController,
                onPageChanged: controller.onPageChanged,
                itemCount: controller.slides.length,

                itemBuilder: (context, index) {
                  final slide = controller.slides[index];
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.s),
                    child: Directionality(
                      textDirection: TextDirection.rtl,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: AppSpacing.xxl.h),

                          Expanded(
                            flex: 3,
                            child: Center(
                              child: SvgPicture.asset(
                                width: 220.w,
                                height: 220.h,

                                slide.imagePath,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),

                          Text(
                            slide.title,
                            textAlign: TextAlign.right,
                            style: AppTypography.displaySmall,
                          ),

                          SizedBox(height: 16.h),

                          Text(
                            slide.description,
                            textAlign: TextAlign.right,
                            style: AppTypography.titleMedium,
                          ),

                          const Spacer(),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            Padding(
              padding: EdgeInsets.fromLTRB(24.s, 0, 24.s, 32.s),
              child: Column(
                children: [
                  Obx(() {
                    final isLast =
                        controller.currentPage.value ==
                        controller.slides.length - 1;
                    if (!isLast) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: EdgeInsets.only(bottom: AppSpacing.md.h),
                      child: TextButton(
                        key: const Key('onboarding-restore'),
                        onPressed: controller.openRestore,
                        child: Text(
                          'بازیابی پشتیبان',
                          style: AppTypography.titleMedium.copyWith(
                            color: context.colors.primary,
                          ),
                        ),
                      ),
                    );
                  }),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Obx(() {
                        return Row(
                          children: List.generate(controller.slides.length, (
                            index,
                          ) {
                            final isActive =
                                controller.currentPage.value == index;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              margin: EdgeInsets.only(right: 6.s),
                              width: isActive ? 18.w : 8.w,
                              height: 8.h,
                              decoration: BoxDecoration(
                                color: isActive
                                    ? context.colors.primary
                                    : context.colors.strengthBarBg,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.ssm,
                                ),
                              ),
                            );
                          }),
                        );
                      }),
                      Obx(() {
                        final isLast =
                            controller.currentPage.value ==
                            controller.slides.length - 1;
                        return FloatingActionButton(
                          onPressed: controller.nextPage,
                          child: Icon(
                            isLast ? Icons.check : Icons.arrow_forward,
                          ),
                        );
                      }),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
