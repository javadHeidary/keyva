import 'package:get/get.dart';
import 'package:keyva/feature/home/model/vault_models.dart';
import 'package:keyva/feature/home/viewmodel/home_viewmodel.dart';
import 'package:keyva/feature/type/login/model/login_item_model.dart';

class LoginVaultStore extends GetxService {
  final RxList<LoginItem> items = <LoginItem>[].obs;

  @override
  void onInit() {
    super.onInit();
    if (items.isEmpty) {
      items.add(
        LoginItem(
          id: '1',
          categoryId: 'work',
          title: 'ایمیل سازمانی',
          username: 'ali.rezaei@company.ir',
          password: 'SecurePass123!',
          websites: ['https://company.ir'],
          createdAt: DateTime(2024, 3, 10, 9, 30),
        ),
      );
      _syncHomeVaultList();
    }
  }

  LoginItem? findById(String id) {
    for (final item in items) {
      if (item.id == id) return item;
    }
    return null;
  }

  void add(LoginItem item) {
    items.add(item);
    _syncHomeVaultList();
  }

  void update(LoginItem item) {
    final index = items.indexWhere((entry) => entry.id == item.id);
    if (index == -1) return;
    items[index] = item;
    _syncHomeVaultList();
  }

  void moveToTrash(String id) {
    items.removeWhere((entry) => entry.id == id);
    _syncHomeVaultList();
    if (Get.isRegistered<HomeController>()) {
      Get.find<HomeController>().incrementTrashCount();
    }
  }

  void clearCategoryId(String categoryId) {
    var changed = false;
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      if (item.categoryId == categoryId) {
        items[i] = item.copyWith(clearCategoryId: true);
        changed = true;
      }
    }
    if (changed) _syncHomeVaultList();
  }

  VaultListItem toVaultListItem(LoginItem item) {
    return VaultListItem(
      id: item.id,
      type: VaultItemType.login,
      title: item.title,
      subtitle: item.username,
      categoryId: item.categoryId ?? '',
    );
  }

  void _syncHomeVaultList() {
    if (!Get.isRegistered<HomeController>()) return;
    final home = Get.find<HomeController>();
    home.syncLoginItems(items.map(toVaultListItem).toList());
  }
}
