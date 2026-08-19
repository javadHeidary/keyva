import 'package:keyva/core/constants/security_constants.dart';

enum MasterPasswordValidationError { empty, tooShort }

abstract final class MasterPasswordPolicy {
  static MasterPasswordValidationError? validate(String password) {
    if (password.isEmpty) {
      return MasterPasswordValidationError.empty;
    }
    if (password.length < SecurityConstants.masterPasswordMinLength) {
      return MasterPasswordValidationError.tooShort;
    }
    return null;
  }

  static bool isValid(String password) => validate(password) == null;

  static String? fieldError(String? value) {
    switch (validate(value ?? '')) {
      case MasterPasswordValidationError.empty:
        return 'رمز عبور الزامی است';
      case MasterPasswordValidationError.tooShort:
        return 'رمز عبور باید حداقل ۸ کاراکتر باشد';
      case null:
        return null;
    }
  }
}
