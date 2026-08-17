import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:cryptography/helpers.dart';
import 'package:keyva/core/constants/security_constants.dart';
import 'package:keyva/core/crypto/crypto_error_mapper.dart';
import 'package:keyva/core/crypto/crypto_service.dart';
import 'package:keyva/core/crypto/encrypted_payload.dart';
import 'package:keyva/core/database/models/kdf_parameters.dart';
import 'package:keyva/core/exceptions/app_failure.dart';
import 'package:keyva/core/exceptions/result.dart';

class CryptoServiceImpl implements CryptoService {
  CryptoServiceImpl({AesGcm? aesGcm}) : _aesGcm = aesGcm ?? AesGcm.with256bits();

  final AesGcm _aesGcm;

  @override
  Uint8List generateSecureBytes(int length) {
    return randomBytes(length);
  }

  @override
  Future<Result<Uint8List>> deriveKey({
    required String masterPassword,
    required Uint8List salt,
    required KdfParameters parameters,
  }) async {
    try {
      if (parameters.algorithm != SecurityConstants.kdfAlgorithm ||
          parameters.memoryCost <= 0 ||
          parameters.timeCost <= 0 ||
          parameters.parallelism <= 0 ||
          parameters.outputLength <= 0 ||
          salt.isEmpty) {
        return const FailureResult(CryptoFailure());
      }

      final algorithm = Argon2id(
        memory: parameters.memoryCost,
        iterations: parameters.timeCost,
        parallelism: parameters.parallelism,
        hashLength: parameters.outputLength,
      );
      final secretKey = await algorithm.deriveKeyFromPassword(
        password: masterPassword,
        nonce: salt,
      );
      final bytes = await secretKey.extractBytes();
      return Success(Uint8List.fromList(bytes));
    } catch (error) {
      return FailureResult(CryptoErrorMapper.map(error));
    }
  }

  @override
  Future<Result<EncryptedPayload>> encrypt({
    required Uint8List plaintext,
    required Uint8List key,
  }) async {
    try {
      if (key.length != SecurityConstants.vaultKeyLength) {
        return const FailureResult(CryptoFailure());
      }

      final nonce = Uint8List.fromList(_aesGcm.newNonce());
      if (nonce.length != SecurityConstants.nonceLength) {
        return const FailureResult(CryptoFailure());
      }

      final secretBox = await _aesGcm.encrypt(
        plaintext,
        secretKey: SecretKey(key),
        nonce: nonce,
      );
      final authenticationTag = Uint8List.fromList(secretBox.mac.bytes);
      if (authenticationTag.length != SecurityConstants.authenticationTagLength) {
        return const FailureResult(CryptoFailure());
      }

      return Success(
        EncryptedPayload(
          version: SecurityConstants.vaultEncryptionVersion,
          nonce: nonce,
          ciphertext: Uint8List.fromList(secretBox.cipherText),
          authenticationTag: authenticationTag,
        ),
      );
    } catch (error) {
      return FailureResult(CryptoErrorMapper.map(error));
    }
  }

  @override
  Future<Result<Uint8List>> decrypt({
    required EncryptedPayload payload,
    required Uint8List key,
  }) async {
    try {
      if (payload.version != SecurityConstants.vaultEncryptionVersion ||
          key.length != SecurityConstants.vaultKeyLength ||
          payload.nonce.length != SecurityConstants.nonceLength ||
          payload.authenticationTag.length !=
              SecurityConstants.authenticationTagLength) {
        return const FailureResult(CryptoFailure());
      }

      final clearText = await _aesGcm.decrypt(
        SecretBox(
          payload.ciphertext,
          nonce: payload.nonce,
          mac: Mac(payload.authenticationTag),
        ),
        secretKey: SecretKey(key),
      );
      return Success(Uint8List.fromList(clearText));
    } on SecretBoxAuthenticationError {
      return const FailureResult(VaultDecryptionFailure());
    } catch (error) {
      return FailureResult(CryptoErrorMapper.map(error));
    }
  }
}
