import 'dart:typed_data';

import 'package:keyva/core/database/models/security_settings.dart';
import 'package:keyva/core/database/models/user_record.dart';
import 'package:keyva/core/exceptions/result.dart';
import 'package:keyva/feature/auth/model/account_summary.dart';

abstract interface class AuthRepository {
  Future<Result<UserRecord>> createAccount({
    required String username,
    required String masterPassword,
  });

  Future<Result<UserRecord>> authenticate({
    required String userId,
    required String masterPassword,
  });

  Future<Result<UserRecord>> openSession({
    required String userId,
    required Uint8List vaultKey,
  });

  Future<Result<void>> changeMasterPassword({
    required String currentPassword,
    required String newPassword,
  });

  Future<Result<SecuritySettings>> currentSecuritySettings();

  Future<Result<void>> setAutoLockTimeout(Duration timeout);

  Future<Result<void>> setPreventScreenshots(bool enabled);

  Future<Result<bool>> hasAnyAccount();

  Future<Result<List<AccountSummary>>> getAccounts();

  Future<Result<AccountSummary>> getAccount(String userId);

  Future<Result<String>> resolveUnlockUserId();

  Future<Result<void>> logout();
}
