import 'dart:typed_data';

enum ImageCaptureSource { camera, gallery }

class ImageCaptureData {
  const ImageCaptureData({
    required this.bytes,
    required this.thumbnailBytes,
    required this.mimeType,
    required this.width,
    required this.height,
  });

  final Uint8List bytes;
  final Uint8List thumbnailBytes;
  final String mimeType;
  final int width;
  final int height;
}

sealed class ImageCaptureOutcome {
  const ImageCaptureOutcome();
}

final class ImageCaptureCancelled extends ImageCaptureOutcome {
  const ImageCaptureCancelled();
}

final class ImageCaptureDenied extends ImageCaptureOutcome {
  const ImageCaptureDenied({required this.isCamera});

  final bool isCamera;
}

final class ImageCaptureFailed extends ImageCaptureOutcome {
  const ImageCaptureFailed({this.message});

  final String? message;
}

final class ImageCaptureSuccess extends ImageCaptureOutcome {
  const ImageCaptureSuccess(this.data);

  final ImageCaptureData data;
}

abstract interface class ImageCaptureService {
  Future<ImageCaptureOutcome> pick(ImageCaptureSource source);
}
