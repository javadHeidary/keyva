import 'package:get/get.dart';
import 'package:keyva/feature/category/bindings/category_bindings.dart';
import 'package:keyva/feature/home/bindings/home_bindings.dart';

class CategoryItemsBindings extends Bindings {
  @override
  void dependencies() {
    CategoryBindings().dependencies();
    HomeBindings().dependencies();
  }
}
