import 'package:flutter/services.dart';
import 'package:iranian_banks/iranian_banks.dart';
import 'package:persian_number_utility/persian_number_utility.dart';

class BankCardNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = extractCardDigits(newValue.text);
    if (digits.length > 16) {
      return oldValue;
    }
    final formatted = formatCardNumberForDisplay(digits);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class BankCardExpiryInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 4) {
      return oldValue;
    }
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i == 2) buffer.write('/');
      buffer.write(digits[i]);
    }
    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

class BankCardCvvInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 4) {
      return oldValue;
    }
    return TextEditingValue(
      text: digits,
      selection: TextSelection.collapsed(offset: digits.length),
    );
  }
}

String extractCardDigits(String raw) {
  return NumberUtility.extractNumber(raw, NumStrLanguage.English);
}

String formatCardNumberForDisplay(String digits) {
  if (digits.isEmpty) return '';
  return NumberUtility.charRagham(digits, separator: ' ');
}

bool isValidBankCardDigits(String digits) {
  if (digits.length != 16) return false;
  return digits.isValidBankCardNumber();
}

BankInfoView? resolveBankInfoFromCard(String digits) {
  if (digits.length < 6) return null;
  return IranianBanks.getBankFromCard(digits);
}

bool verifyCardWithLuhn(String digits) {
  if (digits.length != 16) return false;
  return IranianBanks.verifyCardNumber(digits);
}

({String month, String year}) splitBankCardExpiry(String expiryDate) {
  final parts = expiryDate.trim().split('/');
  if (parts.length != 2) {
    return (month: '', year: '');
  }
  return (month: parts[0], year: parts[1]);
}

String? validateExpiryInput(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'تاریخ انقضا الزامی است';
  }
  final trimmed = value.trim();
  if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(trimmed)) {
    return 'فرمت باید MM/YY باشد';
  }
  final parts = trimmed.split('/');
  final month = int.tryParse(parts[0]);
  if (month == null || month < 1 || month > 12) {
    return 'ماه نامعتبر است';
  }
  return null;
}

String? validateCvvInput(String? value) {
  if (value == null || value.isEmpty) {
    return 'CVV2 الزامی است';
  }
  if (!RegExp(r'^\d{3,4}$').hasMatch(value)) {
    return 'CVV2 باید ۳ یا ۴ رقم باشد';
  }
  return null;
}

String formatBankCardCreatedAt(DateTime dateTime) {
  final y = dateTime.year.toString().padLeft(4, '0');
  final m = dateTime.month.toString().padLeft(2, '0');
  final d = dateTime.day.toString().padLeft(2, '0');
  return '$y/$m/$d';
}
