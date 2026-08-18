import 'package:keyva/core/database/hive_database.dart';
import 'package:keyva/core/database/hive_error_mapper.dart';
import 'package:keyva/core/database/models/vault_record.dart';
import 'package:keyva/core/database/vault_data_source.dart';
import 'package:keyva/core/exceptions/app_failure.dart';
import 'package:keyva/core/exceptions/result.dart';

class HiveVaultDataSource implements VaultDataSource {
  HiveVaultDataSource(this._database);

  final HiveDatabase _database;

  @override
  Future<Result<void>> create(VaultRecord vault) async {
    try {
      if (_database.vaults.containsKey(vault.userId)) {
        return const FailureResult(DatabaseFailure());
      }
      await _database.vaults.put(vault.userId, vault);
      return const Success<void>(null);
    } catch (error) {
      return FailureResult(HiveErrorMapper.map(error));
    }
  }

  @override
  Future<Result<VaultRecord?>> findByUserId(String userId) async {
    try {
      return Success(_database.vaults.get(userId));
    } catch (error) {
      return FailureResult(HiveErrorMapper.map(error));
    }
  }

  @override
  Future<Result<void>> update(VaultRecord vault) async {
    try {
      if (!_database.vaults.containsKey(vault.userId)) {
        return const FailureResult(DatabaseFailure());
      }
      await _database.vaults.put(vault.userId, vault);
      return const Success<void>(null);
    } catch (error) {
      return FailureResult(HiveErrorMapper.map(error));
    }
  }

  @override
  Future<Result<void>> delete(String userId) async {
    try {
      await _database.vaults.delete(userId);
      return const Success<void>(null);
    } catch (error) {
      return FailureResult(HiveErrorMapper.map(error));
    }
  }
}
