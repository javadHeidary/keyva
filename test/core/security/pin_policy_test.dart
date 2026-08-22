import 'package:flutter_test/flutter_test.dart';
import 'package:keyva/core/security/pin_policy.dart';

void main() {
  test('accepts exactly 6 digits', () {
    expect(PinPolicy.isValid('123456'), isTrue);
    expect(PinPolicy.isValid('000001'), isTrue);
    expect(PinPolicy.isValid('654321'), isTrue);
  });

  test('rejects empty, non-digits, too short, too long, and whitespace', () {
    expect(PinPolicy.validate(''), PinValidationError.empty);
    expect(PinPolicy.validate('12ab56'), PinValidationError.notDigits);
    expect(PinPolicy.validate('abcdef'), PinValidationError.notDigits);
    expect(PinPolicy.validate('12345'), PinValidationError.tooShort);
    expect(PinPolicy.validate('1234567'), PinValidationError.tooLong);
    expect(PinPolicy.isValid('12 3456'), isFalse);
    expect(PinPolicy.isValid('1234'), isFalse);
  });

  test('shares a single Persian validation message', () {
    expect(PinPolicy.userMessage, 'پین کد باید ۶ رقم باشد.');
  });
}
