import 'dart:convert';
import 'dart:typed_data';

import 'package:keyva/core/exceptions/app_failure.dart';
import 'package:keyva/core/exceptions/result.dart';
import 'package:keyva/feature/vault/model/vault_data.dart';
import 'package:keyva/feature/vault/serialization/vault_serializer.dart';

class BackupPayload {
  const BackupPayload({
    required this.vault,
    this.imageBlobs = const {},
  });

  final VaultData vault;
  final Map<String, Uint8List> imageBlobs;
}

abstract final class BackupPayloadCodec {
  static const vaultKey = 'vault';
  static const imageBlobsKey = 'imageBlobs';

  static Future<Result<Uint8List>> encode({
    required VaultSerializer serializer,
    required VaultData vault,
    required Map<String, Uint8List> imageBlobs,
  }) async {
    final serialized = await serializer.serialize(vault);
    if (serialized is FailureResult<Uint8List>) {
      return FailureResult(serialized.failure);
    }
    try {
      final vaultObject = jsonDecode(
        utf8.decode((serialized as Success<Uint8List>).data),
      );
      if (vaultObject is! Map) {
        return const FailureResult(ValidationFailure());
      }
      final encoded = utf8.encode(
        jsonEncode(<String, Object?>{
          vaultKey: vaultObject,
          imageBlobsKey: <String, String>{
            for (final entry in imageBlobs.entries)
              entry.key: base64Encode(entry.value),
          },
        }),
      );
      return Success(Uint8List.fromList(encoded));
    } catch (_) {
      return const FailureResult(ValidationFailure());
    }
  }

  static Future<Result<BackupPayload>> decode({
    required VaultSerializer serializer,
    required Uint8List plaintext,
  }) async {
    try {
      final decoded = jsonDecode(utf8.decode(plaintext));
      if (decoded is Map &&
          decoded.containsKey(vaultKey) &&
          decoded.containsKey(imageBlobsKey)) {
        final vaultObject = decoded[vaultKey];
        final blobsObject = decoded[imageBlobsKey];
        if (vaultObject is! Map || blobsObject is! Map) {
          return const FailureResult(BackupPayloadValidationFailure());
        }
        final vaultBytes = Uint8List.fromList(
          utf8.encode(jsonEncode(vaultObject)),
        );
        final vault = await serializer.deserialize(vaultBytes);
        if (vault is FailureResult<VaultData>) {
          return const FailureResult(BackupPayloadValidationFailure());
        }
        final blobs = <String, Uint8List>{};
        for (final entry in blobsObject.entries) {
          if (entry.key is! String || entry.value is! String) {
            return const FailureResult(BackupPayloadValidationFailure());
          }
          blobs[entry.key as String] = Uint8List.fromList(
            base64Decode(entry.value as String),
          );
        }
        return Success(
          BackupPayload(
            vault: (vault as Success<VaultData>).data,
            imageBlobs: blobs,
          ),
        );
      }
    } catch (_) {
      return const FailureResult(BackupPayloadValidationFailure());
    }

    final vault = await serializer.deserialize(plaintext);
    if (vault is FailureResult<VaultData>) {
      return const FailureResult(BackupPayloadValidationFailure());
    }
    return Success(
      BackupPayload(vault: (vault as Success<VaultData>).data),
    );
  }
}
