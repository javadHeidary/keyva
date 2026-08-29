import 'dart:typed_data';

enum ImageGalleryPermissionStatus { granted, denied, permanentlyDenied }

class ImageGalleryAccessDenied implements Exception {
  const ImageGalleryAccessDenied();
}

abstract interface class ImageGalleryGateway {
  Future<bool> hasAccess();

  Future<bool> requestAccess();

  Future<void> putImageBytes({
    required Uint8List bytes,
    required String name,
  });
}
