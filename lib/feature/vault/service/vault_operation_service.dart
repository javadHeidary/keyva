import 'package:keyva/core/exceptions/result.dart';
import 'package:keyva/feature/vault/model/vault_data.dart';

abstract interface class VaultOperationService {
  Future<Result<VaultData>> getVault();

  Future<Result<Object>> getItemById(String id);

  Future<Result<void>> addItem(Object item);

  Future<Result<void>> updateItem(Object item);

  Future<Result<void>> deleteItem(String id);
}
