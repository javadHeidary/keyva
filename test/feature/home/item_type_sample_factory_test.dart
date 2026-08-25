import 'package:flutter_test/flutter_test.dart';
import 'package:keyva/feature/home/model/item_type_sample_factory.dart';
import 'package:keyva/feature/home/model/vault_models.dart';
import 'package:keyva/feature/type/bank_card/util/bank_card_util.dart';
import 'package:keyva/feature/vault/model/bank_card_item.dart';
import 'package:keyva/feature/vault/model/login_item.dart';
import 'package:keyva/feature/vault/model/secure_note_item.dart';

void main() {
  const factory = ItemTypeSampleFactory();
  final now = DateTime.utc(2026, 8, 25, 12);

  test('creates a demo login with the specified fake fields', () {
    final item = factory.create(VaultItemType.login, now: now) as LoginItem;

    expect(item.id, now.millisecondsSinceEpoch.toString());
    expect(item.title, ItemTypeSampleFactory.loginTitle);
    expect(item.username, ItemTypeSampleFactory.loginUsername);
    expect(item.password, ItemTypeSampleFactory.loginPassword);
    expect(item.website, ItemTypeSampleFactory.loginWebsite);
    expect(item.notes, isNull);
    expect(item.categoryId, isNull);
  });

  test('creates a demo bank card with digits-only Luhn-valid PAN', () {
    final item =
        factory.create(VaultItemType.bankCard, now: now) as BankCardItem;

    expect(item.title, ItemTypeSampleFactory.bankCardTitle);
    expect(item.bankName, ItemTypeSampleFactory.bankCardBankName);
    expect(item.cardHolder, isNotEmpty);
    expect(item.expiryDate, isNotEmpty);
    expect(item.cvv, isNotEmpty);
    expect(item.cardNumber, ItemTypeSampleFactory.bankCardNumber);
    expect(item.cardNumber.contains(' '), isFalse);
    expect(item.cardNumber.length, 16);
    expect(isValidBankCardDigits(item.cardNumber), isTrue);
    expect(verifyCardWithLuhn(item.cardNumber), isTrue);
  });

  test('creates a demo note with the specified fake body', () {
    final item =
        factory.create(VaultItemType.secureNote, now: now) as SecureNoteItem;

    expect(item.title, ItemTypeSampleFactory.noteTitle);
    expect(item.content, ItemTypeSampleFactory.noteContent);
  });
}
