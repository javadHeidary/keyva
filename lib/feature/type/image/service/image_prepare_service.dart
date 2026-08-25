import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:keyva/core/exceptions/app_failure.dart';
import 'package:keyva/core/exceptions/result.dart';

abstract final class ImageSizeLimits {
  static const maxBytes = 8 * 1024 * 1024;
  static const maxEdge = 1920;
  static const thumbnailEdge = 256;
  static const pickerQuality = 85;
}

class ImagePrepareResult {
  const ImagePrepareResult({
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

abstract interface class ImagePrepareService {
  Future<Result<ImagePrepareResult>> prepare(Uint8List bytes);
}

class ImagePrepareServiceImpl implements ImagePrepareService {
  const ImagePrepareServiceImpl();

  @override
  Future<Result<ImagePrepareResult>> prepare(Uint8List bytes) async {
    if (bytes.isEmpty) {
      return const FailureResult(ValidationFailure());
    }
    if (bytes.length > ImageSizeLimits.maxBytes) {
      return const FailureResult(
        ValidationFailure(message: 'حجم تصویر بیشتر از حد مجاز است.'),
      );
    }

    try {
      final full = await _decode(bytes);
      if (full == null) {
        return const FailureResult(
          ValidationFailure(message: 'خواندن تصویر ممکن نشد.'),
        );
      }
      final thumbnail = await _decode(
        bytes,
        maxEdge: ImageSizeLimits.thumbnailEdge,
      );
      if (thumbnail == null) {
        return const FailureResult(
          ValidationFailure(message: 'خواندن تصویر ممکن نشد.'),
        );
      }

      final fullBytes = bytes.length <= ImageSizeLimits.maxBytes
          ? bytes
          : full.pngBytes;
      if (fullBytes.length > ImageSizeLimits.maxBytes) {
        return const FailureResult(
          ValidationFailure(message: 'حجم تصویر بیشتر از حد مجاز است.'),
        );
      }

      return Success(
        ImagePrepareResult(
          bytes: Uint8List.fromList(fullBytes),
          thumbnailBytes: thumbnail.pngBytes,
          mimeType: _looksLikeJpeg(fullBytes) ? 'image/jpeg' : 'image/png',
          width: full.width,
          height: full.height,
        ),
      );
    } catch (_) {
      return const FailureResult(
        ValidationFailure(message: 'خواندن تصویر ممکن نشد.'),
      );
    }
  }

  static Future<_DecodedPng?> _decode(
    Uint8List bytes, {
    int? maxEdge,
  }) async {
    final codec = maxEdge == null
        ? await ui.instantiateImageCodec(bytes)
        : await ui.instantiateImageCodec(bytes, targetWidth: maxEdge);
    final frame = await codec.getNextFrame();
    final image = frame.image;
    final width = image.width;
    final height = image.height;
    final encoded = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    codec.dispose();
    if (encoded == null) {
      return null;
    }
    return _DecodedPng(
      pngBytes: encoded.buffer.asUint8List(),
      width: width,
      height: height,
    );
  }

  static bool _looksLikeJpeg(Uint8List bytes) {
    return bytes.length >= 3 &&
        bytes[0] == 0xFF &&
        bytes[1] == 0xD8 &&
        bytes[2] == 0xFF;
  }
}

class _DecodedPng {
  const _DecodedPng({
    required this.pngBytes,
    required this.width,
    required this.height,
  });

  final Uint8List pngBytes;
  final int width;
  final int height;
}
