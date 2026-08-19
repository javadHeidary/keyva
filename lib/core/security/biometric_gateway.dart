enum BiometricPromptResult { success, cancelled, failed }

abstract interface class BiometricGateway {
  Future<bool> isAvailable();

  Future<BiometricPromptResult> authenticate({required String localizedReason});
}
