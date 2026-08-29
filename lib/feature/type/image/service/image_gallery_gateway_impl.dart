import 'dart:typed_data';

import 'package:gal/gal.dart';
import 'package:keyva/feature/type/image/service/image_gallery_gateway.dart';

class ImageGalleryGatewayImpl implements ImageGalleryGateway {
  const ImageGalleryGatewayImpl();

  @override
  Future<bool> hasAccess() {
    return Gal.hasAccess();
  }

  @override
  Future<bool> requestAccess() {
    return Gal.requestAccess();
  }

  @override
  Future<void> putImageBytes({
    required Uint8List bytes,
    required String name,
  }) async {
    try {
      await Gal.putImageBytes(bytes, name: name);
    } on GalException catch (error) {
      if (error.type == GalExceptionType.accessDenied) {
        throw const ImageGalleryAccessDenied();
      }
      rethrow;
    }
  }
}
