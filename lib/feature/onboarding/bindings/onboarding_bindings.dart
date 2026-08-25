import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/get_instance.dart';
import 'package:keyva/core/di/injection_container.dart';
import 'package:keyva/feature/onboarding/viewmodel/onboarding_viewmodel.dart';
import 'package:keyva/feature/settings/model/settings_repository.dart';

class OnboardingBindings extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<OnboardingController>()) {
      Get.lazyPut(
        () => OnboardingController(settings: getIt<SettingsRepository>()),
      );
    }
  }
}
