import 'dart:typed_data';

import 'package:keyva/core/database/models/kdf_parameters.dart';
import 'package:keyva/core/database/models/wrapped_vault_key.dart';
import 'package:keyva/core/exceptions/result.dart';

abstract interface class KeyManagementService {
  KdfParameters defaultKdfParameters();

  Uint8List generateSalt();

  Uint8List generateVaultKey();

  Future<Result<WrappedVaultKey>> wrapVaultKey({
    required Uint8List vaultKey,
    required Uint8List derivedKey,
  });

  Future<Result<Uint8List>> unwrapVaultKey({
    required WrappedVaultKey wrappedVaultKey,
    required Uint8List derivedKey,
  });
}
