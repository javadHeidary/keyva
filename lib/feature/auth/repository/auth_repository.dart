import 'package:keyva/core/database/models/user_record.dart';
import 'package:keyva/core/exceptions/result.dart';

abstract interface class AuthRepository {
  Future<Result<UserRecord>> createAccount({
    required String username,
    required String masterPassword,
  });

  Future<Result<UserRecord>> authenticate({
    required String userId,
    required String masterPassword,
  });

  Future<Result<bool>> hasAnyAccount();

  Future<Result<String>> resolveUnlockUserId();

  Future<Result<void>> logout();
}
