import 'package:flutter_test/flutter_test.dart';
import 'package:keyva/core/security/master_password_policy.dart';

void main() {
  test('accepts passwords of at least 8 characters', () {
    expect(MasterPasswordPolicy.isValid('12345678'), isTrue);
    expect(MasterPasswordPolicy.isValid('long-enough'), isTrue);
  });

  test('rejects empty and too-short passwords', () {
    expect(MasterPasswordPolicy.validate(''), MasterPasswordValidationError.empty);
    expect(
      MasterPasswordPolicy.validate('1234567'),
      MasterPasswordValidationError.tooShort,
    );
    expect(MasterPasswordPolicy.isValid('short'), isFalse);
  });

  test('returns the shared field error copy', () {
    expect(MasterPasswordPolicy.fieldError(''), 'رمز عبور الزامی است');
    expect(
      MasterPasswordPolicy.fieldError('1234567'),
      'رمز عبور باید حداقل ۸ کاراکتر باشد',
    );
    expect(MasterPasswordPolicy.fieldError('12345678'), isNull);
  });
}
