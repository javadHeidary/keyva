import 'package:flutter_test/flutter_test.dart';
import 'package:keyva/core/security/backup_password_policy.dart';
import 'package:keyva/core/security/master_password_policy.dart';

void main() {
  test('reuses the Master Password length floor', () {
    expect(BackupPasswordPolicy.isValid('12345678'), isTrue);
    expect(BackupPasswordPolicy.validate(''), MasterPasswordValidationError.empty);
    expect(
      BackupPasswordPolicy.validate('1234567'),
      MasterPasswordValidationError.tooShort,
    );
    expect(BackupPasswordPolicy.fieldError(''), MasterPasswordPolicy.fieldError(''));
    expect(BackupPasswordPolicy.fieldError('12345678'), isNull);
  });
}
