import 'package:get/get.dart';

abstract final class MainShellTab {
  static const int home = 0;
  static const int passwordGenerator = 1;
  static const int categories = 2;
  static const int settings = 3;

  static const int tabCount = 4;
}

class MainShellController extends GetxController {
  final currentIndex = MainShellTab.home.obs;

  void setTab(int index) {
    if (index < 0 || index >= MainShellTab.tabCount) return;
    currentIndex.value = index;
  }

  void resetToHome() {
    currentIndex.value = MainShellTab.home;
  }
}
