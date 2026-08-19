import 'package:get/get.dart';
import 'package:keyva/core/di/injection_container.dart';
import 'package:keyva/core/security/biometric_service.dart';
import 'package:keyva/core/security/pin_service.dart';
import 'package:keyva/core/session/session_service.dart';
import 'package:keyva/feature/settings/viewmodel/settings_viewmodel.dart';
import 'package:keyva/feature/vault/service/vault_unlock_service.dart';

class SettingsBindings extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => SettingsViewModel(
        unlock: getIt<VaultUnlockService>(),
        pin: getIt<PinService>(),
        biometric: getIt<BiometricService>(),
        session: getIt<SessionService>(),
      ),
    );
  }
}
