import 'dart:convert';
import 'dart:typed_data';

import 'package:keyva/core/database/models/kdf_parameters.dart';
import 'package:keyva/core/database/models/wrapped_vault_key.dart';

abstract final class WrappedKeyCodec {
  static Map<String, dynamic> wrappedVaultKeyToJson(WrappedVaultKey key) {
    return {
      'version': key.version,
      'nonce': base64Encode(key.nonce),
      'ciphertext': base64Encode(key.ciphertext),
      'authenticationTag': base64Encode(key.authenticationTag),
    };
  }

  static WrappedVaultKey? wrappedVaultKeyFromJson(Object? json) {
    if (json is! Map) {
      return null;
    }
    final version = json['version'];
    final nonce = _bytes(json['nonce']);
    final ciphertext = _bytes(json['ciphertext']);
    final tag = _bytes(json['authenticationTag']);
    if (version is! int || nonce == null || ciphertext == null || tag == null) {
      return null;
    }
    return WrappedVaultKey(
      version: version,
      nonce: nonce,
      ciphertext: ciphertext,
      authenticationTag: tag,
    );
  }

  static Map<String, dynamic> kdfToJson(KdfParameters parameters) {
    return {
      'algorithm': parameters.algorithm,
      'memoryCost': parameters.memoryCost,
      'timeCost': parameters.timeCost,
      'parallelism': parameters.parallelism,
      'outputLength': parameters.outputLength,
    };
  }

  static KdfParameters? kdfFromJson(Object? json) {
    if (json is! Map) {
      return null;
    }
    final algorithm = json['algorithm'];
    final memoryCost = json['memoryCost'];
    final timeCost = json['timeCost'];
    final parallelism = json['parallelism'];
    final outputLength = json['outputLength'];
    if (algorithm is! String ||
        memoryCost is! int ||
        timeCost is! int ||
        parallelism is! int ||
        outputLength is! int) {
      return null;
    }
    return KdfParameters(
      algorithm: algorithm,
      memoryCost: memoryCost,
      timeCost: timeCost,
      parallelism: parallelism,
      outputLength: outputLength,
    );
  }

  static Uint8List? _bytes(Object? value) {
    if (value is! String || value.isEmpty) {
      return null;
    }
    try {
      return Uint8List.fromList(base64Decode(value));
    } catch (_) {
      return null;
    }
  }
}
