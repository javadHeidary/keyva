import 'package:get/get.dart';
import 'package:keyva/feature/home/model/vault_models.dart';
import 'package:keyva/feature/type/bank_card/data/bank_card_vault_store.dart';
import 'package:keyva/feature/type/login/data/login_vault_store.dart';
import 'package:keyva/feature/type/note/data/note_vault_store.dart';
import 'package:keyva/shared/widget/app_more_widget.dart';

List<AppMoreAction> vaultMoreActionsForItem(VaultListItem item) {
  switch (item.type) {
    case VaultItemType.login:
      final login = Get.find<LoginVaultStore>().findById(item.id);
      if (login == null) return const [];
      return [
        AppMoreAction(
          label: 'کپی نام کاربری',
          value: login.username,
          toastMessage: 'نام کاربری کپی شد',
        ),
        AppMoreAction(
          label: 'کپی رمز عبور',
          value: login.password,
          toastMessage: 'رمز عبور کپی شد',
        ),
      ];
    case VaultItemType.bankCard:
      final card = Get.find<BankCardVaultStore>().findById(item.id);
      if (card == null) return const [];
      return [
        AppMoreAction(
          label: 'کپی شماره کارت',
          value: card.cardNumber,
          toastMessage: 'شماره کارت کپی شد',
        ),
        AppMoreAction(
          label: 'کپی CVV2',
          value: card.cvv,
          toastMessage: 'CVV2 کپی شد',
        ),
        AppMoreAction(
          label: 'کپی تاریخ انقضا',
          value: card.expiry,
          toastMessage: 'تاریخ انقضا کپی شد',
        ),
      ];
    case VaultItemType.secureNote:
      final note = Get.find<NoteVaultStore>().findById(item.id);
      if (note == null) return const [];
      return [
        AppMoreAction(
          label: 'کپی محتوای یادداشت',
          value: note.body,
          toastMessage: 'متن یادداشت کپی شد',
        ),
      ];
  }
}
