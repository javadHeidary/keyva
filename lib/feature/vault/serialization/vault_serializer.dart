import 'dart:typed_data';

import 'package:keyva/core/exceptions/result.dart';
import 'package:keyva/feature/vault/model/vault_data.dart';

abstract interface class VaultSerializer {
  Future<Result<Uint8List>> serialize(VaultData vault);

  Future<Result<VaultData>> deserialize(Uint8List bytes);
}
