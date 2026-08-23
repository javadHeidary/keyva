import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
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
import 'package:keyva/core/security/unlock_attempt_limiter.dart';
import 'package:keyva/core/security/wrapped_key_codec.dart';
import 'package:keyva/core/session/session_service.dart';

class BiometricServiceImpl implements BiometricService {
  BiometricServiceImpl({
    required BiometricGateway gateway,
    required KeyManagementService keys,
    required SecureStorageService storage,
    required UserDataSource users,
    required SessionService session,
    required UnlockAttemptLimiter attempts,
    void Function(String message)? diagnosticLog,
  }) : _gateway = gateway,
       _keys = keys,
       _storage = storage,
       _users = users,
       _session = session,
       _attempts = attempts,
       _diagnosticLog = diagnosticLog;

  final BiometricGateway _gateway;
  final KeyManagementService _keys;
  final SecureStorageService _storage;
  final UserDataSource _users;
  final SessionService _session;
  final UnlockAttemptLimiter _attempts;
  final void Function(String message)? _diagnosticLog;

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
  Future<Result<bool>> isLockedOut(String userId) async {
    return Success(
      await _attempts.isLockedOut(UnlockAttemptMethod.biometric, userId),
    );
  }

  @override
  Future<Result<int>> remainingAttempts(String userId) async {
    return Success(
      await _attempts.remainingAttempts(UnlockAttemptMethod.biometric, userId),
    );
  }

  @override
  Future<Result<void>> enable({required String localizedReason}) async {
    if (!await isAvailable()) {
      _diag('enable available=false');
      return const FailureResult(BiometricUnavailableFailure());
    }
    final vaultKey = _session.vaultKey;
    final userId = _session.current?.userId;
    if (!_session.isAuthenticated || vaultKey == null || userId == null) {
      return const FailureResult(AuthenticationFailure());
    }

    final prompt = await _gateway.authenticate(localizedReason: localizedReason);
    _diag('enable promptResult=$prompt userIdLength=${userId.length}');
    final promptFailure = _failureForPrompt(prompt);
    if (promptFailure != null) {
      return FailureResult(promptFailure);
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
    await resetFailedAttempts(userId);
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
    final flagged = await _setBiometricEnabled(userId, false);
    if (flagged is FailureResult<void>) {
      return flagged;
    }
    await resetFailedAttempts(userId);
    return flagged;
  }

  @override
  Future<Result<Uint8List>> unwrapVaultKey({
    required String userId,
    required String localizedReason,
  }) async {
    final locked = await isLockedOut(userId);
    if (locked is Success<bool> && locked.data) {
      return const FailureResult(BiometricLockedOutFailure());
    }

    final available = await isAvailable();
    _diag('unwrap available=$available userIdLength=${userId.length}');
    if (!available) {
      return const FailureResult(BiometricUnavailableFailure());
    }

    final prompt = await _gateway.authenticate(localizedReason: localizedReason);
    _diag('unwrap promptResult=$prompt');
    final promptFailure = _failureForPrompt(prompt);
    if (promptFailure != null) {
      if (promptFailure is BiometricAuthFailedFailure) {
        await _attempts.recordFailure(UnlockAttemptMethod.biometric, userId);
      }
      return FailureResult(promptFailure);
    }

    final stored = await _storage.read(
      FastUnlockStorageKeys.biometricMaterial(userId),
    );
    if (stored is FailureResult<String?>) {
      _diag('unwrap hasWrapMaterial=false reason=storage_read_failed');
      return const FailureResult(AuthenticationFailure());
    }
    final raw = (stored as Success<String?>).data;
    if (raw == null || raw.isEmpty) {
      _diag('unwrap hasWrapMaterial=false');
      return const FailureResult(BiometricNotConfiguredFailure());
    }
    _diag('unwrap hasWrapMaterial=true');

    late final Uint8List wrapKey;
    late final WrappedVaultKey wrappedVaultKey;
    try {
      final json = jsonDecode(raw);
      if (json is! Map) {
        _diag('unwrap hasWrapMaterial=true parse=invalid');
        return const FailureResult(BiometricNotConfiguredFailure());
      }
      wrapKey = Uint8List.fromList(base64Decode(json['wrapKey'] as String));
      final wrapped = WrappedKeyCodec.wrappedVaultKeyFromJson(json['wrapped']);
      if (wrapped == null) {
        wrapKey.fillRange(0, wrapKey.length, 0);
        _diag('unwrap hasWrapMaterial=true parse=invalid');
        return const FailureResult(BiometricNotConfiguredFailure());
      }
      wrappedVaultKey = wrapped;
    } catch (_) {
      _diag('unwrap hasWrapMaterial=true parse=invalid');
      return const FailureResult(BiometricNotConfiguredFailure());
    }

    final unwrapped = await _keys.unwrapVaultKey(
      wrappedVaultKey: wrappedVaultKey,
      derivedKey: wrapKey,
    );
    wrapKey.fillRange(0, wrapKey.length, 0);
    if (unwrapped is FailureResult<Uint8List>) {
      _diag('unwrap crypto=failed');
      return const FailureResult(AuthenticationFailure());
    }
    _diag('unwrap crypto=success');
    await resetFailedAttempts(userId);
    return unwrapped;
  }

  @override
  Future<Result<void>> resetFailedAttempts(String userId) async {
    await _attempts.reset(UnlockAttemptMethod.biometric, userId);
    return const Success<void>(null);
  }

  AppFailure? _failureForPrompt(BiometricPromptResult prompt) {
    switch (prompt) {
      case BiometricPromptResult.success:
        return null;
      case BiometricPromptResult.cancelled:
        return const BiometricCancelledFailure();
      case BiometricPromptResult.unavailable:
        return const BiometricUnavailableFailure();
      case BiometricPromptResult.failed:
        return const BiometricAuthFailedFailure();
    }
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

  void _diag(String message) {
    _diagnosticLog?.call(message);
    if (kDebugMode) {
      developer.log(message, name: 'KeyvaBiometric');
    }
  }
}
