import 'dart:convert';
import 'dart:typed_data';

import 'package:keyva/core/crypto/key_management_service.dart';
import 'package:keyva/core/database/models/user_record.dart';
import 'package:keyva/core/database/models/wrapped_vault_key.dart';
import 'package:keyva/core/database/user_data_source.dart';
import 'package:keyva/core/exceptions/app_failure.dart';
import 'package:keyva/core/exceptions/result.dart';
import 'package:keyva/core/security/biometric_gateway.dart';
import 'package:keyva/core/security/biometric_service.dart';
import 'package:keyva/core/security/fast_unlock_storage_keys.dart';
import 'package:keyva/core/security/secure_storage_service.dart';
import 'package:keyva/core/security/wrapped_key_codec.dart';
import 'package:keyva/core/session/session_service.dart';

class BiometricServiceImpl implements BiometricService {
  BiometricServiceImpl({
    required BiometricGateway gateway,
    required KeyManagementService keys,
    required SecureStorageService storage,
    required UserDataSource users,
    required SessionService session,
  }) : _gateway = gateway,
       _keys = keys,
       _storage = storage,
       _users = users,
       _session = session;

  final BiometricGateway _gateway;
  final KeyManagementService _keys;
  final SecureStorageService _storage;
  final UserDataSource _users;
  final SessionService _session;

  @override
  Future<bool> isAvailable() => _gateway.isAvailable();

  @override
  Future<Result<bool>> isEnabled(String userId) async {
    final loaded = await _users.findById(userId);
    if (loaded is FailureResult<UserRecord?>) {
      return FailureResult(loaded.failure);
    }
    final user = (loaded as Success<UserRecord?>).data;
    if (user == null) {
      return const FailureResult(AuthenticationFailure());
    }
    return Success(user.securitySettings.biometricEnabled);
  }

  @override
  Future<Result<void>> enable({required String localizedReason}) async {
    if (!await isAvailable()) {
      return const FailureResult(AuthenticationFailure());
    }
    final vaultKey = _session.vaultKey;
    final userId = _session.current?.userId;
    if (!_session.isAuthenticated || vaultKey == null || userId == null) {
      return const FailureResult(AuthenticationFailure());
    }

    final prompt = await _gateway.authenticate(localizedReason: localizedReason);
    if (prompt == BiometricPromptResult.cancelled) {
      return const FailureResult(BiometricCancelledFailure());
    }
    if (prompt != BiometricPromptResult.success) {
      return const FailureResult(AuthenticationFailure());
    }

    final wrapKey = _keys.generateVaultKey();
    final wrapped = await _keys.wrapVaultKey(
      vaultKey: vaultKey,
      derivedKey: wrapKey,
    );
    if (wrapped is FailureResult<WrappedVaultKey>) {
      wrapKey.fillRange(0, wrapKey.length, 0);
      return const FailureResult(AuthenticationFailure());
    }

    final payload = jsonEncode({
      'wrapKey': base64Encode(wrapKey),
      'wrapped': WrappedKeyCodec.wrappedVaultKeyToJson(
        (wrapped as Success<WrappedVaultKey>).data,
      ),
    });
    wrapKey.fillRange(0, wrapKey.length, 0);

    final stored = await _storage.write(
      FastUnlockStorageKeys.biometricMaterial(userId),
      payload,
    );
    if (stored is FailureResult<void>) {
      return stored;
    }

    final flagged = await _setBiometricEnabled(userId, true);
    if (flagged is FailureResult<void>) {
      await _storage.delete(FastUnlockStorageKeys.biometricMaterial(userId));
      return flagged;
    }
    return const Success<void>(null);
  }

  @override
  Future<Result<void>> disable() async {
    final userId = _session.current?.userId;
    if (!_session.isAuthenticated || userId == null) {
      return const FailureResult(AuthenticationFailure());
    }
    final deleted = await _storage.delete(
      FastUnlockStorageKeys.biometricMaterial(userId),
    );
    if (deleted is FailureResult<void>) {
      return deleted;
    }
    return _setBiometricEnabled(userId, false);
  }

  @override
  Future<Result<Uint8List>> unwrapVaultKey({
    required String userId,
    required String localizedReason,
  }) async {
    if (!await isAvailable()) {
      return const FailureResult(AuthenticationFailure());
    }

    final prompt = await _gateway.authenticate(localizedReason: localizedReason);
    if (prompt == BiometricPromptResult.cancelled) {
      return const FailureResult(BiometricCancelledFailure());
    }
    if (prompt != BiometricPromptResult.success) {
      return const FailureResult(AuthenticationFailure());
    }

    final stored = await _storage.read(
      FastUnlockStorageKeys.biometricMaterial(userId),
    );
    if (stored is FailureResult<String?>) {
      return const FailureResult(AuthenticationFailure());
    }
    final raw = (stored as Success<String?>).data;
    if (raw == null || raw.isEmpty) {
      return const FailureResult(AuthenticationFailure());
    }

    late final Uint8List wrapKey;
    late final WrappedVaultKey wrappedVaultKey;
    try {
      final json = jsonDecode(raw);
      if (json is! Map) {
        return const FailureResult(AuthenticationFailure());
      }
      wrapKey = Uint8List.fromList(base64Decode(json['wrapKey'] as String));
      final wrapped = WrappedKeyCodec.wrappedVaultKeyFromJson(json['wrapped']);
      if (wrapped == null) {
        wrapKey.fillRange(0, wrapKey.length, 0);
        return const FailureResult(AuthenticationFailure());
      }
      wrappedVaultKey = wrapped;
    } catch (_) {
      return const FailureResult(AuthenticationFailure());
    }

    final unwrapped = await _keys.unwrapVaultKey(
      wrappedVaultKey: wrappedVaultKey,
      derivedKey: wrapKey,
    );
    wrapKey.fillRange(0, wrapKey.length, 0);
    if (unwrapped is FailureResult<Uint8List>) {
      return const FailureResult(AuthenticationFailure());
    }
    return unwrapped;
  }

  Future<Result<void>> _setBiometricEnabled(String userId, bool enabled) async {
    final loaded = await _users.findById(userId);
    if (loaded is FailureResult<UserRecord?>) {
      return FailureResult(loaded.failure);
    }
    final user = (loaded as Success<UserRecord?>).data;
    if (user == null) {
      return const FailureResult(AuthenticationFailure());
    }
    return _users.update(
      user.copyWith(
        updatedAt: DateTime.now(),
        securitySettings: user.securitySettings.copyWith(
          biometricEnabled: enabled,
        ),
      ),
    );
  }
}
