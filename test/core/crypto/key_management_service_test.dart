import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:keyva/core/constants/security_constants.dart';
import 'package:keyva/core/crypto/crypto_service_impl.dart';
import 'package:keyva/core/crypto/key_management_service_impl.dart';
import 'package:keyva/core/database/models/wrapped_vault_key.dart';
import 'package:keyva/core/exceptions/app_failure.dart';
import 'package:keyva/core/exceptions/result.dart';

void main() {
  final keys = KeyManagementServiceImpl(CryptoServiceImpl());

  test('generateVaultKey returns a 32-byte unique key', () {
    final first = keys.generateVaultKey();
    final second = keys.generateVaultKey();

    expect(first.length, SecurityConstants.vaultKeyLength);
    expect(second.length, SecurityConstants.vaultKeyLength);
    expect(first, isNot(second));
    expect(first, isNot(Uint8List(SecurityConstants.vaultKeyLength)));
  });

  test('wrap then unwrap round-trips the Vault Key', () async {
    final vaultKey = keys.generateVaultKey();
    final derivedKey = keys.generateVaultKey();

    final wrapped = _expectSuccess(
      await keys.wrapVaultKey(vaultKey: vaultKey, derivedKey: derivedKey),
    );
    expect(wrapped.version, SecurityConstants.wrappedKeyVersion);
    expect(wrapped.nonce.length, SecurityConstants.nonceLength);
    expect(
      wrapped.authenticationTag.length,
      SecurityConstants.authenticationTagLength,
    );

    final unwrapped = _expectSuccess(
      await keys.unwrapVaultKey(
        wrappedVaultKey: wrapped,
        derivedKey: derivedKey,
      ),
    );
    expect(unwrapped, vaultKey);
  });

  test('tampered wrapped key fails', () async {
    final vaultKey = keys.generateVaultKey();
    final derivedKey = keys.generateVaultKey();
    final wrapped = _expectSuccess(
      await keys.wrapVaultKey(vaultKey: vaultKey, derivedKey: derivedKey),
    );
    final tamperedCiphertext = Uint8List.fromList(wrapped.ciphertext);
    tamperedCiphertext[0] = tamperedCiphertext[0] ^ 0xFF;

    final result = await keys.unwrapVaultKey(
      wrappedVaultKey: WrappedVaultKey(
        version: wrapped.version,
        nonce: wrapped.nonce,
        ciphertext: tamperedCiphertext,
        authenticationTag: wrapped.authenticationTag,
      ),
      derivedKey: derivedKey,
    );

    _expectCryptoFailure(result);
  });

  test('wrong wrapping key fails', () async {
    final vaultKey = keys.generateVaultKey();
    final derivedKey = keys.generateVaultKey();
    final otherKey = keys.generateVaultKey();
    final wrapped = _expectSuccess(
      await keys.wrapVaultKey(vaultKey: vaultKey, derivedKey: derivedKey),
    );

    final result = await keys.unwrapVaultKey(
      wrappedVaultKey: wrapped,
      derivedKey: otherKey,
    );

    _expectCryptoFailure(result);
  });
}

T _expectSuccess<T>(Result<T> result) {
  expect(result, isA<Success<T>>());
  return (result as Success<T>).data;
}

void _expectCryptoFailure(Result<dynamic> result) {
  expect(result, isA<FailureResult<dynamic>>());
  final failure = (result as FailureResult<dynamic>).failure;
  expect(failure, isA<CryptoFailure>());
  expect(failure.message, 'Cryptographic operation failed');
}
