import 'package:keyva/core/exceptions/result.dart';
import 'package:keyva/feature/vault/model/vault_data.dart';
import 'package:keyva/feature/vault/session/vault_session.dart';

class VaultSessionImpl implements VaultSession {
  VaultData? _vaultData;

  @override
  bool get isUnlocked => _vaultData != null;

  @override
  VaultData? get vaultData => _vaultData;

  @override
  Future<Result<void>> unlock(VaultData vaultData) async {
    _vaultData = vaultData;
    return const Success<void>(null);
  }

  @override
  Future<Result<void>> lock() async {
    _vaultData = null;
    return const Success<void>(null);
  }
}
