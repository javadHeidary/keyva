import 'dart:typed_data';

import 'package:keyva/core/constants/security_constants.dart';
import 'package:keyva/core/crypto/crypto_service.dart';
import 'package:keyva/core/crypto/encrypted_payload.dart';
import 'package:keyva/core/crypto/key_management_service.dart';
import 'package:keyva/core/database/models/kdf_parameters.dart';
import 'package:keyva/core/database/models/wrapped_vault_key.dart';
import 'package:keyva/core/exceptions/app_failure.dart';
import 'package:keyva/core/exceptions/result.dart';

class KeyManagementServiceImpl implements KeyManagementService {
  KeyManagementServiceImpl(this._crypto);

  final CryptoService _crypto;

  @override
  KdfParameters defaultKdfParameters() {
    return const KdfParameters(
      algorithm: SecurityConstants.kdfAlgorithm,
      memoryCost: SecurityConstants.kdfMemoryCost,
      timeCost: SecurityConstants.kdfTimeCost,
      parallelism: SecurityConstants.kdfParallelism,
      outputLength: SecurityConstants.kdfOutputLength,
    );
  }

  @override
  Uint8List generateSalt() {
    return _crypto.generateSecureBytes(SecurityConstants.saltLength);
  }

  @override
  Uint8List generateVaultKey() {
    return _crypto.generateSecureBytes(SecurityConstants.vaultKeyLength);
  }

  @override
  Future<Result<WrappedVaultKey>> wrapVaultKey({
    required Uint8List vaultKey,
    required Uint8List derivedKey,
  }) async {
    if (vaultKey.length != SecurityConstants.vaultKeyLength ||
        derivedKey.length != SecurityConstants.vaultKeyLength) {
      return const FailureResult(CryptoFailure());
    }

    final encrypted = await _crypto.encrypt(
      plaintext: vaultKey,
      key: derivedKey,
    );
    if (encrypted is FailureResult<EncryptedPayload>) {
      return FailureResult(_asCryptoFailure(encrypted.failure));
    }

    final payload = (encrypted as Success<EncryptedPayload>).data;
    return Success(
      WrappedVaultKey(
        version: SecurityConstants.wrappedKeyVersion,
        nonce: payload.nonce,
        ciphertext: payload.ciphertext,
        authenticationTag: payload.authenticationTag,
      ),
    );
  }

  @override
  Future<Result<Uint8List>> unwrapVaultKey({
    required WrappedVaultKey wrappedVaultKey,
    required Uint8List derivedKey,
  }) async {
    if (wrappedVaultKey.version != SecurityConstants.wrappedKeyVersion ||
        derivedKey.length != SecurityConstants.vaultKeyLength ||
        wrappedVaultKey.nonce.length != SecurityConstants.nonceLength ||
        wrappedVaultKey.authenticationTag.length !=
            SecurityConstants.authenticationTagLength) {
      return const FailureResult(CryptoFailure());
    }

    final decrypted = await _crypto.decrypt(
      payload: EncryptedPayload(
        version: SecurityConstants.vaultEncryptionVersion,
        nonce: wrappedVaultKey.nonce,
        ciphertext: wrappedVaultKey.ciphertext,
        authenticationTag: wrappedVaultKey.authenticationTag,
      ),
      key: derivedKey,
    );
    if (decrypted is FailureResult<Uint8List>) {
      return FailureResult(_asCryptoFailure(decrypted.failure));
    }

    final vaultKey = (decrypted as Success<Uint8List>).data;
    if (vaultKey.length != SecurityConstants.vaultKeyLength) {
      return const FailureResult(CryptoFailure());
    }
    return Success(vaultKey);
  }

  static AppFailure _asCryptoFailure(AppFailure failure) {
    if (failure is CryptoFailure) {
      return failure;
    }
    return const CryptoFailure();
  }
}
