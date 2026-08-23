import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keyva/core/gen/assets.gen.dart';
import 'package:keyva/core/routes/app_routing.dart';
import 'package:keyva/feature/onboarding/model/onboadrding_model.dart';

class OnboardingController extends GetxController {
  final durationValue = 300.milliseconds;
  final pageController = PageController();
  final currentPage = 0.obs;

  final slides = <OnboardingSlide>[
    OnboardingSlide(
      title: 'گاوصندوق امن شخصی شما',
      description:
          'Keyva یک فضای کاملاً خصوصی برای نگهداری رمزها، کارت‌های بانکی و یادداشت‌های حساس شماست.\nهمه چیز فقط روی گوشی خودتان ذخیره می‌شود.',
      imagePath: Assets.images.aboutOurApp.path,
    ),
    OnboardingSlide(
      title: 'اطلاعات شما از دستگاه خارج نمی‌شود',
      description:
          'بدون حساب کاربری، بدون سرور و بدون اینترنت.\nتمام داده‌ها به‌صورت محلی رمزنگاری می‌شوند و فقط شما به آن‌ها دسترسی دارید.',
      imagePath: Assets.images.contractOurApp.path,
    ),
    OnboardingSlide(
      title: 'امنیت قوی، استفاده ساده',
      description:
          'با Master Password و اثر انگشت از اطلاعاتتان محافظت کنید.\nرمزهای قوی بسازید، دسته‌بندی کنید و با خیال راحت مدیریت کنید.',
      imagePath: Assets.images.category.path,
    ),
  ];

  void onPageChanged(int index) {
    currentPage.value = index;
  }

  void nextPage() {
    if (currentPage.value < slides.length - 1) {
      pageController.nextPage(duration: durationValue, curve: Curves.easeInOut);
    } else {
      Get.offNamed(AppRoutes.authRegister);
    }
  }

  void openRestore() {
    Get.toNamed(AppRoutes.authRestore);
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }
}
