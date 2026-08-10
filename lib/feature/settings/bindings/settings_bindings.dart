import 'package:get/get.dart';
import 'package:keyva/feature/settings/viewmodel/settings_viewmodel.dart';

class SettingsBindings extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => SettingsViewModel());
  }
}
