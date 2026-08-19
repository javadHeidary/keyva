import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/get_instance.dart';
import 'package:keyva/core/di/injection_container.dart';
import 'package:keyva/core/security/biometric_service.dart';
import 'package:keyva/core/security/pin_service.dart';
import 'package:keyva/feature/auth/repository/auth_repository.dart';
import 'package:keyva/feature/auth/view_model/auth_login_viewmodel.dart';
import 'package:keyva/feature/auth/view_model/auth_register_viewmodel.dart';
import 'package:keyva/feature/vault/service/vault_unlock_service.dart';

class AuthBindings extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<LoginController>()) {
      Get.lazyPut(
        () => LoginController(
          unlock: getIt<VaultUnlockService>(),
          auth: getIt<AuthRepository>(),
          pin: getIt<PinService>(),
          biometric: getIt<BiometricService>(),
        ),
      );
    }
    if (!Get.isRegistered<RegisterController>()) {
      Get.lazyPut(
        () => RegisterController(
          auth: getIt<AuthRepository>(),
          unlock: getIt<VaultUnlockService>(),
        ),
      );
    }
  }
}
