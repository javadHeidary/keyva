import 'dart:async';
import 'dart:typed_data';

import 'package:keyva/core/constants/security_constants.dart';
import 'package:keyva/core/database/models/kdf_parameters.dart';
import 'package:keyva/core/database/models/security_settings.dart';
import 'package:keyva/core/database/models/user_record.dart';
import 'package:keyva/core/database/models/wrapped_vault_key.dart';
import 'package:keyva/core/exceptions/app_failure.dart';
import 'package:keyva/core/exceptions/result.dart';
import 'package:keyva/feature/auth/model/account_deletion_outcome.dart';
import 'package:keyva/feature/auth/model/account_summary.dart';
import 'package:keyva/feature/auth/repository/auth_repository.dart';

class FakeAuthRepository implements AuthRepository {
  bool anyAccount = true;
  String? unlockUserId = 'user-1';
  AppFailure? resolveFailure;
  AppFailure? createFailure;
  int createCount = 0;
  int logoutCount = 0;
  int resolveCount = 0;
  int changeMasterPasswordCount = 0;
  int setAutoLockTimeoutCount = 0;
  String? lastCreatedUsername;
  String? lastCreatedPassword;
  String? lastCurrentPassword;
  String? lastNewPassword;
  Duration autoLockTimeout = const Duration(minutes: 1);
  Duration? lastAutoLockTimeout;
  AppFailure? changeMasterPasswordFailure;
  AppFailure? setAutoLockTimeoutFailure;
  AppFailure? currentSecuritySettingsFailure;
  int setPreventScreenshotsCount = 0;
  bool preventScreenshots = false;
  bool? lastPreventScreenshots;
  AppFailure? setPreventScreenshotsFailure;
  bool userRecordDeleted = false;
  bool vaultRecordDeleted = false;
  int deleteAccountCount = 0;
  String? lastDeletePassword;
  AppFailure? deleteAccountFailure;
  bool deleteHasRemainingAccounts = false;
  Completer<void>? deleteAccountGate;
  bool masterPasswordLockedOut = false;
  int remainingMasterPasswordAttemptCount = 6;
  Duration remainingMasterPasswordLockoutDuration = Duration.zero;
  List<AccountSummary> accounts = const [
    AccountSummary(id: 'user-1', username: 'علی'),
  ];

  @override
  Future<Result<UserRecord>> createAccount({
    required String username,
    required String masterPassword,
  }) async {
    createCount++;
    lastCreatedUsername = username;
    lastCreatedPassword = masterPassword;
    final failure = createFailure;
    if (failure != null) {
      return FailureResult(failure);
    }
    return Success(_fakeUser(username: username));
  }

