import 'package:get/get.dart';
import 'package:keyva/feature/home/model/vault_models.dart';
import 'package:keyva/feature/home/viewmodel/home_viewmodel.dart';
import 'package:keyva/feature/type/bank_card/model/bank_card_item_model.dart';

class BankCardVaultStore extends GetxService {
  final RxList<BankCardItem> items = <BankCardItem>[].obs;

  @override
  void onInit() {
    super.onInit();
    if (items.isEmpty) {
      items.add(
        BankCardItem(
          id: '2',
          categoryId: 'finance',
          title: 'کارت بانک ملت',
          cardNumber: '6104330000000003',
          bankTitle: 'بانک ملت',
          expiry: '12/28',
          cvv: '123',
          createdAt: DateTime(2024, 2, 15, 14, 0),
        ),
      );
      _syncHomeVaultList();
    }
  }

  BankCardItem? findById(String id) {
    for (final item in items) {
      if (item.id == id) return item;
    }
    return null;
  }

  void add(BankCardItem item) {
    items.add(item);
    _syncHomeVaultList();
  }

  void update(BankCardItem item) {
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

  VaultListItem toVaultListItem(BankCardItem item) {
    return VaultListItem(
      id: item.id,
      type: VaultItemType.bankCard,
      title: item.title,
      subtitle: item.bankTitle,
      categoryId: item.categoryId ?? '',
    );
  }

  void _syncHomeVaultList() {
    if (!Get.isRegistered<HomeController>()) return;
    final home = Get.find<HomeController>();
    home.syncBankCardItems(items.map(toVaultListItem).toList());
  }
}
