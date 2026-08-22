import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:keyva/core/security/biometric_gateway.dart';
import 'package:local_auth/local_auth.dart';

class LocalAuthBiometricGateway implements BiometricGateway {
  LocalAuthBiometricGateway({
    LocalAuthentication? auth,
    void Function(String message)? diagnosticLog,
  }) : _auth = auth ?? LocalAuthentication(),
       _diagnosticLog = diagnosticLog;

  final LocalAuthentication _auth;
  final void Function(String message)? _diagnosticLog;

  static const _cancelledCodes = {
    'UserCancel',
    'UserCancelled',
    'SystemCancel',
    'Canceled',
    'user_canceled',
    'cancelled',
  };

  static const _unavailableCodes = {
    'NotAvailable',
    'NotEnrolled',
    'PasscodeNotSet',
    'BiometricNotAvailable',
    'no_fragment_activity',
    'no_activity',
  };

  @override
  Future<bool> isAvailable() async {
    try {
      final supported = await _auth.isDeviceSupported();
      if (!supported) {
        _diag('available=false reason=device_unsupported');
        return false;
      }
      final types = await _auth.getAvailableBiometrics();
      final available = types.isNotEmpty;
      _diag('available=$available');
      return available;
    } catch (_) {
      _diag('available=false reason=check_failed');
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
      final result = ok
          ? BiometricPromptResult.success
          : BiometricPromptResult.cancelled;
      _diag('promptResult=$result');
      return result;
    } on PlatformException catch (error) {
      final result = mapPlatformCode(error.code);
      _diag('promptResult=$result code=${error.code}');
      return result;
    } catch (_) {
      _diag('promptResult=${BiometricPromptResult.failed} code=unknown');
      return BiometricPromptResult.failed;
    }
  }

  @visibleForTesting
  static BiometricPromptResult mapPlatformCode(String code) {
    if (_cancelledCodes.contains(code)) {
      return BiometricPromptResult.cancelled;
    }
    if (_unavailableCodes.contains(code)) {
      return BiometricPromptResult.unavailable;
    }
    return BiometricPromptResult.failed;
  }

  void _diag(String message) {
    _diagnosticLog?.call(message);
    if (kDebugMode) {
      developer.log(message, name: 'KeyvaBiometric');
    }
  }
}
