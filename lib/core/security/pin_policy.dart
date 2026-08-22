import 'package:keyva/core/constants/security_constants.dart';

enum PinValidationError { empty, notDigits, tooShort, tooLong }

abstract final class PinPolicy {
  static final _digitsOnly = RegExp(r'^\d+$');

  static const userMessage = 'پین کد باید ۶ رقم باشد.';

  static PinValidationError? validate(String pin) {
    if (pin.isEmpty) {
      return PinValidationError.empty;
    }
    if (!_digitsOnly.hasMatch(pin)) {
      return PinValidationError.notDigits;
    }
    if (pin.length < SecurityConstants.pinMinLength) {
      return PinValidationError.tooShort;
    }
    if (pin.length > SecurityConstants.pinMaxLength) {
      return PinValidationError.tooLong;
    }
    return null;
  }

  static bool isValid(String pin) => validate(pin) == null;
}
