import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/get_instance.dart';
import 'package:keyva/feature/auth/view_model/auth_login_viewmodel.dart';
import 'package:keyva/feature/auth/view_model/auth_register_viewmodel.dart';

class AuthBindings extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<LoginController>()) {
      Get.lazyPut(() => LoginController());
    }
    if (!Get.isRegistered<RegisterController>()) {
      Get.lazyPut(() => RegisterController());
    }
  }
}
