import 'dart:typed_data';

import 'package:keyva/core/exceptions/app_failure.dart';
import 'package:keyva/core/exceptions/result.dart';
import 'package:keyva/core/security/pin_service.dart';

class FakePinService implements PinService {
  bool enabled = false;
  bool lockedOut = false;
  AppFailure? unwrapFailure;
  AppFailure? enableFailure;
  String? lastEnabledPin;
  String? lastUnwrapPin;
  int unwrapCount = 0;
  int enableCount = 0;
  int disableCount = 0;
  int resetCount = 0;
  Uint8List vaultKey = Uint8List(32);

  @override
  Future<Result<bool>> isEnabled(String userId) async => Success(enabled);

  @override
  Future<Result<bool>> isLockedOut(String userId) async => Success(lockedOut);

  @override
  Future<Result<void>> enable(String pin) async {
    enableCount++;
    lastEnabledPin = pin;
    final failure = enableFailure;
    if (failure != null) {
      return FailureResult(failure);
    }
    enabled = true;
    return const Success<void>(null);
  }

  @override
  Future<Result<void>> change({
    required String currentPin,
    required String newPin,
  }) async {
    lastEnabledPin = newPin;
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
    required String pin,
  }) async {
    unwrapCount++;
    lastUnwrapPin = pin;
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
    return const Success<void>(null);
  }
}
