import 'package:flutter/services.dart';
import 'package:keyva/core/security/biometric_gateway.dart';
import 'package:local_auth/local_auth.dart';

class LocalAuthBiometricGateway implements BiometricGateway {
  LocalAuthBiometricGateway({LocalAuthentication? auth})
    : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  @override
  Future<bool> isAvailable() async {
    try {
      final supported = await _auth.isDeviceSupported();
      if (!supported) {
        return false;
      }
      final types = await _auth.getAvailableBiometrics();
      return types.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<BiometricPromptResult> authenticate({
    required String localizedReason,
  }) async {
    try {
      final ok = await _auth.authenticate(
        localizedReason: localizedReason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
      return ok
          ? BiometricPromptResult.success
          : BiometricPromptResult.cancelled;
    } on PlatformException catch (error) {
      if (_isCancelled(error.code)) {
        return BiometricPromptResult.cancelled;
      }
      return BiometricPromptResult.failed;
    } catch (_) {
      return BiometricPromptResult.failed;
    }
  }

  static bool _isCancelled(String code) {
    return code == 'UserCancel' ||
        code == 'Canceled' ||
        code == 'user_canceled' ||
        code == 'cancelled';
  }
}
