import 'package:keyva/feature/home/model/vault_models.dart';
import 'package:keyva/feature/vault/model/bank_card_item.dart';
import 'package:keyva/feature/vault/model/login_item.dart';
import 'package:keyva/feature/vault/model/secure_note_item.dart';

class ItemTypeSampleFactory {
  const ItemTypeSampleFactory();

  static const loginTitle = 'جیمیل نمونه';
  static const loginUsername = 'ali@gmail.com';
  static const loginPassword = 'Keyva@123456';
  static const loginWebsite = 'https://gmail.com';

  static const bankCardTitle = 'کارت بانکی نمونه';
  static const bankCardNumber = '6037990012345670';
  static const bankCardHolder = 'کاربر نمونه';
  static const bankCardExpiry = '12/30';
  static const bankCardCvv = '000';
  static const bankCardBankName = 'بانک ملی';

  static const noteTitle = 'یادداشت نمونه';
  static const noteContent =
      'این یک یادداشت نمونه است تا نحوه کار کیوا را نشان دهد.';

  static bool supports(VaultItemType type) => type != VaultItemType.image;

  Object create(VaultItemType type, {DateTime? now}) {
    final createdAt = now ?? DateTime.now();
    final id = createdAt.millisecondsSinceEpoch.toString();

    return switch (type) {
      VaultItemType.login => LoginItem(
        id: id,
        title: loginTitle,
        username: loginUsername,
        password: loginPassword,
        website: loginWebsite,
        notes: null,
        categoryId: null,
        createdAt: createdAt,
        updatedAt: createdAt,
      ),
      VaultItemType.bankCard => BankCardItem(
        id: id,
        title: bankCardTitle,
        cardNumber: bankCardNumber,
        cardHolder: bankCardHolder,
        expiryDate: bankCardExpiry,
        cvv: bankCardCvv,
        bankName: bankCardBankName,
        notes: null,
        categoryId: null,
        createdAt: createdAt,
        updatedAt: createdAt,
      ),
      VaultItemType.secureNote => SecureNoteItem(
        id: id,
        title: noteTitle,
        content: noteContent,
        categoryId: null,
        createdAt: createdAt,
        updatedAt: createdAt,
      ),
      VaultItemType.image => throw UnsupportedError(
        'Image folders do not support sample creation',
      ),
    };
  }
}
