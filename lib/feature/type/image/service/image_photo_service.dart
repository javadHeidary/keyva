import 'dart:typed_data';

import 'package:keyva/core/exceptions/app_failure.dart';
import 'package:keyva/core/exceptions/result.dart';
import 'package:keyva/feature/vault/blob/encrypted_blob_store.dart';
import 'package:keyva/feature/vault/model/image_item.dart';
import 'package:keyva/feature/vault/model/vault_data.dart';
import 'package:keyva/feature/vault/service/vault_operation_service.dart';

class ImagePhotoService {
  ImagePhotoService({
    required VaultOperationService operations,
    required EncryptedBlobStore blobs,
  }) : _operations = operations,
       _blobs = blobs;

  final VaultOperationService _operations;
  final EncryptedBlobStore _blobs;

  Future<Result<void>> addPhoto({
    required String folderId,
    required Uint8List bytes,
    required Uint8List thumbnailBytes,
    String? note,
    required String mimeType,
    required int width,
    required int height,
  }) async {
    if (folderId.isEmpty ||
        bytes.isEmpty ||
        thumbnailBytes.isEmpty ||
        mimeType.isEmpty ||
        width <= 0 ||
        height <= 0) {
      return const FailureResult(ValidationFailure());
    }

    final vaultResult = await _operations.getVault();
    if (vaultResult is FailureResult<VaultData>) {
      return FailureResult(vaultResult.failure);
    }
    final vault = (vaultResult as Success<VaultData>).data;
    if (!vault.imageFolders.any((folder) => folder.id == folderId)) {
      return const FailureResult(ValidationFailure());
    }

    final blob = await _blobs.write(bytes);
    if (blob is FailureResult<String>) {
      return FailureResult(blob.failure);
    }
    final blobId = (blob as Success<String>).data;

    final thumb = await _blobs.write(thumbnailBytes);
    if (thumb is FailureResult<String>) {
      await _blobs.delete(blobId);
      return FailureResult(thumb.failure);
    }
    final thumbnailBlobId = (thumb as Success<String>).data;

    final now = DateTime.now().toUtc();
    final item = ImageItem(
      id: now.millisecondsSinceEpoch.toString(),
      folderId: folderId,
      note: note,
      blobId: blobId,
      thumbnailBlobId: thumbnailBlobId,
      mimeType: mimeType,
      width: width,
      height: height,
      createdAt: now,
    );

    final added = await _operations.addItem(item);
    if (added is FailureResult<void>) {
      await _blobs.deleteMany([blobId, thumbnailBlobId]);
      return added;
    }
    return const Success(null);
  }
}
