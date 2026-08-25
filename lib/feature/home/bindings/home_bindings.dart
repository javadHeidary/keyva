import 'package:get/get.dart';
import 'package:keyva/core/di/injection_container.dart';
import 'package:keyva/feature/auth/repository/auth_repository.dart';
import 'package:keyva/feature/category/controller/category_catalog_controller.dart';
import 'package:keyva/feature/home/viewmodel/home_viewmodel.dart';
import 'package:keyva/feature/settings/model/settings_repository.dart';
import 'package:keyva/feature/type/bank_card/data/bank_card_vault_store.dart';
import 'package:keyva/feature/type/login/data/login_vault_store.dart';
import 'package:keyva/feature/type/note/data/note_vault_store.dart';
import 'package:keyva/feature/vault/service/vault_unlock_service.dart';
import 'package:keyva/feature/vault/session/vault_session.dart';
import 'package:keyva/feature/vault/viewmodel/vault_home_viewmodel.dart';

class HomeBindings extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<LoginVaultStore>()) {
      Get.put(LoginVaultStore(), permanent: true);
    }
    if (!Get.isRegistered<BankCardVaultStore>()) {
      Get.put(BankCardVaultStore(), permanent: true);
    }
    if (!Get.isRegistered<NoteVaultStore>()) {
      Get.put(NoteVaultStore(), permanent: true);
    }
    if (!Get.isRegistered<CategoryCatalogController>()) {
      Get.put(CategoryCatalogController(), permanent: true);
    }
    if (!Get.isRegistered<VaultHomeViewModel>()) {
      Get.lazyPut(() => getIt<VaultHomeViewModel>());
    }
    if (!Get.isRegistered<HomeController>()) {
      Get.lazyPut(
        () => HomeController(
          unlock: getIt<VaultUnlockService>(),
          auth: getIt<AuthRepository>(),
          session: getIt<VaultSession>(),
          settings: getIt<SettingsRepository>(),
        ),
      );
    }
  }
}
