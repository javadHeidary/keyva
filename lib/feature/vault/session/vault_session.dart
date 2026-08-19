import 'package:keyva/core/exceptions/result.dart';
import 'package:keyva/feature/vault/model/vault_data.dart';

abstract interface class VaultSession {
  bool get isUnlocked;

  VaultData? get vaultData;

  Future<Result<void>> unlock(VaultData vaultData);

  Future<Result<void>> lock();
}
