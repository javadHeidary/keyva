import 'package:get/get.dart';

class MainShellController extends GetxController {
  final currentIndex = 0.obs;

  void setTab(int index) {
    currentIndex.value = index;
  }
}
