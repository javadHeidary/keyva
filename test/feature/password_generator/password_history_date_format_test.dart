import 'package:flutter_test/flutter_test.dart';
import 'package:keyva/feature/password_generator/util/password_history_date_format.dart';

void main() {
  group('formatPasswordHistoryCopiedAt', () {
    test('formats a local timestamp as Jalali with time', () {
      expect(
        formatPasswordHistoryCopiedAt(DateTime(2026, 7, 1, 12, 0)),
        '1405/04/10 • 12:00',
      );
    });

    test('pads month, day, hour, and minute', () {
      expect(
        formatPasswordHistoryCopiedAt(DateTime(2026, 4, 22, 9, 5)),
        '1405/02/02 • 09:05',
      );
    });

    test('does not convert digits to Persian code points', () {
      final formatted = formatPasswordHistoryCopiedAt(
        DateTime(2026, 7, 1, 12),
      );
      expect(formatted, isNot(contains('۱')));
      expect(formatted, matches(RegExp(r'^\d{4}/\d{2}/\d{2} • \d{2}:\d{2}$')));
    });
  });
}
