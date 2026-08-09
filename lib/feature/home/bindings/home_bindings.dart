import 'package:get/get.dart';
import 'package:keyva/feature/home/viewmodel/home_viewmodel.dart';

class HomeBindings extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<HomeController>()) {
      Get.lazyPut(() => HomeController());
    }
  }
}
