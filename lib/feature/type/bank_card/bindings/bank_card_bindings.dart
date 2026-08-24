import 'package:get/get.dart';
import 'package:keyva/core/di/injection_container.dart';
import 'package:keyva/feature/category/bindings/category_bindings.dart';
import 'package:keyva/feature/type/bank_card/data/bank_card_vault_store.dart';
import 'package:keyva/feature/type/bank_card/viewmodel/bank_card_create_viewmodel.dart';
import 'package:keyva/feature/type/bank_card/viewmodel/bank_card_details_viewmodel.dart';
import 'package:keyva/feature/type/bank_card/viewmodel/bank_card_edit_viewmodel.dart';
import 'package:keyva/feature/vault/share/share_sheet_service.dart';
import 'package:keyva/feature/vault/view/vault_item_navigation.dart';
import 'package:keyva/feature/vault/viewmodel/vault_item_viewmodel.dart';

class BankCardBindings extends Bindings {
  @override
  void dependencies() {
    _ensureStore();
  }

  static void _ensureStore() {
    CategoryBindings().dependencies();
    if (!Get.isRegistered<BankCardVaultStore>()) {
      Get.put(BankCardVaultStore(), permanent: true);
    }
  }

  static VaultItemViewModel _itemViewModel() {
    if (!Get.isRegistered<VaultItemViewModel>()) {
      Get.lazyPut(() => getIt<VaultItemViewModel>());
    }
    return Get.find<VaultItemViewModel>();
  }
}

class BankCardCreateBindings extends Bindings {
  @override
  void dependencies() {
    BankCardBindings._ensureStore();
    final items = BankCardBindings._itemViewModel();
    Get.lazyPut(() => BankCardCreateViewModel(items: items));
  }
}

class BankCardEditBindings extends Bindings {
  @override
  void dependencies() {
    BankCardBindings._ensureStore();
    final items = BankCardBindings._itemViewModel();
    final cardId = vaultRouteItemId();
    Get.lazyPut(() => BankCardEditViewModel(cardId: cardId, items: items));
  }
}

class BankCardDetailsBindings extends Bindings {
  @override
  void dependencies() {
    BankCardBindings._ensureStore();
    final cardId = vaultRouteItemId();
    Get.lazyPut(
      () => BankCardDetailsViewModel(
        cardId: cardId,
        shareSheet: getIt<ShareSheetService>(),
      ),
    );
  }
}
