import 'package:get/get.dart';
import 'package:keyva/feature/password_generator/data/password_generator_settings_store.dart';
import 'package:keyva/feature/password_generator/data/password_history_store.dart';
import 'package:keyva/feature/password_generator/viewmodel/password_generator_viewmodel.dart';
import 'package:keyva/feature/password_generator/viewmodel/password_history_viewmodel.dart';

class PasswordGeneratorBindings extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<PasswordGeneratorSettingsStore>()) {
      Get.putAsync(
        () => PasswordGeneratorSettingsStore().init(),
        permanent: true,
      );
    }
    if (!Get.isRegistered<PasswordHistoryStore>()) {
      Get.putAsync(() => PasswordHistoryStore().init(), permanent: true);
    }
    Get.lazyPut(() => PasswordGeneratorViewModel());
  }
}

class PasswordHistoryBindings extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<PasswordHistoryStore>()) {
      Get.putAsync(() => PasswordHistoryStore().init(), permanent: true);
    }
    Get.lazyPut(() => PasswordHistoryViewModel());
  }
}
