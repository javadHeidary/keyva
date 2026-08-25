import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:keyva/feature/onboarding/viewmodel/onboarding_viewmodel.dart';

import '../settings/support/fake_settings_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeSettingsRepository settings;
  late OnboardingController controller;

  setUp(() {
    Get.testMode = true;
    settings = FakeSettingsRepository();
    controller = OnboardingController(settings: settings);
  });

  tearDown(() {
    controller.onClose();
    Get.reset();
  });

  test('last nextPage persists onboarding', () async {
    controller.currentPage.value = controller.slides.length - 1;

    await controller.nextPage();

    expect(settings.onboardingCompleted, isTrue);
  });

  testWidgets('intermediate nextPage does not persist onboarding', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PageView(
          controller: controller.pageController,
          onPageChanged: controller.onPageChanged,
          children: List.generate(
            controller.slides.length,
            (_) => const SizedBox.expand(),
          ),
        ),
      ),
    );

    final pending = controller.nextPage();
    await tester.pumpAndSettle();
    await pending;

    expect(settings.onboardingCompleted, isFalse);
  });
}
