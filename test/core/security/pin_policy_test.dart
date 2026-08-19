import 'package:flutter_test/flutter_test.dart';
import 'package:keyva/core/security/pin_policy.dart';

void main() {
  test('accepts 4 to 6 digits', () {
    expect(PinPolicy.isValid('1234'), isTrue);
    expect(PinPolicy.isValid('12345'), isTrue);
    expect(PinPolicy.isValid('123456'), isTrue);
  });

  test('rejects empty, non-digits, too short, and too long values', () {
    expect(PinPolicy.validate(''), PinValidationError.empty);
    expect(PinPolicy.validate('12ab'), PinValidationError.notDigits);
    expect(PinPolicy.validate('123'), PinValidationError.tooShort);
    expect(PinPolicy.validate('1234567'), PinValidationError.tooLong);
    expect(PinPolicy.isValid('12 34'), isFalse);
  });
}
