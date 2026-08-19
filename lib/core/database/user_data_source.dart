import 'package:keyva/core/database/models/user_record.dart';
import 'package:keyva/core/exceptions/result.dart';

abstract interface class UserDataSource {
  Future<Result<void>> create(UserRecord user);

  Future<Result<UserRecord?>> findById(String id);

  Future<Result<bool>> exists(String id);

  Future<Result<List<String>>> listIds();

  Future<Result<void>> update(UserRecord user);
}
