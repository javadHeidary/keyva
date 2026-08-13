import 'package:get/get.dart';
import 'package:keyva/feature/home/bindings/home_bindings.dart';
import 'package:keyva/feature/search/viewmodel/search_viewmodel.dart';

class SearchBindings extends Bindings {
  @override
  void dependencies() {
    HomeBindings().dependencies();
    Get.lazyPut(() => SearchViewModel());
  }
}
