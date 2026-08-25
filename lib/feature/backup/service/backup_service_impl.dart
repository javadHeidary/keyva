import 'dart:developer' as developer;
import 'dart:typed_data';

import 'package:keyva/core/constants/security_constants.dart';
import 'package:keyva/core/crypto/crypto_service.dart';
import 'package:keyva/core/crypto/encrypted_payload.dart';
import 'package:keyva/core/crypto/key_management_service.dart';
import 'package:keyva/core/database/models/user_record.dart';
import 'package:keyva/core/database/user_data_source.dart';
import 'package:keyva/core/database/vault_data_source.dart';
import 'package:keyva/core/exceptions/app_failure.dart';
import 'package:keyva/core/exceptions/result.dart';
import 'package:keyva/core/security/backup_password_policy.dart';
import 'package:keyva/core/security/master_password_policy.dart';
import 'package:keyva/feature/auth/repository/auth_repository.dart';
import 'package:keyva/feature/backup/model/backup_envelope.dart';
import 'package:keyva/feature/backup/model/backup_preview.dart';
import 'package:keyva/feature/backup/model/restore_progress.dart';
import 'package:keyva/feature/backup/serialization/backup_envelope_codec.dart';
import 'package:keyva/feature/backup/serialization/backup_payload_codec.dart';
import 'package:keyva/feature/backup/service/backup_service.dart';
import 'package:keyva/feature/vault/blob/encrypted_blob_store.dart';
import 'package:keyva/feature/vault/model/vault_data.dart';
import 'package:keyva/feature/vault/serialization/vault_serializer.dart';
import 'package:keyva/feature/vault/service/vault_data_service.dart';
import 'package:keyva/feature/vault/service/vault_operation_service.dart';
import 'package:keyva/feature/vault/service/vault_unlock_service.dart';

class BackupServiceImpl implements BackupService {
  BackupServiceImpl({
    required VaultOperationService operations,
    required VaultDataService vaultData,
    required VaultSerializer serializer,
    required CryptoService crypto,
    required KeyManagementService keys,
    AuthRepository? auth,
    VaultUnlockService? unlock,
    UserDataSource? users,
    VaultDataSource? vaults,
    EncryptedBlobStore? blobs,
  }) : _operations = operations,
       _vaultData = vaultData,
       _serializer = serializer,
       _crypto = crypto,
       _keys = keys,
       _auth = auth,
       _unlock = unlock,
       _users = users,
       _vaults = vaults,
       _blobs = blobs;

  final VaultOperationService _operations;
  final VaultDataService _vaultData;
  final VaultSerializer _serializer;
  final CryptoService _crypto;
  final KeyManagementService _keys;
  final AuthRepository? _auth;
  final VaultUnlockService? _unlock;
  final UserDataSource? _users;
  final VaultDataSource? _vaults;
  final EncryptedBlobStore? _blobs;

  @override
  Future<Result<Uint8List>> createBackup({
    required String backupPassword,
  }) async {
    if (!BackupPasswordPolicy.isValid(backupPassword)) {
      return const FailureResult(ValidationFailure());
    }

    final current = await _operations.getVault();
    if (current is FailureResult<VaultData>) {
      return FailureResult(current.failure);
    }

    final vault = (current as Success<VaultData>).data;
    final imageBlobs = await _readImageBlobs(vault);
    if (imageBlobs is FailureResult<Map<String, Uint8List>>) {
      return FailureResult(imageBlobs.failure);
    }

    final serialized = await BackupPayloadCodec.encode(
      serializer: _serializer,
      vault: vault,
      imageBlobs: (imageBlobs as Success<Map<String, Uint8List>>).data,
    );
    if (serialized is FailureResult<Uint8List>) {
      return FailureResult(serialized.failure);
    }

    final salt = _keys.generateSalt();
    final parameters = _keys.defaultKdfParameters();
    final derived = await _crypto.deriveKey(
      masterPassword: backupPassword,
      salt: salt,
      parameters: parameters,
    );
    if (derived is FailureResult<Uint8List>) {
      return const FailureResult(CryptoFailure());
    }
    final backupKey = (derived as Success<Uint8List>).data;

    final encrypted = await _crypto.encrypt(
      plaintext: (serialized as Success<Uint8List>).data,
      key: backupKey,
    );
    backupKey.fillRange(0, backupKey.length, 0);
    if (encrypted is FailureResult<EncryptedPayload>) {
      return const FailureResult(CryptoFailure());
    }
    final payload = (encrypted as Success<EncryptedPayload>).data;

    final encoded = BackupEnvelopeCodec.encode(
      BackupEnvelope(
        formatVersion: SecurityConstants.backupFormatVersion,
        kdfSalt: salt,
        kdfParameters: parameters,
        nonce: payload.nonce,
        ciphertext: payload.ciphertext,
        authenticationTag: payload.authenticationTag,
      ),
    );
    if (encoded is Success<Uint8List>) {
      _log('backup created');
    }
    return encoded;
  }

