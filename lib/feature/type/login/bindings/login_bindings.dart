import 'package:get/get.dart';
import 'package:keyva/feature/category/bindings/category_bindings.dart';
import 'package:keyva/feature/type/login/data/login_vault_store.dart';
import 'package:keyva/feature/type/login/viewmodel/login_create_viewmodel.dart';
import 'package:keyva/feature/type/login/viewmodel/login_details_viewmodel.dart';
import 'package:keyva/feature/type/login/viewmodel/login_edit_viewmodel.dart';

class LoginBindings extends Bindings {
  @override
  void dependencies() {
    _ensureStore();
  }

  static void _ensureStore() {
    CategoryBindings().dependencies();
    if (!Get.isRegistered<LoginVaultStore>()) {
      Get.put(LoginVaultStore(), permanent: true);
    }
  }
}

class LoginCreateBindings extends Bindings {
  @override
  void dependencies() {
    LoginBindings._ensureStore();
    Get.lazyPut(() => LoginCreateViewModel());
  }
}

class LoginEditBindings extends Bindings {
  @override
  void dependencies() {
    LoginBindings._ensureStore();
    final loginId = Get.arguments as String? ?? '';
    Get.lazyPut(() => LoginEditViewModel(loginId: loginId));
  }
}

class LoginDetailsBindings extends Bindings {
  @override
  void dependencies() {
    LoginBindings._ensureStore();
    final loginId = Get.arguments as String? ?? '';
    Get.lazyPut(() => LoginDetailsViewModel(loginId: loginId));
  }
}
