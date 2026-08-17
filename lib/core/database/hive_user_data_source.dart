import 'package:keyva/core/database/hive_database.dart';
import 'package:keyva/core/database/hive_error_mapper.dart';
import 'package:keyva/core/database/models/user_record.dart';
import 'package:keyva/core/database/user_data_source.dart';
import 'package:keyva/core/exceptions/app_failure.dart';
import 'package:keyva/core/exceptions/result.dart';

class HiveUserDataSource implements UserDataSource {
  HiveUserDataSource(this._database);

  final HiveDatabase _database;

  @override
  Future<Result<void>> create(UserRecord user) async {
    try {
      if (_database.users.containsKey(user.id)) {
        return const FailureResult(DatabaseFailure());
      }
      await _database.users.put(user.id, user);
      return const Success<void>(null);
    } catch (error) {
      return FailureResult(HiveErrorMapper.map(error));
    }
  }

  @override
  Future<Result<UserRecord?>> findById(String id) async {
    try {
      return Success(_database.users.get(id));
    } catch (error) {
      return FailureResult(HiveErrorMapper.map(error));
    }
  }

  @override
  Future<Result<bool>> exists(String id) async {
    try {
      return Success(_database.users.containsKey(id));
    } catch (error) {
      return FailureResult(HiveErrorMapper.map(error));
    }
  }

  @override
  Future<Result<void>> update(UserRecord user) async {
    try {
      if (!_database.users.containsKey(user.id)) {
        return const FailureResult(DatabaseFailure());
      }
      await _database.users.put(user.id, user);
      return const Success<void>(null);
    } catch (error) {
      return FailureResult(HiveErrorMapper.map(error));
    }
  }
}
