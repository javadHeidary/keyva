import 'dart:typed_data';

import 'package:keyva/core/exceptions/app_failure.dart';
import 'package:keyva/core/exceptions/result.dart';
import 'package:keyva/feature/type/image/service/image_gallery_gateway.dart';
import 'package:keyva/feature/vault/blob/encrypted_blob_store.dart';
import 'package:keyva/feature/vault/model/image_item.dart';

class ImageGalleryFolderExportResult {
  const ImageGalleryFolderExportResult({
    required this.saved,
    required this.total,
  });

  final int saved;
  final int total;
}

class ImageGalleryExportService {
  ImageGalleryExportService({
    required EncryptedBlobStore blobs,
    required ImageGalleryGateway gallery,
    DateTime Function()? now,
  }) : _blobs = blobs,
       _gallery = gallery,
       _now = now ?? DateTime.now;

  final EncryptedBlobStore _blobs;
  final ImageGalleryGateway _gallery;
  final DateTime Function() _now;
  var _deniedOnce = false;
  var _busy = false;

  Future<Result<void>> export({
    required String blobId,
    required String mimeType,
  }) async {
    if (!_begin()) {
      return const FailureResult(GalleryExportBusyFailure());
    }
    try {
      return await _exportOne(
        blobId: blobId,
        mimeType: mimeType,
        name: _fileName(mimeType),
        ensurePermission: true,
      );
    } finally {
      _busy = false;
    }
  }

  Future<Result<ImageGalleryFolderExportResult>> exportFolder({
    required List<ImageItem> images,
    void Function(int current, int total)? onProgress,
  }) async {
    if (!_begin()) {
      return const FailureResult(GalleryExportBusyFailure());
    }
    try {
      if (images.isEmpty) {
        return const Success(
          ImageGalleryFolderExportResult(saved: 0, total: 0),
        );
      }

      final permission = await _ensureAccess();
      if (permission != ImageGalleryPermissionStatus.granted) {
        return FailureResult(
          GalleryPermissionDeniedFailure(
            permanentlyDenied:
                permission == ImageGalleryPermissionStatus.permanentlyDenied,
          ),
        );
      }

      final stamp = _now().toUtc().millisecondsSinceEpoch;
      var saved = 0;
      for (var i = 0; i < images.length; i++) {
        onProgress?.call(i + 1, images.length);
        final photo = images[i];
        final result = await _exportOne(
          blobId: photo.blobId,
          mimeType: photo.mimeType,
          name: _batchFileName(stamp, i, photo.mimeType),
          ensurePermission: false,
        );
        if (result is Success<void>) {
          saved++;
        } else if (result is FailureResult<void> &&
            result.failure is GalleryPermissionDeniedFailure) {
          return FailureResult(result.failure);
        }
      }
      return Success(
        ImageGalleryFolderExportResult(saved: saved, total: images.length),
      );
    } finally {
      _busy = false;
    }
  }

  bool _begin() {
    if (_busy) {
      return false;
    }
    _busy = true;
    return true;
  }

  Future<Result<void>> _exportOne({
    required String blobId,
    required String mimeType,
    required String name,
    required bool ensurePermission,
  }) async {
    if (blobId.isEmpty) {
      return const FailureResult(ValidationFailure());
    }

    final read = await _blobs.read(blobId);
    if (read is FailureResult<Uint8List>) {
      return FailureResult(read.failure);
    }
    final bytes = (read as Success<Uint8List>).data;
    if (bytes.isEmpty) {
      return const FailureResult(ValidationFailure());
    }

    if (ensurePermission) {
      final permission = await _ensureAccess();
      if (permission != ImageGalleryPermissionStatus.granted) {
        return FailureResult(
          GalleryPermissionDeniedFailure(
            permanentlyDenied:
                permission == ImageGalleryPermissionStatus.permanentlyDenied,
          ),
        );
      }
    }

    try {
      await _gallery.putImageBytes(bytes: bytes, name: name);
    } on ImageGalleryAccessDenied {
      _deniedOnce = true;
      return const FailureResult(
        GalleryPermissionDeniedFailure(permanentlyDenied: true),
      );
    } catch (_) {
      return const FailureResult(GallerySaveFailure());
    }
    return const Success(null);
  }

  Future<ImageGalleryPermissionStatus> _ensureAccess() async {
    if (await _gallery.hasAccess()) {
      _deniedOnce = false;
      return ImageGalleryPermissionStatus.granted;
    }
    if (await _gallery.requestAccess()) {
      _deniedOnce = false;
      return ImageGalleryPermissionStatus.granted;
    }
    final status = _deniedOnce
        ? ImageGalleryPermissionStatus.permanentlyDenied
        : ImageGalleryPermissionStatus.denied;
    _deniedOnce = true;
    return status;
  }

  String _fileName(String mimeType) {
    final stamp = _now().toUtc().millisecondsSinceEpoch;
    return 'keyva_${stamp}_${_kind(mimeType)}';
  }

  String _batchFileName(int stamp, int index, String mimeType) {
    return 'keyva_${stamp}_${index}_${_kind(mimeType)}';
  }

  String _kind(String mimeType) => mimeType == 'image/png' ? 'png' : 'jpg';
}
