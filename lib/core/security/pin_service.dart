import 'dart:typed_data';

import 'package:keyva/core/exceptions/result.dart';

abstract interface class PinService {
  Future<Result<bool>> isEnabled(String userId);

  Future<Result<bool>> isLockedOut(String userId);

  Future<Result<int>> remainingAttempts(String userId);

  Future<Result<void>> enable(String pin);

  Future<Result<void>> change({
    required String currentPin,
    required String newPin,
  });

  Future<Result<void>> disable();

  Future<Result<Uint8List>> unwrapVaultKey({
    required String userId,
    required String pin,
  });

  Future<Result<void>> resetFailedAttempts(String userId);
}
