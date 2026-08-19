import 'package:keyva/core/exceptions/result.dart';

abstract interface class VaultUnlockService {
  Future<Result<void>> unlock({
    required String userId,
    required String masterPassword,
  });

  Future<Result<void>> lock();
}
