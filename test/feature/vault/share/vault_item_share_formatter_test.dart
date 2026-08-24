import 'package:flutter_test/flutter_test.dart';
import 'package:keyva/feature/category/model/category_constants.dart';
import 'package:keyva/feature/type/bank_card/util/bank_card_util.dart';
import 'package:keyva/feature/vault/model/bank_card_item.dart';
import 'package:keyva/feature/vault/model/login_item.dart';
import 'package:keyva/feature/vault/model/secure_note_item.dart';
import 'package:keyva/feature/vault/share/vault_item_share_formatter.dart';

void main() {
  const formatter = VaultItemShareFormatter();
  final createdAt = DateTime.utc(1999, 1, 2, 3);
  final updatedAt = DateTime.utc(1999, 4, 5, 6);

  LoginItem login({
    String? website = 'https://mail.test',
    String? notes,
    String title = 'Mail',
  }) {
    return LoginItem(
      id: 'id-login-uuid',
      title: title,
      username: 'keep-this-user',
      password: 'keep-this-password',
      website: website,
      notes: notes,
      categoryId: 'cat-hidden',
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  BankCardItem card({String? notes}) {
    return BankCardItem(
      id: 'id-card-uuid',
      title: 'Travel',
      cardNumber: '6219861234567890',
      cardHolder: 'Nima Karimi',
      expiryDate: '06/30',
      cvv: '321',
      bankName: 'Saman',
      notes: notes,
      categoryId: 'cat-hidden',
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  SecureNoteItem note({String content = 'building-code-42'}) {
    return SecureNoteItem(
      id: 'id-note-uuid',
      title: 'Gate',
      content: content,
      categoryId: 'cat-hidden',
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  test('login template includes Keyva and expected fields', () {
    final text = formatter.formatLogin(
      login(notes: 'secret note'),
      categoryName: 'Work',
    );

    expect(text, startsWith('Keyva — اطلاعات ورود'));
    expect(text, contains('عنوان: Mail'));
    expect(text, contains('نام کاربری: keep-this-user'));
    expect(text, contains('رمز عبور: keep-this-password'));
    expect(text, contains('وب‌سایت: https://mail.test'));
    expect(text, contains('دسته‌بندی: Work'));
    expect(text, contains('یادداشت: secret note'));
    expect(text, isNot(contains('id-login-uuid')));
    expect(text, isNot(contains('cat-hidden')));
    expect(text, isNot(contains('1999')));
  });

  test('login omits empty optional website and notes', () {
    final text = formatter.formatLogin(
      login(website: null),
      categoryName: CategoryConstants.withoutCategoryLabel,
    );

    expect(text, isNot(contains('وب‌سایت')));
    expect(text, isNot(contains('یادداشت')));
    expect(text, contains('دسته‌بندی: ${CategoryConstants.withoutCategoryLabel}'));
  });

  test('login omits blank website', () {
    final text = formatter.formatLogin(
      login(website: '   '),
      categoryName: CategoryConstants.withoutCategoryLabel,
    );
    expect(text, isNot(contains('وب‌سایت')));
  });

  test('bank card template includes Keyva, grouped number, CVV, and expiry', () {
    final text = formatter.formatBankCard(
      card(notes: 'card note'),
      categoryName: 'Finance',
      bankTitle: 'بانک سامان',
    );

    expect(text, startsWith('Keyva — اطلاعات کارت'));
    expect(text, contains('عنوان: Travel'));
    expect(text, contains('بانک: بانک سامان'));
    expect(
      text,
      contains('شماره کارت: ${formatCardNumberForDisplay('6219861234567890')}'),
    );
    expect(text, contains('تاریخ انقضا: 06 / 30'));
    expect(text, contains('نام دارنده: Nima Karimi'));
    expect(text, contains('CVV2: 321'));
    expect(text, contains('دسته‌بندی: Finance'));
    expect(text, contains('یادداشت: card note'));
    expect(text, isNot(contains('id-card-uuid')));
    expect(text, isNot(contains('1999')));
  });

  test('bank card falls back to item bankName and omits empty notes', () {
    final text = formatter.formatBankCard(
      card(),
      categoryName: CategoryConstants.withoutCategoryLabel,
    );

    expect(text, contains('بانک: Saman'));
    expect(text, isNot(contains('یادداشت')));
  });

  test('secure note template puts content on the following line', () {
    final text = formatter.formatSecureNote(
      note(content: 'line one\nline two'),
      categoryName: 'Personal',
    );

    expect(text, startsWith('Keyva — یادداشت'));
    expect(text, contains('عنوان: Gate'));
    expect(text, contains('دسته‌بندی: Personal'));
    expect(text, contains('توضیحات:\nline one\nline two'));
    expect(text, isNot(contains('id-note-uuid')));
    expect(text, isNot(contains('1999')));
  });

  test('subjects use the Keyva application name', () {
    expect(VaultItemShareFormatter.loginSubject, 'Keyva — اطلاعات ورود');
    expect(VaultItemShareFormatter.cardSubject, 'Keyva — اطلاعات کارت');
    expect(VaultItemShareFormatter.noteSubject, 'Keyva — یادداشت');
  });
}
