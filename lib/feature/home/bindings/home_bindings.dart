import 'package:get/get.dart';
import 'package:keyva/feature/home/viewmodel/home_viewmodel.dart';
import 'package:keyva/feature/type/login/data/login_vault_store.dart';

class HomeBindings extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<LoginVaultStore>()) {
      Get.put(LoginVaultStore(), permanent: true);
    }
    if (!Get.isRegistered<HomeController>()) {
      Get.lazyPut(() => HomeController());
    }
  }
}
