import 'dart:convert';
import 'dart:typed_data';

import 'package:keyva/core/constants/security_constants.dart';
import 'package:keyva/core/database/models/kdf_parameters.dart';
import 'package:keyva/core/exceptions/app_failure.dart';
import 'package:keyva/core/exceptions/result.dart';
import 'package:keyva/feature/backup/model/backup_envelope.dart';

abstract final class BackupEnvelopeCodec {
  static const _envelopeKeys = {
    'formatVersion',
    'kdfSalt',
    'kdfParameters',
    'nonce',
    'ciphertext',
    'authenticationTag',
  };

  static const _kdfKeys = {
    'algorithm',
    'memoryCost',
    'timeCost',
    'parallelism',
    'outputLength',
  };

  static Result<Uint8List> encode(BackupEnvelope envelope) {
    try {
      final encoded = utf8.encode(
        jsonEncode(<String, Object?>{
          'formatVersion': envelope.formatVersion,
          'kdfSalt': base64Encode(envelope.kdfSalt),
          'kdfParameters': <String, Object?>{
            'algorithm': envelope.kdfParameters.algorithm,
            'memoryCost': envelope.kdfParameters.memoryCost,
            'timeCost': envelope.kdfParameters.timeCost,
            'parallelism': envelope.kdfParameters.parallelism,
            'outputLength': envelope.kdfParameters.outputLength,
          },
          'nonce': base64Encode(envelope.nonce),
          'ciphertext': base64Encode(envelope.ciphertext),
          'authenticationTag': base64Encode(envelope.authenticationTag),
        }),
      );
      return Success(Uint8List.fromList(encoded));
    } catch (_) {
      return const FailureResult(InvalidBackupFormatFailure());
    }
  }

  static Result<BackupEnvelope> decode(Uint8List bytes) {
    try {
      if (bytes.isEmpty) {
        return const FailureResult(InvalidBackupFormatFailure());
      }

      final decoded = jsonDecode(utf8.decode(bytes));
      final object = _requireObject(decoded);
      _requireExactKeys(object, _envelopeKeys);

      final formatVersion = _requireInt(object['formatVersion']);
      if (formatVersion != SecurityConstants.backupFormatVersion) {
        return const FailureResult(UnsupportedBackupVersionFailure());
      }

      final kdfObject = _requireObject(object['kdfParameters']);
      _requireExactKeys(kdfObject, _kdfKeys);
      final kdfParameters = KdfParameters(
        algorithm: _requireString(kdfObject['algorithm']),
        memoryCost: _requireInt(kdfObject['memoryCost']),
        timeCost: _requireInt(kdfObject['timeCost']),
        parallelism: _requireInt(kdfObject['parallelism']),
        outputLength: _requireInt(kdfObject['outputLength']),
      );
      _validateKdfParameters(kdfParameters);

      final salt = _requireBase64(object['kdfSalt']);
      final nonce = _requireBase64(object['nonce']);
      final ciphertext = _requireBase64(object['ciphertext']);
      final authenticationTag = _requireBase64(object['authenticationTag']);

      if (salt.length != SecurityConstants.saltLength ||
          nonce.length != SecurityConstants.nonceLength ||
          authenticationTag.length !=
              SecurityConstants.authenticationTagLength ||
          ciphertext.isEmpty) {
        return const FailureResult(InvalidBackupFormatFailure());
      }

      return Success(
        BackupEnvelope(
          formatVersion: formatVersion,
          kdfSalt: salt,
          kdfParameters: kdfParameters,
          nonce: nonce,
          ciphertext: ciphertext,
          authenticationTag: authenticationTag,
        ),
      );
    } catch (_) {
      return const FailureResult(InvalidBackupFormatFailure());
    }
  }

  static void _validateKdfParameters(KdfParameters parameters) {
    if (parameters.algorithm != SecurityConstants.kdfAlgorithm ||
        parameters.memoryCost <= 0 ||
        parameters.timeCost <= 0 ||
        parameters.parallelism <= 0 ||
        parameters.outputLength != SecurityConstants.kdfOutputLength) {
      throw const _BackupEnvelopeException();
    }
  }

  static Map<String, Object?> _requireObject(Object? value) {
    if (value is! Map) {
      throw const _BackupEnvelopeException();
    }
    final object = <String, Object?>{};
    for (final entry in value.entries) {
      if (entry.key is! String) {
        throw const _BackupEnvelopeException();
      }
      object[entry.key as String] = entry.value;
    }
    return object;
  }

  static void _requireExactKeys(Map<String, Object?> object, Set<String> expected) {
    if (object.length != expected.length) {
      throw const _BackupEnvelopeException();
    }
    for (final key in object.keys) {
      if (!expected.contains(key)) {
        throw const _BackupEnvelopeException();
      }
    }
    for (final key in expected) {
      if (!object.containsKey(key)) {
        throw const _BackupEnvelopeException();
      }
    }
  }

  static int _requireInt(Object? value) {
    if (value is int) {
      return value;
    }
    throw const _BackupEnvelopeException();
  }

  static String _requireString(Object? value) {
    if (value is String && value.isNotEmpty) {
      return value;
    }
    throw const _BackupEnvelopeException();
  }

  static Uint8List _requireBase64(Object? value) {
    if (value is! String || value.isEmpty) {
      throw const _BackupEnvelopeException();
    }
    try {
      return Uint8List.fromList(base64Decode(value));
    } catch (_) {
      throw const _BackupEnvelopeException();
    }
  }
}

final class _BackupEnvelopeException implements Exception {
  const _BackupEnvelopeException();
}
