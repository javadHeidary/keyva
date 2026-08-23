import 'dart:convert';
import 'dart:typed_data';

import 'package:keyva/core/crypto/crypto_service.dart';
import 'package:keyva/core/crypto/key_management_service.dart';
import 'package:keyva/core/database/models/kdf_parameters.dart';
import 'package:keyva/core/database/models/user_record.dart';
import 'package:keyva/core/database/models/wrapped_vault_key.dart';
import 'package:keyva/core/database/user_data_source.dart';
import 'package:keyva/core/exceptions/app_failure.dart';
import 'package:keyva/core/exceptions/result.dart';
import 'package:keyva/core/security/fast_unlock_storage_keys.dart';
import 'package:keyva/core/security/pin_policy.dart';
import 'package:keyva/core/security/pin_service.dart';
import 'package:keyva/core/security/secure_storage_service.dart';
import 'package:keyva/core/security/unlock_attempt_limiter.dart';
import 'package:keyva/core/security/wrapped_key_codec.dart';
import 'package:keyva/core/session/session_service.dart';

class PinServiceImpl implements PinService {
  PinServiceImpl({
    required CryptoService crypto,
    required KeyManagementService keys,
    required SecureStorageService storage,
    required UserDataSource users,
    required SessionService session,
    required UnlockAttemptLimiter attempts,
  }) : _crypto = crypto,
       _keys = keys,
       _storage = storage,
       _users = users,
       _session = session,
       _attempts = attempts;

  final CryptoService _crypto;
  final KeyManagementService _keys;
  final SecureStorageService _storage;
  final UserDataSource _users;
  final SessionService _session;
  final UnlockAttemptLimiter _attempts;

  @override
  Future<Result<bool>> isEnabled(String userId) async {
    final user = await _loadUser(userId);
    if (user is FailureResult<UserRecord>) {
      return FailureResult(user.failure);
    }
    return Success((user as Success<UserRecord>).data.securitySettings.pinEnabled);
  }

  @override
  Future<Result<bool>> isLockedOut(String userId) async {
    return Success(await _attempts.isLockedOut(UnlockAttemptMethod.pin, userId));
  }

  @override
  Future<Result<int>> remainingAttempts(String userId) async {
    return Success(
      await _attempts.remainingAttempts(UnlockAttemptMethod.pin, userId),
    );
  }

  @override
  Future<Result<void>> enable(String pin) async {
    if (!PinPolicy.isValid(pin)) {
      return const FailureResult(ValidationFailure(message: 'PIN is invalid'));
    }
    final vaultKey = _sessionVaultKey();
    if (vaultKey == null) {
      return const FailureResult(AuthenticationFailure());
    }
    final userId = _session.current!.userId;
    final stored = await _wrapAndStore(userId: userId, pin: pin, vaultKey: vaultKey);
    if (stored is FailureResult<void>) {
      return stored;
    }
    final flagged = await _setPinEnabled(userId, true);
    if (flagged is FailureResult<void>) {
      await _storage.delete(FastUnlockStorageKeys.pinMaterial(userId));
      return flagged;
    }
    await resetFailedAttempts(userId);
    return const Success<void>(null);
  }

  @override
  Future<Result<void>> change({
    required String currentPin,
    required String newPin,
  }) async {
    if (!PinPolicy.isValid(newPin)) {
      return const FailureResult(ValidationFailure(message: 'PIN is invalid'));
    }
    final vaultKey = _sessionVaultKey();
    if (vaultKey == null) {
      return const FailureResult(AuthenticationFailure());
    }
    final userId = _session.current!.userId;
    final verified = await unwrapVaultKey(userId: userId, pin: currentPin);
    if (verified is FailureResult<Uint8List>) {
      return FailureResult(verified.failure);
    }
    final unwrapped = (verified as Success<Uint8List>).data;
    unwrapped.fillRange(0, unwrapped.length, 0);
    return _wrapAndStore(userId: userId, pin: newPin, vaultKey: vaultKey);
  }

  @override
  Future<Result<void>> disable() async {
    final userId = _session.current?.userId;
    if (!_session.isAuthenticated || userId == null) {
      return const FailureResult(AuthenticationFailure());
    }
    final deleted = await _storage.delete(FastUnlockStorageKeys.pinMaterial(userId));
    if (deleted is FailureResult<void>) {
      return deleted;
    }
    final flagged = await _setPinEnabled(userId, false);
    if (flagged is FailureResult<void>) {
      return flagged;
    }
    await resetFailedAttempts(userId);
    return const Success<void>(null);
  }

