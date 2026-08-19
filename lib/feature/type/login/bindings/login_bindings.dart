import 'package:get/get.dart';
import 'package:keyva/core/di/injection_container.dart';
import 'package:keyva/feature/category/bindings/category_bindings.dart';
import 'package:keyva/feature/type/login/data/login_vault_store.dart';
import 'package:keyva/feature/type/login/viewmodel/login_create_viewmodel.dart';
import 'package:keyva/feature/type/login/viewmodel/login_details_viewmodel.dart';
import 'package:keyva/feature/type/login/viewmodel/login_edit_viewmodel.dart';
import 'package:keyva/feature/vault/viewmodel/vault_item_viewmodel.dart';

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

  static VaultItemViewModel _itemViewModel() {
    if (!Get.isRegistered<VaultItemViewModel>()) {
      Get.lazyPut(() => getIt<VaultItemViewModel>());
    }
    return Get.find<VaultItemViewModel>();
  }
}

class LoginCreateBindings extends Bindings {
  @override
  void dependencies() {
    LoginBindings._ensureStore();
    final items = LoginBindings._itemViewModel();
    Get.lazyPut(() => LoginCreateViewModel(items: items));
  }
}

class LoginEditBindings extends Bindings {
  @override
  void dependencies() {
    LoginBindings._ensureStore();
    final items = LoginBindings._itemViewModel();
    final loginId = Get.arguments as String? ?? '';
    Get.lazyPut(() => LoginEditViewModel(loginId: loginId, items: items));
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
