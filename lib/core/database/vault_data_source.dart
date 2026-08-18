import 'package:keyva/core/database/models/vault_record.dart';
import 'package:keyva/core/exceptions/result.dart';

abstract interface class VaultDataSource {
  Future<Result<void>> create(VaultRecord vault);

  Future<Result<VaultRecord?>> findByUserId(String userId);

  Future<Result<void>> update(VaultRecord vault);

  Future<Result<void>> delete(String userId);
}
