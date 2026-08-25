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
          'رمزها، کارت‌های بانکی و یادداشت‌های حساس را در یک فضای خصوصی نگه دارید. همه‌چیز فقط روی گوشی خودتان می‌ماند.',
      imagePath: Assets.images.aboutOurApp.path,
    ),
    OnboardingSlide(
      title: 'بدون حساب، بدون سرور',
      description:
          'اینترنت لازم نیست. اطلاعات روی دستگاه رمزنگاری می‌شود و فقط خودتان به آن دسترسی دارید.',
      imagePath: Assets.images.contractOurApp.path,
    ),
    OnboardingSlide(
      title: 'امنیت قوی، کار ساده',
      description:
          'با رمز اصلی و اثر انگشت از اطلاعاتتان محافظت کنید. رمز قوی بسازید، دسته‌بندی کنید و راحت مدیریت کنید.',
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

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }
}
