import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:keyva/core/constants/security_constants.dart';
import 'package:keyva/core/crypto/crypto_service_impl.dart';
import 'package:keyva/core/crypto/encrypted_payload.dart';
import 'package:keyva/core/database/models/kdf_parameters.dart';
import 'package:keyva/core/exceptions/app_failure.dart';
import 'package:keyva/core/exceptions/result.dart';

void main() {
  final crypto = CryptoServiceImpl();
  const kdfTimeout = Timeout(Duration(minutes: 2));

  KdfParameters productionKdf() {
    return const KdfParameters(
      algorithm: SecurityConstants.kdfAlgorithm,
      memoryCost: SecurityConstants.kdfMemoryCost,
      timeCost: SecurityConstants.kdfTimeCost,
      parallelism: SecurityConstants.kdfParallelism,
      outputLength: SecurityConstants.kdfOutputLength,
    );
  }

  Uint8List bytes(int length, int seed) {
    return Uint8List.fromList(
      List<int>.generate(length, (index) => (seed + index) & 0xFF),
    );
  }

  test(
    'deriveKey is deterministic for identical inputs',
    () async {
      final salt = bytes(SecurityConstants.saltLength, 1);
      const password = 'test-master-password';
      final parameters = productionKdf();

      final first = await crypto.deriveKey(
        masterPassword: password,
        salt: salt,
        parameters: parameters,
      );
      final second = await crypto.deriveKey(
        masterPassword: password,
        salt: salt,
        parameters: parameters,
      );

      final firstKey = _expectSuccess(first);
      final secondKey = _expectSuccess(second);
      expect(firstKey.length, SecurityConstants.kdfOutputLength);
      expect(firstKey, secondKey);
    },
    timeout: kdfTimeout,
  );

  test(
    'deriveKey produces a different key when the salt changes',
    () async {
      const password = 'test-master-password';
      final parameters = productionKdf();

      final first = await crypto.deriveKey(
        masterPassword: password,
        salt: bytes(SecurityConstants.saltLength, 1),
        parameters: parameters,
      );
      final second = await crypto.deriveKey(
        masterPassword: password,
        salt: bytes(SecurityConstants.saltLength, 2),
        parameters: parameters,
      );

      expect(_expectSuccess(first), isNot(_expectSuccess(second)));
    },
    timeout: kdfTimeout,
  );

  test('encrypt then decrypt round-trips plaintext', () async {
    final key = crypto.generateSecureBytes(SecurityConstants.vaultKeyLength);
    final plaintext = Uint8List.fromList('vault-bytes'.codeUnits);

    final encrypted = _expectSuccess(
      await crypto.encrypt(plaintext: plaintext, key: key),
    );
    expect(encrypted.version, SecurityConstants.vaultEncryptionVersion);
    expect(encrypted.nonce.length, SecurityConstants.nonceLength);
    expect(
      encrypted.authenticationTag.length,
      SecurityConstants.authenticationTagLength,
    );

    final decrypted = _expectSuccess(
      await crypto.decrypt(payload: encrypted, key: key),
    );
    expect(decrypted, plaintext);
  });

  test('tampered ciphertext fails authentication', () async {
    final key = crypto.generateSecureBytes(SecurityConstants.vaultKeyLength);
    final encrypted = _expectSuccess(
      await crypto.encrypt(
        plaintext: Uint8List.fromList('vault-bytes'.codeUnits),
        key: key,
      ),
    );
    final tamperedCiphertext = Uint8List.fromList(encrypted.ciphertext);
    tamperedCiphertext[0] = tamperedCiphertext[0] ^ 0xFF;

    final result = await crypto.decrypt(
      payload: EncryptedPayload(
        version: encrypted.version,
        nonce: encrypted.nonce,
        ciphertext: tamperedCiphertext,
        authenticationTag: encrypted.authenticationTag,
      ),
      key: key,
    );

    _expectFailure<VaultDecryptionFailure>(result);
  });

  test('tampered nonce fails authentication', () async {
    final key = crypto.generateSecureBytes(SecurityConstants.vaultKeyLength);
    final encrypted = _expectSuccess(
      await crypto.encrypt(
        plaintext: Uint8List.fromList('vault-bytes'.codeUnits),
        key: key,
      ),
    );
    final tamperedNonce = Uint8List.fromList(encrypted.nonce);
    tamperedNonce[0] = tamperedNonce[0] ^ 0xFF;

    final result = await crypto.decrypt(
      payload: EncryptedPayload(
        version: encrypted.version,
        nonce: tamperedNonce,
        ciphertext: encrypted.ciphertext,
        authenticationTag: encrypted.authenticationTag,
      ),
      key: key,
    );

    _expectFailure<VaultDecryptionFailure>(result);
  });
}

T _expectSuccess<T>(Result<T> result) {
  expect(result, isA<Success<T>>());
  return (result as Success<T>).data;
}

void _expectFailure<F extends AppFailure>(Result<dynamic> result) {
  expect(result, isA<FailureResult<dynamic>>());
  final failure = (result as FailureResult<dynamic>).failure;
  expect(failure, isA<F>());
  expect(failure.message, isNot(contains('SecretBox')));
  expect(failure.message, isNot(contains('GCM')));
  expect(failure.message, isNot(contains('Argon2')));
}
