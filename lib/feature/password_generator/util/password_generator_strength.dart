import 'package:keyva/feature/type/login/util/login_password_util.dart';

String passwordGeneratorStrengthLabel(double strength) {
  if (strength < 0.2) return 'خیلی ضعیف';
  if (strength < 0.4) return 'ضعیف';
  if (strength < 0.6) return 'خوب';
  if (strength < 0.8) return 'قوی';
  return 'خیلی قوی';
}

int passwordGeneratorStrengthPercent(double strength) {
  return (strength.clamp(0.0, 1.0) * 100).round();
}

double calculatePasswordGeneratorStrength(String password) {
  if (password.isEmpty) return 0;

  double score = calculateLoginPasswordStrength(password);

  final hasLower = RegExp('[a-z]').hasMatch(password);
  final hasUpper = RegExp('[A-Z]').hasMatch(password);
  final hasDigit = RegExp('[0-9]').hasMatch(password);
  final hasSymbol = RegExp(r'[^a-zA-Z0-9]').hasMatch(password);
  final variety = [hasLower, hasUpper, hasDigit, hasSymbol]
      .where((enabled) => enabled)
      .length;
  if (variety >= 3) score += 0.05;
  if (variety == 4) score += 0.05;

  if (password.length >= 20) score += 0.05;

  if (_isPredictablePattern(password)) {
    score -= 0.15;
  }

  return score.clamp(0.0, 1.0);
}

bool _isPredictablePattern(String password) {
  if (RegExp(r'^(.)\1{3,}$').hasMatch(password)) return true;
  if (RegExp(
    r'^(?:0123|1234|2345|3456|4567|5678|6789|abcd|qwer)',
    caseSensitive: false,
  ).hasMatch(password)) {
    return true;
  }
  return false;
}
