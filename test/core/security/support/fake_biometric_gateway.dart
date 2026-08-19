import 'package:keyva/core/security/biometric_gateway.dart';

class FakeBiometricGateway implements BiometricGateway {
  bool available = true;
  BiometricPromptResult result = BiometricPromptResult.success;
  int authenticateCount = 0;
  String? lastReason;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<BiometricPromptResult> authenticate({
    required String localizedReason,
  }) async {
    authenticateCount++;
    lastReason = localizedReason;
    return result;
  }
}
