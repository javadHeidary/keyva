import 'package:flutter_test/flutter_test.dart';
import 'package:keyva/core/crypto/crypto_error_mapper.dart';
import 'package:keyva/core/exceptions/app_failure.dart';

void main() {
  test('maps unexpected errors to CryptoFailure without leaking details', () {
    const secret = 'nonce-or-key-material';
    final mapped = CryptoErrorMapper.map(StateError(secret));

    expect(mapped, isA<CryptoFailure>());
    expect(mapped.message, 'Cryptographic operation failed');
    expect(mapped.message, isNot(contains(secret)));
  });

  test('passes AppFailure through unchanged', () {
    const failure = VaultDecryptionFailure();
    expect(CryptoErrorMapper.map(failure), same(failure));
  });
}
