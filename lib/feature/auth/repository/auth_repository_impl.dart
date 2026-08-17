import 'dart:typed_data';

import 'package:keyva/core/crypto/crypto_service.dart';
import 'package:keyva/core/crypto/key_management_service.dart';
import 'package:keyva/core/database/models/security_settings.dart';
import 'package:keyva/core/database/models/user_record.dart';
import 'package:keyva/core/database/models/wrapped_vault_key.dart';
import 'package:keyva/core/database/user_data_source.dart';
import 'package:keyva/core/exceptions/app_failure.dart';
import 'package:keyva/core/exceptions/result.dart';
import 'package:keyva/core/session/session_service.dart';
import 'package:keyva/feature/auth/repository/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required UserDataSource users,
    required CryptoService crypto,
    required KeyManagementService keys,
    required SessionService session,
  }) : _users = users,
       _crypto = crypto,
       _keys = keys,
       _session = session;

  final UserDataSource _users;
  final CryptoService _crypto;
  final KeyManagementService _keys;
  final SessionService _session;

  @override
  Future<Result<UserRecord>> createAccount({
    required String username,
    required String masterPassword,
  }) async {
    final userIdResult = await _uniqueUserId();
    if (userIdResult is FailureResult<String>) {
      return FailureResult(userIdResult.failure);
    }
    final userId = (userIdResult as Success<String>).data;

    final salt = _keys.generateSalt();
    final parameters = _keys.defaultKdfParameters();

    final derived = await _crypto.deriveKey(
      masterPassword: masterPassword,
      salt: salt,
      parameters: parameters,
    );
    if (derived is FailureResult<Uint8List>) {
      return FailureResult(derived.failure);
    }
    final derivedKey = (derived as Success<Uint8List>).data;

    final vaultKey = _keys.generateVaultKey();
    final wrapped = await _keys.wrapVaultKey(
      vaultKey: vaultKey,
      derivedKey: derivedKey,
    );
    derivedKey.fillRange(0, derivedKey.length, 0);
    vaultKey.fillRange(0, vaultKey.length, 0);
    if (wrapped is FailureResult<WrappedVaultKey>) {
      return FailureResult(wrapped.failure);
    }

    final now = DateTime.now();
    final user = UserRecord(
      id: userId,
      username: username,
      createdAt: now,
      updatedAt: now,
      kdfSalt: salt,
      kdfParameters: parameters,
      wrappedVaultKey: (wrapped as Success<WrappedVaultKey>).data,
      securitySettings: SecuritySettings.initial(),
    );

    final persisted = await _users.create(user);
    if (persisted is FailureResult<void>) {
      return FailureResult(persisted.failure);
    }
    return Success(user);
  }

  @override
  Future<Result<UserRecord>> authenticate({
    required String userId,
    required String masterPassword,
  }) async {
    final loaded = await _users.findById(userId);
    if (loaded is FailureResult<UserRecord?>) {
      return _authenticationFailed();
    }
    final user = (loaded as Success<UserRecord?>).data;
    if (user == null) {
      return _authenticationFailed();
    }

    final derived = await _crypto.deriveKey(
      masterPassword: masterPassword,
      salt: user.kdfSalt,
      parameters: user.kdfParameters,
    );
    if (derived is FailureResult<Uint8List>) {
      return _authenticationFailed();
    }
    final derivedKey = (derived as Success<Uint8List>).data;

    final unwrapped = await _keys.unwrapVaultKey(
      wrappedVaultKey: user.wrappedVaultKey,
      derivedKey: derivedKey,
    );
    derivedKey.fillRange(0, derivedKey.length, 0);
    if (unwrapped is FailureResult<Uint8List>) {
      return _authenticationFailed();
    }

    _session.setAuthenticated(
      userId: user.id,
      username: user.username,
      vaultKey: (unwrapped as Success<Uint8List>).data,
    );
    return Success(user);
  }

  @override
  Future<Result<void>> logout() async {
    _session.clear();
    return const Success<void>(null);
  }

  Future<Result<String>> _uniqueUserId() async {
    while (true) {
      final id = _generateUserId();
      final exists = await _users.exists(id);
      if (exists is FailureResult<bool>) {
        return FailureResult(exists.failure);
      }
      if (!(exists as Success<bool>).data) {
        return Success(id);
      }
    }
  }

  String _generateUserId() {
    final bytes = _crypto.generateSecureBytes(16);
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = StringBuffer();
    for (final byte in bytes) {
      hex.write(byte.toRadixString(16).padLeft(2, '0'));
    }
    final value = hex.toString();
    return '${value.substring(0, 8)}-'
        '${value.substring(8, 12)}-'
        '${value.substring(12, 16)}-'
        '${value.substring(16, 20)}-'
        '${value.substring(20, 32)}';
  }

  Result<UserRecord> _authenticationFailed() {
    _session.clear();
    return const FailureResult(AuthenticationFailure());
  }
}
