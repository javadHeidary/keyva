import 'dart:typed_data';

import 'package:keyva/core/constants/security_constants.dart';
import 'package:keyva/core/crypto/crypto_service.dart';
import 'package:keyva/core/crypto/encrypted_payload.dart';
import 'package:keyva/core/crypto/key_management_service.dart';
import 'package:keyva/core/exceptions/app_failure.dart';
import 'package:keyva/core/exceptions/result.dart';
import 'package:keyva/core/security/backup_password_policy.dart';
import 'package:keyva/feature/backup/model/backup_envelope.dart';
import 'package:keyva/feature/backup/model/backup_preview.dart';
import 'package:keyva/feature/backup/serialization/backup_envelope_codec.dart';
import 'package:keyva/feature/backup/service/backup_service.dart';
import 'package:keyva/feature/vault/model/vault_data.dart';
import 'package:keyva/feature/vault/serialization/vault_serializer.dart';
import 'package:keyva/feature/vault/service/vault_data_service.dart';
import 'package:keyva/feature/vault/service/vault_operation_service.dart';

class BackupServiceImpl implements BackupService {
  BackupServiceImpl({
    required VaultOperationService operations,
    required VaultDataService vaultData,
    required VaultSerializer serializer,
    required CryptoService crypto,
    required KeyManagementService keys,
  }) : _operations = operations,
       _vaultData = vaultData,
       _serializer = serializer,
       _crypto = crypto,
       _keys = keys;

  final VaultOperationService _operations;
  final VaultDataService _vaultData;
  final VaultSerializer _serializer;
  final CryptoService _crypto;
  final KeyManagementService _keys;

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

    final serialized = await _serializer.serialize(
      (current as Success<VaultData>).data,
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

    return BackupEnvelopeCodec.encode(
      BackupEnvelope(
        formatVersion: SecurityConstants.backupFormatVersion,
        kdfSalt: salt,
        kdfParameters: parameters,
        nonce: payload.nonce,
        ciphertext: payload.ciphertext,
        authenticationTag: payload.authenticationTag,
      ),
    );
  }

  @override
  Result<void> validateEnvelope(Uint8List bytes) {
    final decoded = BackupEnvelopeCodec.decode(bytes);
    if (decoded is FailureResult<BackupEnvelope>) {
      return FailureResult(decoded.failure);
    }
    return const Success<void>(null);
  }

  @override
  Future<Result<BackupRestorePlan>> decryptBackup({
    required Uint8List bytes,
    required String backupPassword,
  }) async {
    final decoded = BackupEnvelopeCodec.decode(bytes);
    if (decoded is FailureResult<BackupEnvelope>) {
      return FailureResult(decoded.failure);
    }
    final envelope = (decoded as Success<BackupEnvelope>).data;

    final derived = await _crypto.deriveKey(
      masterPassword: backupPassword,
      salt: envelope.kdfSalt,
      parameters: envelope.kdfParameters,
    );
    if (derived is FailureResult<Uint8List>) {
      return const FailureResult(BackupIntegrityFailure());
    }
    final backupKey = (derived as Success<Uint8List>).data;

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
      if (decrypted.failure is VaultDecryptionFailure) {
        return const FailureResult(WrongBackupPasswordFailure());
      }
      return const FailureResult(BackupIntegrityFailure());
    }

    final deserialized = await _serializer.deserialize(
      (decrypted as Success<Uint8List>).data,
    );
    if (deserialized is FailureResult<VaultData>) {
      return const FailureResult(BackupPayloadValidationFailure());
    }
    final vault = (deserialized as Success<VaultData>).data;
    return Success(
      BackupRestorePlan(
        vault: vault,
        preview: BackupPreview.fromVault(vault),
      ),
    );
  }

  @override
  Future<Result<void>> restoreVault(VaultData vault) async {
    final replaced = await _vaultData.replaceVault(vault);
    if (replaced is FailureResult<void>) {
      if (replaced.failure is AuthenticationFailure) {
        return replaced;
      }
      return const FailureResult(BackupRestorePersistenceFailure());
    }
    return replaced;
  }
}
