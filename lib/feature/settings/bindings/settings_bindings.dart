import 'package:get/get.dart';
import 'package:keyva/core/di/injection_container.dart';
import 'package:keyva/feature/settings/viewmodel/settings_viewmodel.dart';
import 'package:keyva/feature/vault/service/vault_unlock_service.dart';

class SettingsBindings extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => SettingsViewModel(unlock: getIt<VaultUnlockService>()),
    );
  }
}
