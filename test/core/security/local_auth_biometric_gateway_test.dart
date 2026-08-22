import 'package:flutter_test/flutter_test.dart';
import 'package:keyva/core/security/biometric_gateway.dart';
import 'package:keyva/core/security/local_auth_biometric_gateway.dart';

void main() {
  test('maps no_fragment_activity to unavailable', () {
    expect(
      LocalAuthBiometricGateway.mapPlatformCode('no_fragment_activity'),
      BiometricPromptResult.unavailable,
    );
  });

  test('maps iOS UserCancelled to cancelled', () {
    expect(
      LocalAuthBiometricGateway.mapPlatformCode('UserCancelled'),
      BiometricPromptResult.cancelled,
    );
  });

  test('maps LockedOut to failed', () {
    expect(
      LocalAuthBiometricGateway.mapPlatformCode('LockedOut'),
      BiometricPromptResult.failed,
    );
  });

  test('maps NotAvailable and NotEnrolled to unavailable', () {
    expect(
      LocalAuthBiometricGateway.mapPlatformCode('NotAvailable'),
      BiometricPromptResult.unavailable,
    );
    expect(
      LocalAuthBiometricGateway.mapPlatformCode('NotEnrolled'),
      BiometricPromptResult.unavailable,
    );
  });
}
