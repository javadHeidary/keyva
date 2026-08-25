import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:keyva/core/crypto/crypto_service_impl.dart';
import 'package:keyva/core/exceptions/app_failure.dart';
import 'package:keyva/core/exceptions/result.dart';
import 'package:keyva/core/session/session_service_impl.dart';
import 'package:keyva/feature/vault/blob/encrypted_blob_store_impl.dart';

void main() {
  late Directory tempDir;
  late SessionServiceImpl session;
  late EncryptedBlobStoreImpl store;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('keyva_blobs_');
    session = SessionServiceImpl();
    session.setAuthenticated(
      userId: 'user-1',
      username: 'owner',
      vaultKey: Uint8List.fromList(List<int>.generate(32, (index) => index + 3)),
    );
    store = EncryptedBlobStoreImpl(
      crypto: CryptoServiceImpl(),
      session: session,
      supportDirectory: () async => tempDir,
    );
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('writes and reads encrypted bytes', () async {
    final written = _expectSuccess(
      await store.write(Uint8List.fromList([9, 8, 7, 6])),
    );
    expect(written.length, 32);

    store.clearCache();
    final read = _expectSuccess(await store.read(written));
    expect(read, Uint8List.fromList([9, 8, 7, 6]));
  });

  test('replaceAll wipes previous files', () async {
    final first = _expectSuccess(await store.write(Uint8List.fromList([1])));
    _expectSuccess(
      await store.replaceAll({
        'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa': Uint8List.fromList([2, 2]),
      }),
    );

    expect(await store.read(first), isA<FailureResult<Uint8List>>());
    expect(
      _expectSuccess(
        await store.read('aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'),
      ),
      Uint8List.fromList([2, 2]),
    );
  });

  test('replaceAll failure leaves previous files', () async {
    final first = _expectSuccess(await store.write(Uint8List.fromList([1])));
    final result = await store.replaceAll({
      'not-a-valid-blob-id': Uint8List.fromList([2, 2]),
    });

    expect(result, isA<FailureResult<void>>());
    expect(
      (result as FailureResult<void>).failure,
      isA<ValidationFailure>(),
    );
    expect(_expectSuccess(await store.read(first)), Uint8List.fromList([1]));
  });

  test('fails closed without a vault key', () async {
    session.clear();
    final result = await store.write(Uint8List.fromList([1]));
    expect(result, isA<FailureResult<String>>());
    expect(
      (result as FailureResult<String>).failure,
      isA<AuthenticationFailure>(),
    );
  });
}

T _expectSuccess<T>(Result<T> result) {
  expect(result, isA<Success<T>>());
  return (result as Success<T>).data;
}
