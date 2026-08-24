import 'package:keyva/feature/type/bank_card/util/bank_card_util.dart';
import 'package:keyva/feature/vault/model/bank_card_item.dart';
import 'package:keyva/feature/vault/model/login_item.dart';
import 'package:keyva/feature/vault/model/secure_note_item.dart';

class VaultItemShareFormatter {
  const VaultItemShareFormatter();

  static const appName = 'Keyva';
  static const loginHeading = 'اطلاعات اکانت';
  static const cardHeading = 'اطلاعات کارت';
  static const noteHeading = 'یادداشت';

  static String get loginSubject => '$appName — $loginHeading';
  static String get cardSubject => '$appName — $cardHeading';
  static String get noteSubject => '$appName — $noteHeading';

  String formatLogin(LoginItem item, {required String categoryName}) {
    final buffer = StringBuffer()
      ..writeln(loginSubject)
      ..writeln();
    _line(buffer, 'عنوان', item.title);
    _line(buffer, 'نام کاربری', item.username);
    _line(buffer, 'رمز عبور', item.password);
    _optionalLine(buffer, 'وب‌سایت', item.website);
    _line(buffer, 'دسته‌بندی', categoryName);
    _optionalLine(buffer, 'یادداشت', item.notes);
    return _finish(buffer);
  }

  String formatBankCard(
    BankCardItem item, {
    required String categoryName,
    String? bankTitle,
  }) {
    final bank = _nonEmpty(bankTitle) ?? item.bankName;
    final buffer = StringBuffer()
      ..writeln(cardSubject)
      ..writeln();
    _line(buffer, 'عنوان', item.title);
    _line(buffer, 'بانک', bank);
    _line(buffer, 'شماره کارت', formatCardNumberForDisplay(item.cardNumber));
    _line(buffer, 'تاریخ انقضا', formatShareExpiry(item.expiryDate));
    _line(buffer, 'نام دارنده', item.cardHolder);
    _line(buffer, 'CVV2', item.cvv);
    _line(buffer, 'دسته‌بندی', categoryName);
    _optionalLine(buffer, 'یادداشت', item.notes);
    return _finish(buffer);
  }

  String formatSecureNote(
    SecureNoteItem item, {
    required String categoryName,
  }) {
    final buffer = StringBuffer()
      ..writeln(noteSubject)
      ..writeln();
    _line(buffer, 'عنوان', item.title);
    _line(buffer, 'دسته‌بندی', categoryName);
    buffer.writeln('توضیحات:');
    buffer.write(item.content);
    return _finish(buffer);
  }

  static String formatShareExpiry(String expiryDate) {
    final trimmed = expiryDate.trim();
    final parts = trimmed.split('/');
    if (parts.length != 2) return trimmed;
    return '${parts[0].trim()} / ${parts[1].trim()}';
  }

  static void _line(StringBuffer buffer, String label, String value) {
    buffer.writeln('$label: $value');
  }

  static void _optionalLine(StringBuffer buffer, String label, String? value) {
    final text = _nonEmpty(value);
    if (text == null) return;
    _line(buffer, label, text);
  }

  static String? _nonEmpty(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }

  static String _finish(StringBuffer buffer) {
    return buffer.toString().trimRight();
  }
}
