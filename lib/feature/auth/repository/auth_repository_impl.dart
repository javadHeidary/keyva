import 'dart:typed_data';

import 'package:keyva/core/constants/database_constants.dart';
import 'package:keyva/core/crypto/crypto_service.dart';
import 'package:keyva/core/crypto/key_management_service.dart';
import 'package:keyva/core/database/hive_database.dart';
import 'package:keyva/core/database/models/security_settings.dart';
import 'package:keyva/core/database/models/user_record.dart';
import 'package:keyva/core/database/models/vault_record.dart';
import 'package:keyva/core/database/models/wrapped_vault_key.dart';
import 'package:keyva/core/database/user_data_source.dart';
import 'package:keyva/core/database/vault_data_source.dart';
import 'package:keyva/core/exceptions/app_failure.dart';
import 'package:keyva/core/exceptions/result.dart';
import 'package:keyva/core/security/fast_unlock_storage_keys.dart';
import 'package:keyva/core/security/master_password_policy.dart';
import 'package:keyva/core/security/secure_storage_service.dart';
import 'package:keyva/core/security/unlock_attempt_limiter.dart';
import 'package:keyva/core/session/session_service.dart';
import 'package:keyva/feature/auth/model/account_deletion_outcome.dart';
import 'package:keyva/feature/auth/model/account_summary.dart';
import 'package:keyva/feature/auth/repository/auth_repository.dart';
import 'package:keyva/feature/vault/blob/encrypted_blob_store.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required UserDataSource users,
    required CryptoService crypto,
    required KeyManagementService keys,
    required SessionService session,
    required HiveDatabase database,
    required VaultDataSource vaults,
    SecureStorageService? secureStorage,
    UnlockAttemptLimiter? attempts,
    EncryptedBlobStore? blobs,
  }) : _users = users,
       _crypto = crypto,
       _keys = keys,
       _session = session,
       _database = database,
       _vaults = vaults,
       _secureStorage = secureStorage,
       _attempts = attempts,
       _blobs = blobs;

  final UserDataSource _users;
  final CryptoService _crypto;
  final KeyManagementService _keys;
  final SessionService _session;
  final HiveDatabase _database;
  final VaultDataSource _vaults;
  final SecureStorageService? _secureStorage;
  final UnlockAttemptLimiter? _attempts;
  final EncryptedBlobStore? _blobs;

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

    return openSession(
      userId: user.id,
      vaultKey: (unwrapped as Success<Uint8List>).data,
    );
  }

  @override
  Future<Result<void>> changeMasterPassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final sessionVaultKey = _sessionVaultKey();
    final userId = _session.current?.userId;
    if (sessionVaultKey == null || userId == null) {
      return const FailureResult(AuthenticationFailure());
    }
    if (!MasterPasswordPolicy.isValid(newPassword)) {
      return const FailureResult(ValidationFailure());
    }

    final loaded = await _loadCurrentUser();
    if (loaded is FailureResult<UserRecord>) {
      return FailureResult(loaded.failure);
    }
    final user = (loaded as Success<UserRecord>).data;

    final oldDerived = await _crypto.deriveKey(
      masterPassword: currentPassword,
      salt: user.kdfSalt,
      parameters: user.kdfParameters,
    );
    if (oldDerived is FailureResult<Uint8List>) {
      return const FailureResult(AuthenticationFailure());
    }
    final oldDerivedKey = (oldDerived as Success<Uint8List>).data;

    final unwrapped = await _keys.unwrapVaultKey(
      wrappedVaultKey: user.wrappedVaultKey,
      derivedKey: oldDerivedKey,
    );
    oldDerivedKey.fillRange(0, oldDerivedKey.length, 0);
    if (unwrapped is FailureResult<Uint8List>) {
      return const FailureResult(AuthenticationFailure());
    }
    final recoveredKey = (unwrapped as Success<Uint8List>).data;
    final matchesCurrent = _sameKey(recoveredKey, sessionVaultKey);
    recoveredKey.fillRange(0, recoveredKey.length, 0);
    if (!matchesCurrent) {
      return const FailureResult(AuthenticationFailure());
    }

    final newSalt = _keys.generateSalt();
    final newParameters = _keys.defaultKdfParameters();
    final newDerived = await _crypto.deriveKey(
      masterPassword: newPassword,
      salt: newSalt,
      parameters: newParameters,
    );
    if (newDerived is FailureResult<Uint8List>) {
      return const FailureResult(CryptoFailure());
    }
    final newDerivedKey = (newDerived as Success<Uint8List>).data;

    final wrapped = await _keys.wrapVaultKey(
      vaultKey: sessionVaultKey,
      derivedKey: newDerivedKey,
    );
    if (wrapped is FailureResult<WrappedVaultKey>) {
      newDerivedKey.fillRange(0, newDerivedKey.length, 0);
      return const FailureResult(CryptoFailure());
    }
    final newWrap = (wrapped as Success<WrappedVaultKey>).data;

    final verified = await _keys.unwrapVaultKey(
      wrappedVaultKey: newWrap,
      derivedKey: newDerivedKey,
    );
    newDerivedKey.fillRange(0, newDerivedKey.length, 0);
    if (verified is FailureResult<Uint8List>) {
      return const FailureResult(CryptoFailure());
    }
    final verifiedKey = (verified as Success<Uint8List>).data;
    final verifiedMatches = _sameKey(verifiedKey, sessionVaultKey);
    verifiedKey.fillRange(0, verifiedKey.length, 0);
    if (!verifiedMatches) {
      return const FailureResult(CryptoFailure());
    }

    return _users.update(
      user.copyWith(
        updatedAt: DateTime.now(),
        kdfSalt: newSalt,
        kdfParameters: newParameters,
        wrappedVaultKey: newWrap,
      ),
    );
  }

  @override
  Future<Result<SecuritySettings>> currentSecuritySettings() async {
    final loaded = await _loadCurrentUser();
    if (loaded is FailureResult<UserRecord>) {
      return FailureResult(loaded.failure);
    }
    return Success((loaded as Success<UserRecord>).data.securitySettings);
  }

  @override
  Future<Result<void>> setAutoLockTimeout(Duration timeout) async {
    if (timeout.isNegative) {
      return const FailureResult(ValidationFailure());
    }
    final loaded = await _loadCurrentUser();
    if (loaded is FailureResult<UserRecord>) {
      return FailureResult(loaded.failure);
    }
    final user = (loaded as Success<UserRecord>).data;
    return _users.update(
      user.copyWith(
        updatedAt: DateTime.now(),
        securitySettings: user.securitySettings.copyWith(
          autoLockTimeout: timeout,
        ),
      ),
    );
  }

  @override
  Future<Result<void>> setPreventScreenshots(bool enabled) async {
    final loaded = await _loadCurrentUser();
    if (loaded is FailureResult<UserRecord>) {
      return FailureResult(loaded.failure);
    }
    final user = (loaded as Success<UserRecord>).data;
    return _users.update(
      user.copyWith(
        updatedAt: DateTime.now(),
        securitySettings: user.securitySettings.copyWith(
          preventScreenshots: enabled,
        ),
      ),
    );
  }

  @override
  Future<Result<UserRecord>> currentUser() {
    return _loadCurrentUser();
  }

  @override
  Future<Result<void>> updateProfile({
    required String username,
  }) async {
    final trimmedName = username.trim();
    if (trimmedName.isEmpty) {
      return const FailureResult(ValidationFailure());
    }
    final loaded = await _loadCurrentUser();
    if (loaded is FailureResult<UserRecord>) {
      return FailureResult(loaded.failure);
    }
    final user = (loaded as Success<UserRecord>).data;
    final updated = await _users.update(
      user.copyWith(
        username: trimmedName,
        updatedAt: DateTime.now(),
      ),
    );
    if (updated is FailureResult<void>) {
      return updated;
    }
    _session.updateUsername(trimmedName);
    return const Success(null);
  }

  @override
  Future<Result<UserRecord>> openSession({
    required String userId,
    required Uint8List vaultKey,
  }) async {
    final loaded = await _users.findById(userId);
    if (loaded is FailureResult<UserRecord?>) {
      vaultKey.fillRange(0, vaultKey.length, 0);
      return _authenticationFailed();
    }
    final user = (loaded as Success<UserRecord?>).data;
    if (user == null) {
      vaultKey.fillRange(0, vaultKey.length, 0);
      return _authenticationFailed();
    }

    _session.setAuthenticated(
      userId: user.id,
      username: user.username,
      vaultKey: vaultKey,
    );
    await _rememberActiveUserId(user.id);
    return Success(user);
  }

  @override
  Future<Result<bool>> hasAnyAccount() async {
    final ids = await _users.listIds();
    if (ids is FailureResult<List<String>>) {
      return FailureResult(ids.failure);
    }
    return Success((ids as Success<List<String>>).data.isNotEmpty);
  }

  @override
  Future<Result<List<AccountSummary>>> getAccounts() async {
    final listed = await _users.list();
    if (listed is FailureResult<List<UserRecord>>) {
      return FailureResult(listed.failure);
    }
    final records = (listed as Success<List<UserRecord>>).data;
    return Success([
      for (final user in records)
        AccountSummary(id: user.id, username: user.username),
    ]);
  }

  @override
  Future<Result<AccountSummary>> getAccount(String userId) async {
    final loaded = await _users.findById(userId);
    if (loaded is FailureResult<UserRecord?>) {
      return FailureResult(loaded.failure);
    }
    final user = (loaded as Success<UserRecord?>).data;
    if (user == null) {
      return const FailureResult(AuthenticationFailure());
    }
    return Success(AccountSummary(id: user.id, username: user.username));
  }

  @override
  Future<Result<String>> resolveUnlockUserId() async {
    try {
      final stored = _database.appSettings.get(HiveSettingsKeys.activeUserId);
      if (stored is String && stored.isNotEmpty) {
        final exists = await _users.exists(stored);
        if (exists is FailureResult<bool>) {
          return const FailureResult(AuthenticationFailure());
        }
        if ((exists as Success<bool>).data) {
          return Success(stored);
        }
      }
    } catch (_) {
      return const FailureResult(AuthenticationFailure());
    }

    final ids = await _users.listIds();
    if (ids is FailureResult<List<String>>) {
      return const FailureResult(AuthenticationFailure());
    }
    final list = (ids as Success<List<String>>).data;
    if (list.length == 1) {
      return Success(list.first);
    }
    return const FailureResult(AuthenticationFailure());
  }

  @override
  Future<Result<void>> logout() async {
    _session.clear();
    return const Success<void>(null);
  }

  @override
  Future<Result<AccountDeletionOutcome>> deleteAccount({
    required String masterPassword,
  }) async {
    final sessionVaultKey = _sessionVaultKey();
    final userId = _session.current?.userId;
    if (sessionVaultKey == null || userId == null) {
      return const FailureResult(AuthenticationFailure());
    }
    if (masterPassword.isEmpty) {
      return const FailureResult(ValidationFailure());
    }

    final loaded = await _loadCurrentUser();
    if (loaded is FailureResult<UserRecord>) {
      return FailureResult(loaded.failure);
    }
    final user = (loaded as Success<UserRecord>).data;

    final verified = await _verifyMasterPassword(
      user: user,
      masterPassword: masterPassword,
      sessionVaultKey: sessionVaultKey,
    );
    if (verified is FailureResult<void>) {
      return FailureResult(verified.failure);
    }

    final remaining = await _remainingAccountCount(excludingUserId: userId);
    if (remaining is FailureResult<int>) {
      return FailureResult(remaining.failure);
    }

    await _purgeDeviceCredentials(userId);
    await _blobs?.deleteAllForUser(userId);
    _blobs?.clearCache();

    final vaultDeleted = await _vaults.delete(userId);
    if (vaultDeleted is FailureResult<void>) {
      return FailureResult(vaultDeleted.failure);
    }

    final userDeleted = await _users.delete(userId);
    if (userDeleted is FailureResult<void>) {
      return FailureResult(userDeleted.failure);
    }

    final verifiedWipe = await _verifyAccountDeleted(userId);
    if (verifiedWipe is FailureResult<void>) {
      return FailureResult(verifiedWipe.failure);
    }

    await _clearActiveUserIdIfMatch(userId);
    _session.clear();
    return Success(
      AccountDeletionOutcome(
        hasRemainingAccounts: (remaining as Success<int>).data > 0,
      ),
    );
  }

  Future<void> _rememberActiveUserId(String userId) async {
    try {
      await _database.appSettings.put(HiveSettingsKeys.activeUserId, userId);
    } catch (_) {}
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

  Future<Result<UserRecord>> _loadCurrentUser() async {
    final userId = _session.current?.userId;
    if (!_session.isAuthenticated || userId == null) {
      return const FailureResult(AuthenticationFailure());
    }
    final loaded = await _users.findById(userId);
    if (loaded is FailureResult<UserRecord?>) {
      return const FailureResult(AuthenticationFailure());
    }
    final user = (loaded as Success<UserRecord?>).data;
    if (user == null) {
      return const FailureResult(AuthenticationFailure());
    }
    return Success(user);
  }

  Future<Result<void>> _verifyMasterPassword({
    required UserRecord user,
    required String masterPassword,
    required Uint8List sessionVaultKey,
  }) async {
    final derived = await _crypto.deriveKey(
      masterPassword: masterPassword,
      salt: user.kdfSalt,
      parameters: user.kdfParameters,
    );
    if (derived is FailureResult<Uint8List>) {
      return const FailureResult(AuthenticationFailure());
    }
    final derivedKey = (derived as Success<Uint8List>).data;

    final unwrapped = await _keys.unwrapVaultKey(
      wrappedVaultKey: user.wrappedVaultKey,
      derivedKey: derivedKey,
    );
    derivedKey.fillRange(0, derivedKey.length, 0);
    if (unwrapped is FailureResult<Uint8List>) {
      return const FailureResult(AuthenticationFailure());
    }
    final recoveredKey = (unwrapped as Success<Uint8List>).data;
    final matches = _sameKey(recoveredKey, sessionVaultKey);
    recoveredKey.fillRange(0, recoveredKey.length, 0);
    if (!matches) {
      return const FailureResult(AuthenticationFailure());
    }
    return const Success<void>(null);
  }

  Future<Result<int>> _remainingAccountCount({
    required String excludingUserId,
  }) async {
    final ids = await _users.listIds();
    if (ids is FailureResult<List<String>>) {
      return FailureResult(ids.failure);
    }
    final remaining = (ids as Success<List<String>>).data
        .where((id) => id != excludingUserId)
        .length;
    return Success(remaining);
  }

  Future<void> _purgeDeviceCredentials(String userId) async {
    final storage = _secureStorage;
    if (storage != null) {
      try {
        await storage.delete(FastUnlockStorageKeys.pinMaterial(userId));
      } catch (_) {}
      try {
        await storage.delete(FastUnlockStorageKeys.biometricMaterial(userId));
      } catch (_) {}
    }
    final attempts = _attempts;
    if (attempts != null) {
      await attempts.reset(UnlockAttemptMethod.pin, userId);
      await attempts.reset(UnlockAttemptMethod.biometric, userId);
    }
  }

  Future<Result<void>> _verifyAccountDeleted(String userId) async {
    final exists = await _users.exists(userId);
    if (exists is FailureResult<bool>) {
      return const FailureResult(DatabaseFailure());
    }
    if ((exists as Success<bool>).data) {
      return const FailureResult(DatabaseFailure());
    }
    final vault = await _vaults.findByUserId(userId);
    if (vault is FailureResult<VaultRecord?>) {
      return const FailureResult(DatabaseFailure());
    }
    if ((vault as Success<VaultRecord?>).data != null) {
      return const FailureResult(DatabaseFailure());
    }
    return const Success<void>(null);
  }

  Future<void> _clearActiveUserIdIfMatch(String userId) async {
    try {
      final stored = _database.appSettings.get(HiveSettingsKeys.activeUserId);
      if (stored == userId) {
        await _database.appSettings.delete(HiveSettingsKeys.activeUserId);
      }
    } catch (_) {}
  }

  Uint8List? _sessionVaultKey() {
    if (!_session.isAuthenticated || _session.current == null) {
      return null;
    }
    return _session.vaultKey;
  }

  static bool _sameKey(Uint8List left, Uint8List right) {
    if (left.length != right.length) {
      return false;
    }
    var diff = 0;
    for (var i = 0; i < left.length; i++) {
      diff |= left[i] ^ right[i];
    }
    return diff == 0;
  }
}
