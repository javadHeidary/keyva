import 'package:keyva/core/security/master_password_policy.dart';

abstract final class BackupPasswordPolicy {
  static MasterPasswordValidationError? validate(String password) {
    return MasterPasswordPolicy.validate(password);
  }

  static bool isValid(String password) => MasterPasswordPolicy.isValid(password);

  static String? fieldError(String? value) {
    return MasterPasswordPolicy.fieldError(value);
  }
}