  @override
  Result<void> validateEnvelope(Uint8List bytes) {
    final decoded = BackupEnvelopeCodec.decode(bytes);
    if (decoded is FailureResult<BackupEnvelope>) {
      return FailureResult(decoded.failure);
    }
    _log('backup file parsed version=${SecurityConstants.backupFormatVersion}');
    return const Success<void>(null);
  }

  @override
  Future<Result<BackupRestorePlan>> decryptBackup({
    required Uint8List bytes,
    required String backupPassword,
    RestoreProgressCallback? onProgress,
  }) async {
    _emit(onProgress, RestoreProgress.decryptStarting());
    _emit(onProgress, RestoreProgress.decryptValidating());
    final decoded = BackupEnvelopeCodec.decode(bytes);
    if (decoded is FailureResult<BackupEnvelope>) {
      return FailureResult(decoded.failure);
    }
    final envelope = (decoded as Success<BackupEnvelope>).data;
    _log('decrypt started version=${envelope.formatVersion}');

    _emit(onProgress, RestoreProgress.decryptDerivingKey());
    final derived = await _crypto.deriveKey(
      masterPassword: backupPassword,
      salt: envelope.kdfSalt,
      parameters: envelope.kdfParameters,
    );
    if (derived is FailureResult<Uint8List>) {
      _log('decrypt failed');
      return const FailureResult(BackupIntegrityFailure());
    }
    final backupKey = (derived as Success<Uint8List>).data;

    _emit(onProgress, RestoreProgress.decryptDecrypting());
    final decrypted = await _crypto.decrypt(
      payload: EncryptedPayload(
        version: SecurityConstants.vaultEncryptionVersion,
        nonce: envelope.nonce,
        ciphertext: envelope.ciphertext,
        authenticationTag: envelope.authenticationTag,
      ),
      key: backupKey,
    );
    backupKey.fillRange(0, backupKey.length, 0);
    if (decrypted is FailureResult<Uint8List>) {
      _log('decrypt failed');
      if (decrypted.failure is VaultDecryptionFailure) {
        return const FailureResult(WrongBackupPasswordFailure());
      }
      return const FailureResult(BackupIntegrityFailure());
    }

    _emit(onProgress, RestoreProgress.decryptDeserializing());
    final deserialized = await BackupPayloadCodec.decode(
      serializer: _serializer,
      plaintext: (decrypted as Success<Uint8List>).data,
    );
    if (deserialized is FailureResult<BackupPayload>) {
      _log('restore validation failed');
      return const FailureResult(BackupPayloadValidationFailure());
    }
    final payload = (deserialized as Success<BackupPayload>).data;
    _emit(onProgress, RestoreProgress.decryptCompleted());
    return Success(
      BackupRestorePlan(
        vault: payload.vault,
        preview: BackupPreview.fromVault(payload.vault),
        imageBlobs: payload.imageBlobs,
      ),
    );
  }

  @override
  Future<Result<void>> restoreVault(
    VaultData vault, {
    Map<String, Uint8List> imageBlobs = const {},
    RestoreProgressCallback? onProgress,
  }) async {
    _emit(onProgress, RestoreProgress.replacePersisting());
    final blobsInstalled = await _installImageBlobs(vault, imageBlobs);
    if (blobsInstalled is FailureResult<void>) {
      return const FailureResult(BackupRestorePersistenceFailure());
    }
    final replaced = await _vaultData.replaceVault(vault);
    if (replaced is FailureResult<void>) {
      await _blobs?.rollbackReplace();
      if (replaced.failure is AuthenticationFailure) {
        return replaced;
      }
      return const FailureResult(BackupRestorePersistenceFailure());
    }
    await _blobs?.finalizeReplace();
    _log('restore committed');
    return replaced;
  }

