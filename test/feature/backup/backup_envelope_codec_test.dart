import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:keyva/core/constants/security_constants.dart';
import 'package:keyva/core/crypto/crypto_service_impl.dart';
import 'package:keyva/core/crypto/key_management_service_impl.dart';
import 'package:keyva/core/exceptions/app_failure.dart';
import 'package:keyva/core/exceptions/result.dart';
import 'package:keyva/feature/backup/model/backup_envelope.dart';
import 'package:keyva/feature/backup/serialization/backup_envelope_codec.dart';

import '../../core/security/support/fast_key_management_service.dart';

void main() {
  late FastKeyManagementService keys;

  setUp(() {
    keys = FastKeyManagementService(KeyManagementServiceImpl(CryptoServiceImpl()));
  });

  BackupEnvelope sampleEnvelope({int formatVersion = 1}) {
    return BackupEnvelope(
      formatVersion: formatVersion,
      kdfSalt: keys.generateSalt(),
      kdfParameters: keys.defaultKdfParameters(),
      nonce: Uint8List(SecurityConstants.nonceLength),
      ciphertext: Uint8List.fromList([1, 2, 3, 4]),
      authenticationTag: Uint8List(SecurityConstants.authenticationTagLength),
    );
  }

  Map<String, Object?> decodeJson(Uint8List bytes) {
    return Map<String, Object?>.from(jsonDecode(utf8.decode(bytes)) as Map);
  }

  test('round-trips a supported envelope', () {
    final encoded = BackupEnvelopeCodec.encode(
      sampleEnvelope(formatVersion: SecurityConstants.backupFormatVersion),
    );
    expect(encoded, isA<Success<Uint8List>>());
    final decoded = BackupEnvelopeCodec.decode((encoded as Success<Uint8List>).data);
    expect(decoded, isA<Success<BackupEnvelope>>());
    final envelope = (decoded as Success<BackupEnvelope>).data;
    expect(envelope.formatVersion, SecurityConstants.backupFormatVersion);
  });

  test('accepts a version 1 envelope', () {
    final encoded = BackupEnvelopeCodec.encode(sampleEnvelope());
    expect(encoded, isA<Success<Uint8List>>());
    final decoded = BackupEnvelopeCodec.decode((encoded as Success<Uint8List>).data);
    expect(decoded, isA<Success<BackupEnvelope>>());
    expect((decoded as Success<BackupEnvelope>).data.formatVersion, 1);
  });

  test('rejects extra envelope keys', () {
    final encoded = (BackupEnvelopeCodec.encode(sampleEnvelope()) as Success<Uint8List>).data;
    final object = decodeJson(encoded);
    object['extra'] = true;
    final bytes = Uint8List.fromList(utf8.encode(jsonEncode(object)));
    final result = BackupEnvelopeCodec.decode(bytes);
    expect(result, isA<FailureResult<BackupEnvelope>>());
    expect(
      (result as FailureResult<BackupEnvelope>).failure,
      isA<InvalidBackupFormatFailure>(),
    );
  });

  test('rejects unsupported format versions', () {
    final encoded = (BackupEnvelopeCodec.encode(sampleEnvelope()) as Success<Uint8List>).data;
    final object = decodeJson(encoded);
    object['formatVersion'] = 99;
    final bytes = Uint8List.fromList(utf8.encode(jsonEncode(object)));
    final result = BackupEnvelopeCodec.decode(bytes);
    expect(result, isA<FailureResult<BackupEnvelope>>());
    expect(
      (result as FailureResult<BackupEnvelope>).failure,
      isA<UnsupportedBackupVersionFailure>(),
    );
  });

  test('rejects invalid kdf parameters', () {
    final encoded = (BackupEnvelopeCodec.encode(sampleEnvelope()) as Success<Uint8List>).data;
    final object = decodeJson(encoded);
    final kdf = Map<String, Object?>.from(object['kdfParameters']! as Map);
    kdf['algorithm'] = 'PBKDF2';
    object['kdfParameters'] = kdf;
    final bytes = Uint8List.fromList(utf8.encode(jsonEncode(object)));
    final result = BackupEnvelopeCodec.decode(bytes);
    expect(result, isA<FailureResult<BackupEnvelope>>());
    expect(
      (result as FailureResult<BackupEnvelope>).failure,
      isA<InvalidBackupFormatFailure>(),
    );
  });

  test('rejects truncated json', () {
    final result = BackupEnvelopeCodec.decode(Uint8List.fromList(utf8.encode('{"formatVersion"')));
    expect(result, isA<FailureResult<BackupEnvelope>>());
    expect(
      (result as FailureResult<BackupEnvelope>).failure,
      isA<InvalidBackupFormatFailure>(),
    );
  });
}
