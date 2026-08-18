import 'dart:typed_data';

import 'package:keyva/core/exceptions/result.dart';

abstract interface class VaultRepository {
  Future<Result<Uint8List?>> loadVaultData();

  Future<Result<void>> saveVaultData(Uint8List plaintext);

  Future<Result<void>> deleteVault();
}
