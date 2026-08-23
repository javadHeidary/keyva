import 'package:flutter_test/flutter_test.dart';
import 'package:keyva/shared/utils/jalali_date_formatter.dart';

void main() {
  group('formatJalaliDate', () {
    test('converts a local July 1 2026 noon to Jalali with Persian digits', () {
      expect(formatJalaliDate(DateTime(2026, 7, 1, 12)), '۱۴۰۵/۰۴/۱۰');
    });

    test('converts 2026-07-01 10:00Z to Jalali with Persian digits', () {
      expect(formatJalaliDate(DateTime.utc(2026, 7, 1, 10)), '۱۴۰۵/۰۴/۱۰');
    });

    test('pads single-digit month and day with Persian zeros', () {
      expect(formatJalaliDate(DateTime(2026, 4, 22, 12)), '۱۴۰۵/۰۲/۰۲');
    });

    test('emits only Persian digits and slashes', () {
      final formatted = formatJalaliDate(DateTime(2026, 7, 1, 12));
      expect(RegExp(r'^[۰-۹]{4}/[۰-۹]{2}/[۰-۹]{2}$').hasMatch(formatted), isTrue);
      expect(RegExp(r'[0-9]').hasMatch(formatted), isFalse);
    });
  });
}
