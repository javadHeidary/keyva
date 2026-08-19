import 'dart:typed_data';

import 'package:keyva/core/constants/security_constants.dart';
import 'package:keyva/core/crypto/key_management_service.dart';
import 'package:keyva/core/database/models/kdf_parameters.dart';
import 'package:keyva/core/database/models/wrapped_vault_key.dart';
import 'package:keyva/core/exceptions/result.dart';

class FastKeyManagementService implements KeyManagementService {
  FastKeyManagementService(this._delegate);

  final KeyManagementService _delegate;

  @override
  KdfParameters defaultKdfParameters() {
    return const KdfParameters(
      algorithm: SecurityConstants.kdfAlgorithm,
      memoryCost: 8,
      timeCost: 1,
      parallelism: 1,
      outputLength: SecurityConstants.kdfOutputLength,
    );
  }

  @override
  Uint8List generateSalt() => _delegate.generateSalt();

  @override
  Uint8List generateVaultKey() => _delegate.generateVaultKey();

  @override
  Future<Result<WrappedVaultKey>> wrapVaultKey({
    required Uint8List vaultKey,
    required Uint8List derivedKey,
  }) {
    return _delegate.wrapVaultKey(vaultKey: vaultKey, derivedKey: derivedKey);
  }

  @override
  Future<Result<Uint8List>> unwrapVaultKey({
    required WrappedVaultKey wrappedVaultKey,
    required Uint8List derivedKey,
  }) {
    return _delegate.unwrapVaultKey(
      wrappedVaultKey: wrappedVaultKey,
      derivedKey: derivedKey,
    );
  }
}
