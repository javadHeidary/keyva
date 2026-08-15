import 'package:get/get.dart';
import 'package:keyva/feature/password_generator/data/password_generator_settings_store.dart';
import 'package:keyva/feature/password_generator/data/password_history_store.dart';
import 'package:keyva/feature/password_generator/viewmodel/password_generator_viewmodel.dart';
import 'package:keyva/feature/password_generator/viewmodel/password_history_viewmodel.dart';

class PasswordGeneratorBindings extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<PasswordGeneratorSettingsStore>()) {
      final store = PasswordGeneratorSettingsStore();
      Get.put(store, permanent: true);
      store.init();
    }
    if (!Get.isRegistered<PasswordHistoryStore>()) {
      final store = PasswordHistoryStore();
      Get.put(store, permanent: true);
      store.init();
    }
    Get.lazyPut(() => PasswordGeneratorViewModel());
  }
}

class PasswordHistoryBindings extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<PasswordHistoryStore>()) {
      final store = PasswordHistoryStore();
      Get.put(store, permanent: true);
      store.init();
    }
    Get.lazyPut(() => PasswordHistoryViewModel());
  }
}
