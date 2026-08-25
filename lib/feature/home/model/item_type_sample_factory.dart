import 'package:keyva/feature/home/model/vault_models.dart';
import 'package:keyva/feature/vault/model/bank_card_item.dart';
import 'package:keyva/feature/vault/model/image_folder.dart';
import 'package:keyva/feature/vault/model/login_item.dart';
import 'package:keyva/feature/vault/model/secure_note_item.dart';

class ItemTypeSampleFactory {
  const ItemTypeSampleFactory();

  static const loginTitle = 'Example Gmail';
  static const loginUsername = 'example@gmail.com';
  static const loginPassword = 'Example@123456';
  static const loginWebsite = 'https://gmail.com';

  static const bankCardTitle = 'Example Bank Card';
  static const bankCardNumber = '6037990012345670';
  static const bankCardHolder = 'Example User';
  static const bankCardExpiry = '12/30';
  static const bankCardCvv = '000';
  static const bankCardBankName = 'Example Bank';

  static const noteTitle = 'Example Note';
  static const noteContent =
      'This is an example note created to demonstrate how Keyva works.';
  static const imageFolderTitle = 'Example Photos';

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
      VaultItemType.image => ImageFolder(
        id: id,
        title: imageFolderTitle,
        categoryId: null,
        createdAt: createdAt,
        updatedAt: createdAt,
      ),
    };
  }
}