  @override
  Future<Result<Uint8List>> unwrapVaultKey({
    required String userId,
    required String pin,
  }) async {
    final locked = await isLockedOut(userId);
    if (locked is Success<bool> && locked.data) {
      return const FailureResult(AuthenticationFailure());
    }

    final material = await _loadPinMaterial(userId);
    if (material == null) {
      return const FailureResult(AuthenticationFailure());
    }

    final derived = await _crypto.deriveKey(
      masterPassword: pin,
      salt: material.salt,
      parameters: material.parameters,
    );
    if (derived is FailureResult<Uint8List>) {
      await _attempts.recordFailure(UnlockAttemptMethod.pin, userId);
      return const FailureResult(AuthenticationFailure());
    }
    final derivedKey = (derived as Success<Uint8List>).data;

    final unwrapped = await _keys.unwrapVaultKey(
      wrappedVaultKey: material.wrappedVaultKey,
      derivedKey: derivedKey,
    );
    derivedKey.fillRange(0, derivedKey.length, 0);
    if (unwrapped is FailureResult<Uint8List>) {
      await _attempts.recordFailure(UnlockAttemptMethod.pin, userId);
      return const FailureResult(AuthenticationFailure());
    }

    await resetFailedAttempts(userId);
    return unwrapped;
  }

  @override
  Future<Result<void>> resetFailedAttempts(String userId) async {
    await _attempts.reset(UnlockAttemptMethod.pin, userId);
    return const Success<void>(null);
  }

  Future<Result<void>> _wrapAndStore({
    required String userId,
    required String pin,
    required Uint8List vaultKey,
  }) async {
    final salt = _keys.generateSalt();
    final parameters = _keys.defaultKdfParameters();
    final derived = await _crypto.deriveKey(
      masterPassword: pin,
      salt: salt,
      parameters: parameters,
    );
    if (derived is FailureResult<Uint8List>) {
      return const FailureResult(AuthenticationFailure());
    }
    final derivedKey = (derived as Success<Uint8List>).data;
    final wrapped = await _keys.wrapVaultKey(
      vaultKey: vaultKey,
      derivedKey: derivedKey,
    );
    derivedKey.fillRange(0, derivedKey.length, 0);
    if (wrapped is FailureResult<WrappedVaultKey>) {
      return const FailureResult(AuthenticationFailure());
    }

    final payload = jsonEncode({
      'salt': base64Encode(salt),
      'kdf': WrappedKeyCodec.kdfToJson(parameters),
      'wrapped': WrappedKeyCodec.wrappedVaultKeyToJson(
        (wrapped as Success<WrappedVaultKey>).data,
      ),
    });
    return _storage.write(FastUnlockStorageKeys.pinMaterial(userId), payload);
  }

  Future<_PinMaterial?> _loadPinMaterial(String userId) async {
    final stored = await _storage.read(FastUnlockStorageKeys.pinMaterial(userId));
    if (stored is FailureResult<String?>) {
      return null;
    }
    final raw = (stored as Success<String?>).data;
    if (raw == null || raw.isEmpty) {
      return null;
    }
    try {
      final json = jsonDecode(raw);
      if (json is! Map) {
        return null;
      }
      final saltBytes = base64Decode(json['salt'] as String);
      final kdf = WrappedKeyCodec.kdfFromJson(json['kdf']);
      final wrapped = WrappedKeyCodec.wrappedVaultKeyFromJson(json['wrapped']);
      if (kdf == null || wrapped == null || saltBytes.isEmpty) {
        return null;
      }
      return _PinMaterial(
        salt: Uint8List.fromList(saltBytes),
        parameters: kdf,
        wrappedVaultKey: wrapped,
      );
    } catch (_) {
      return null;
    }
  }

  Future<Result<void>> _setPinEnabled(String userId, bool enabled) async {
    final loaded = await _loadUser(userId);
    if (loaded is FailureResult<UserRecord>) {
      return FailureResult(loaded.failure);
    }
    final user = (loaded as Success<UserRecord>).data;
    return _users.update(
      user.copyWith(
        updatedAt: DateTime.now(),
        securitySettings: user.securitySettings.copyWith(pinEnabled: enabled),
      ),
    );
  }

  Future<Result<UserRecord>> _loadUser(String userId) async {
    final loaded = await _users.findById(userId);
    if (loaded is FailureResult<UserRecord?>) {
      return FailureResult(loaded.failure);
    }
    final user = (loaded as Success<UserRecord?>).data;
    if (user == null) {
      return const FailureResult(AuthenticationFailure());
    }
    return Success(user);
  }

  Uint8List? _sessionVaultKey() {
    if (!_session.isAuthenticated || _session.current == null) {
      return null;
    }
    return _session.vaultKey;
  }
}

class _PinMaterial {
  const _PinMaterial({
    required this.salt,
    required this.parameters,
    required this.wrappedVaultKey,
  });

  final Uint8List salt;
  final KdfParameters parameters;
  final WrappedVaultKey wrappedVaultKey;
}