  @override
  Future<Result<UserRecord>> authenticate({
    required String userId,
    required String masterPassword,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<Result<bool>> isMasterPasswordLockedOut(String userId) async {
    return Success(masterPasswordLockedOut);
  }

  @override
  Future<Result<int>> remainingMasterPasswordAttempts(String userId) async {
    return Success(remainingMasterPasswordAttemptCount);
  }

  @override
  Future<Result<Duration>> remainingMasterPasswordLockout(String userId) async {
    return Success(remainingMasterPasswordLockoutDuration);
  }

  @override
  Future<Result<UserRecord>> openSession({
    required String userId,
    required Uint8List vaultKey,
  }) async {
    return Success(_fakeUser(username: 'test'));
  }

  @override
  Future<Result<void>> changeMasterPassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    changeMasterPasswordCount++;
    lastCurrentPassword = currentPassword;
    lastNewPassword = newPassword;
    final failure = changeMasterPasswordFailure;
    if (failure != null) {
      return FailureResult(failure);
    }
    return const Success(null);
  }

  @override
  Future<Result<SecuritySettings>> currentSecuritySettings() async {
    final failure = currentSecuritySettingsFailure;
    if (failure != null) {
      return FailureResult(failure);
    }
    return Success(
      SecuritySettings.initial().copyWith(
        autoLockTimeout: autoLockTimeout,
        preventScreenshots: preventScreenshots,
      ),
    );
  }

  @override
  Future<Result<void>> setAutoLockTimeout(Duration timeout) async {
    setAutoLockTimeoutCount++;
    lastAutoLockTimeout = timeout;
    final failure = setAutoLockTimeoutFailure;
    if (failure != null) {
      return FailureResult(failure);
    }
    autoLockTimeout = timeout;
    return const Success(null);
  }

  @override
  Future<Result<void>> setPreventScreenshots(bool enabled) async {
    setPreventScreenshotsCount++;
    lastPreventScreenshots = enabled;
    final failure = setPreventScreenshotsFailure;
    if (failure != null) {
      return FailureResult(failure);
    }
    preventScreenshots = enabled;
    return const Success(null);
  }

  UserRecord? storedUser;
  AppFailure? currentUserFailure;
  AppFailure? updateProfileFailure;
  int updateProfileCount = 0;
  String? lastUpdatedUsername;

  @override
  Future<Result<UserRecord>> currentUser() async {
    final failure = currentUserFailure;
    if (failure != null) {
      return FailureResult(failure);
    }
    final user = storedUser;
    if (user == null) {
      return const FailureResult(AuthenticationFailure());
    }
    return Success(user);
  }

  @override
  Future<Result<void>> updateProfile({
    required String username,
  }) async {
    updateProfileCount++;
    lastUpdatedUsername = username;
    final failure = updateProfileFailure;
    if (failure != null) {
      return FailureResult(failure);
    }
    final trimmedName = username.trim();
    if (trimmedName.isEmpty) {
      return const FailureResult(ValidationFailure());
    }
    storedUser = (storedUser ?? _fakeUser(username: trimmedName)).copyWith(
      username: trimmedName,
    );
    accounts = [
      for (final account in accounts)
        if (account.id == storedUser!.id)
          AccountSummary(id: account.id, username: trimmedName)
        else
          account,
    ];
    return const Success(null);
  }

  @override
  Future<Result<bool>> hasAnyAccount() async {
    return Success(anyAccount);
  }

  @override
  Future<Result<List<AccountSummary>>> getAccounts() async {
    return Success(List<AccountSummary>.from(accounts));
  }

  @override
  Future<Result<AccountSummary>> getAccount(String userId) async {
    for (final account in accounts) {
      if (account.id == userId) {
        return Success(account);
      }
    }
    return const FailureResult(AuthenticationFailure());
  }

  @override
  Future<Result<String>> resolveUnlockUserId() async {
    resolveCount++;
    final failure = resolveFailure;
    if (failure != null) {
      return FailureResult(failure);
    }
    final id = unlockUserId;
    if (id == null) {
      return const FailureResult(AuthenticationFailure());
    }
    return Success(id);
  }

  @override
  Future<Result<void>> logout() async {
    logoutCount++;
    return const Success(null);
  }

  @override
  Future<Result<AccountDeletionOutcome>> deleteAccount({
    required String masterPassword,
  }) async {
    deleteAccountCount++;
    lastDeletePassword = masterPassword;
    final gate = deleteAccountGate;
    if (gate != null) {
      await gate.future;
    }
    final failure = deleteAccountFailure;
    if (failure != null) {
      return FailureResult(failure);
    }
    userRecordDeleted = true;
    vaultRecordDeleted = true;
    if (!deleteHasRemainingAccounts) {
      accounts = const [];
      anyAccount = false;
    }
    return Success(
      AccountDeletionOutcome(hasRemainingAccounts: deleteHasRemainingAccounts),
    );
  }
}

UserRecord _fakeUser({required String username}) {
  return UserRecord(
    id: 'user-1',
    username: username,
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 2),
    kdfSalt: Uint8List.fromList(List<int>.filled(16, 1)),
    kdfParameters: const KdfParameters(
      algorithm: SecurityConstants.kdfAlgorithm,
      memoryCost: SecurityConstants.kdfMemoryCost,
      timeCost: SecurityConstants.kdfTimeCost,
      parallelism: SecurityConstants.kdfParallelism,
      outputLength: SecurityConstants.kdfOutputLength,
    ),
    wrappedVaultKey: WrappedVaultKey(
      version: SecurityConstants.wrappedKeyVersion,
      nonce: Uint8List.fromList(List<int>.filled(12, 2)),
      ciphertext: Uint8List.fromList(List<int>.filled(48, 3)),
      authenticationTag: Uint8List.fromList(List<int>.filled(16, 4)),
    ),
    securitySettings: SecuritySettings.initial(),
  );
}
