import 'package:get/get.dart';
import 'package:keyva/feature/shell/viewmodel/main_shell_viewmodel.dart';

void switchMainShellTab(int index) {
  if (!Get.isRegistered<MainShellController>()) return;
  Get.find<MainShellController>().setTab(index);
}
