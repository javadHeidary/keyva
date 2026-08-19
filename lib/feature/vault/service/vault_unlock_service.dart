import 'package:keyva/core/exceptions/result.dart';

abstract interface class VaultUnlockService {
  Future<Result<void>> unlock({
    required String userId,
    required String masterPassword,
  });

  Future<Result<void>> unlockWithPin({
    required String userId,
    required String pin,
  });

  Future<Result<void>> unlockWithBiometric({required String userId});

  Future<Result<void>> lock();
}
