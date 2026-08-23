import 'package:flutter_test/flutter_test.dart';
import 'package:keyva/feature/type/bank_card/util/bank_card_util.dart';

void main() {
  group('splitBankCardExpiry', () {
    test('splits stored MM/YY into month and year', () {
      final parts = splitBankCardExpiry('06/30');
      expect(parts.month, '06');
      expect(parts.year, '30');
    });

    test('trims surrounding whitespace before splitting', () {
      final parts = splitBankCardExpiry(' 12/28 ');
      expect(parts.month, '12');
      expect(parts.year, '28');
    });

    test('returns empty parts when the value is malformed', () {
      expect(splitBankCardExpiry(''), (month: '', year: ''));
      expect(splitBankCardExpiry('06'), (month: '', year: ''));
      expect(splitBankCardExpiry('06/30/99'), (month: '', year: ''));
      expect(splitBankCardExpiry('invalid'), (month: '', year: ''));
    });
  });
}
