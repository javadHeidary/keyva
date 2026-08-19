import 'dart:typed_data';

import 'package:keyva/core/constants/security_constants.dart';
import 'package:keyva/core/database/models/kdf_parameters.dart';
import 'package:keyva/core/database/models/security_settings.dart';
import 'package:keyva/core/database/models/user_record.dart';
import 'package:keyva/core/database/models/wrapped_vault_key.dart';
import 'package:keyva/core/exceptions/app_failure.dart';
import 'package:keyva/core/exceptions/result.dart';
import 'package:keyva/feature/auth/repository/auth_repository.dart';

class FakeAuthRepository implements AuthRepository {
  bool anyAccount = true;
  String? unlockUserId = 'user-1';
  AppFailure? resolveFailure;
  AppFailure? createFailure;
  int createCount = 0;
  int logoutCount = 0;
  int resolveCount = 0;
  String? lastCreatedUsername;
  String? lastCreatedPassword;
  bool userRecordDeleted = false;
  bool vaultRecordDeleted = false;

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
  Future<Result<UserRecord>> openSession({
    required String userId,
    required Uint8List vaultKey,
  }) async {
    return Success(_fakeUser(username: 'test'));
  }

  @override
  Future<Result<bool>> hasAnyAccount() async {
    return Success(anyAccount);
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
