import 'package:get/get.dart';
import 'package:keyva/core/di/injection_container.dart';
import 'package:keyva/core/security/biometric_service.dart';
import 'package:keyva/core/security/pin_service.dart';
import 'package:keyva/feature/auth/repository/auth_repository.dart';
import 'package:keyva/feature/auth/view_model/account_selection_viewmodel.dart';
import 'package:keyva/feature/auth/view_model/auth_login_viewmodel.dart';
import 'package:keyva/feature/auth/view_model/auth_register_viewmodel.dart';
import 'package:keyva/feature/vault/service/vault_unlock_service.dart';

class AccountSelectionBindings extends Bindings {
  @override
  void dependencies() {
    _replace<AccountSelectionViewModel>(
      () => AccountSelectionViewModel(auth: getIt<AuthRepository>()),
    );
  }
}

class UnlockBindings extends Bindings {
  @override
  void dependencies() {
    _replace<LoginController>(
      () => LoginController(
        unlock: getIt<VaultUnlockService>(),
        auth: getIt<AuthRepository>(),
        pin: getIt<PinService>(),
        biometric: getIt<BiometricService>(),
      ),
    );
  }
}

class RegisterBindings extends Bindings {
  @override
  void dependencies() {
    _replace<RegisterController>(
      () => RegisterController(
        auth: getIt<AuthRepository>(),
        unlock: getIt<VaultUnlockService>(),
      ),
    );
  }
}

void _replace<T>(T Function() create) {
  if (Get.isRegistered<T>()) {
    Get.delete<T>(force: true);
  }
  Get.put<T>(create());
}
