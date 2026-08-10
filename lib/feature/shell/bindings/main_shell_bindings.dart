import 'package:get/get.dart';
import 'package:keyva/feature/category/bindings/category_bindings.dart';
import 'package:keyva/feature/category/viewmodel/category_list_viewmodel.dart';
import 'package:keyva/feature/home/bindings/home_bindings.dart';
import 'package:keyva/feature/shell/viewmodel/main_shell_viewmodel.dart';

class MainShellBindings extends Bindings {
  @override
  void dependencies() {
    HomeBindings().dependencies();
    CategoryBindings().dependencies();
    Get.lazyPut(() => CategoryListViewModel());
    Get.lazyPut(() => MainShellController());
  }
}
