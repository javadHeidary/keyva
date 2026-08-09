import 'package:get/get.dart';
import 'package:keyva/feature/home/viewmodel/home_viewmodel.dart';
import 'package:keyva/feature/type/login/data/login_vault_store.dart';
import 'package:keyva/feature/type/bank_card/data/bank_card_vault_store.dart';
import 'package:keyva/feature/type/note/data/note_vault_store.dart';

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
    if (!Get.isRegistered<HomeController>()) {
      Get.lazyPut(() => HomeController());
    }
  }
}
