import 'dart:typed_data';

import 'package:keyva/core/exceptions/app_failure.dart';
import 'package:keyva/core/exceptions/result.dart';
import 'package:keyva/core/security/biometric_service.dart';

class FakeBiometricService implements BiometricService {
  bool available = false;
  bool enabled = false;
  bool lockedOut = false;
  int remaining = 3;
  AppFailure? unwrapFailure;
  AppFailure? enableFailure;
  int unwrapCount = 0;
  int enableCount = 0;
  int disableCount = 0;
  int resetCount = 0;
  Uint8List vaultKey = Uint8List(32);

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<Result<bool>> isEnabled(String userId) async => Success(enabled);

  @override
  Future<Result<bool>> isLockedOut(String userId) async => Success(lockedOut);

  @override
  Future<Result<int>> remainingAttempts(String userId) async =>
      Success(lockedOut ? 0 : remaining);

  @override
  Future<Result<void>> enable({required String localizedReason}) async {
    enableCount++;
    final failure = enableFailure;
    if (failure != null) {
      return FailureResult(failure);
    }
    enabled = true;
    return const Success<void>(null);
  }

  @override
  Future<Result<void>> disable() async {
    disableCount++;
    enabled = false;
    return const Success<void>(null);
  }

  @override
  Future<Result<Uint8List>> unwrapVaultKey({
    required String userId,
    required String localizedReason,
  }) async {
    unwrapCount++;
    final failure = unwrapFailure;
    if (failure != null) {
      return FailureResult(failure);
    }
    return Success(Uint8List.fromList(vaultKey));
  }

  @override
  Future<Result<void>> resetFailedAttempts(String userId) async {
    resetCount++;
    lockedOut = false;
    remaining = 3;
    return const Success<void>(null);
  }
}
