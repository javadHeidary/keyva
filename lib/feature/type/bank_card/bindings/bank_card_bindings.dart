import 'package:get/get.dart';
import 'package:keyva/feature/type/bank_card/data/bank_card_vault_store.dart';
import 'package:keyva/feature/type/bank_card/viewmodel/bank_card_create_viewmodel.dart';
import 'package:keyva/feature/type/bank_card/viewmodel/bank_card_details_viewmodel.dart';
import 'package:keyva/feature/type/bank_card/viewmodel/bank_card_edit_viewmodel.dart';

class BankCardBindings extends Bindings {
  @override
  void dependencies() {
    _ensureStore();
  }

  static void _ensureStore() {
    if (!Get.isRegistered<BankCardVaultStore>()) {
      Get.put(BankCardVaultStore(), permanent: true);
    }
  }
}

class BankCardCreateBindings extends Bindings {
  @override
  void dependencies() {
    BankCardBindings._ensureStore();
    Get.lazyPut(() => BankCardCreateViewModel());
  }
}

class BankCardEditBindings extends Bindings {
  @override
  void dependencies() {
    BankCardBindings._ensureStore();
    final cardId = Get.arguments as String? ?? '';
    Get.lazyPut(() => BankCardEditViewModel(cardId: cardId));
  }
}

class BankCardDetailsBindings extends Bindings {
  @override
  void dependencies() {
    BankCardBindings._ensureStore();
    final cardId = Get.arguments as String? ?? '';
    Get.lazyPut(() => BankCardDetailsViewModel(cardId: cardId));
  }
}