  @override
  Future<Result<void>> restoreIntoNewAccount({
    required String username,
    required String masterPassword,
    required VaultData vault,
    Map<String, Uint8List> imageBlobs = const {},
    RestoreProgressCallback? onProgress,
  }) async {
    final auth = _auth;
    final unlock = _unlock;
    if (auth == null || unlock == null) {
      return const FailureResult(BackupRestorePersistenceFailure());
    }

    final trimmedName = username.trim();
    if (trimmedName.length < 3 || !MasterPasswordPolicy.isValid(masterPassword)) {
      return const FailureResult(ValidationFailure());
    }

    _emit(onProgress, RestoreProgress.newAccountPreparing());
    final serialized = await _serializer.serialize(vault);
    if (serialized is FailureResult<Uint8List>) {
      _log('restore validation failed');
      return const FailureResult(BackupPayloadValidationFailure());
    }

    _emit(onProgress, RestoreProgress.newAccountCreating());
    final created = await auth.createAccount(
      username: trimmedName,
      masterPassword: masterPassword,
    );
    if (created is FailureResult<UserRecord>) {
      return const FailureResult(BackupRestorePersistenceFailure());
    }
    final user = (created as Success<UserRecord>).data;

    _emit(onProgress, RestoreProgress.newAccountUnlocking());
    final unlocked = await unlock.unlock(
      userId: user.id,
      masterPassword: masterPassword,
    );
    if (unlocked is FailureResult<void>) {
      await _rollbackNewAccount(user.id);
      return const FailureResult(BackupRestorePersistenceFailure());
    }

    _emit(onProgress, RestoreProgress.newAccountPersisting());
    final blobsInstalled = await _installImageBlobs(vault, imageBlobs);
    if (blobsInstalled is FailureResult<void>) {
      await _rollbackNewAccount(user.id);
      return const FailureResult(BackupRestorePersistenceFailure());
    }
    final replaced = await _vaultData.replaceVault(vault);
    if (replaced is FailureResult<void>) {
      await _rollbackNewAccount(user.id);
      return const FailureResult(BackupRestorePersistenceFailure());
    }
    await _blobs?.finalizeReplace();

    _emit(onProgress, RestoreProgress.commitCompleted());
    _log('restore committed');
    return const Success<void>(null);
  }

  Future<Result<Map<String, Uint8List>>> _readImageBlobs(VaultData vault) async {
    final ids = vault.imageBlobIds;
    if (ids.isEmpty) {
      return const Success(<String, Uint8List>{});
    }
    final blobs = _blobs;
    if (blobs == null) {
      return const FailureResult(BackupExportFailure());
    }
    final collected = <String, Uint8List>{};
    for (final id in ids) {
      final read = await blobs.read(id);
      if (read is FailureResult<Uint8List>) {
        return const FailureResult(BackupExportFailure());
      }
      collected[id] = (read as Success<Uint8List>).data;
    }
    return Success(collected);
  }

  Future<Result<void>> _installImageBlobs(
    VaultData vault,
    Map<String, Uint8List> imageBlobs,
  ) async {
    final expected = vault.imageBlobIds;
    final blobs = _blobs;
    if (expected.isEmpty && imageBlobs.isEmpty) {
      if (blobs == null) {
        return const Success(null);
      }
      return blobs.installReplace(const {});
    }
    for (final id in expected) {
      if (!imageBlobs.containsKey(id) || imageBlobs[id]!.isEmpty) {
        return const FailureResult(BackupRestorePersistenceFailure());
      }
    }
    if (blobs == null) {
      return const FailureResult(BackupRestorePersistenceFailure());
    }
    return blobs.installReplace({
      for (final id in expected) id: imageBlobs[id]!,
    });
  }

  static void _emit(
    RestoreProgressCallback? onProgress,
    RestoreProgress progress,
  ) {
    onProgress?.call(progress);
  }

  Future<void> _rollbackNewAccount(String userId) async {
    try {
      await _blobs?.rollbackReplace();
    } catch (_) {}
    try {
      await _blobs?.deleteAllForUser(userId);
    } catch (_) {}
    try {
      await _unlock?.lock();
    } catch (_) {}
    try {
      await _vaults?.delete(userId);
    } catch (_) {}
    try {
      await _users?.delete(userId);
    } catch (_) {}
  }

  static void _log(String message) {
    developer.log(message, name: 'KeyvaBackup');
  }
}
