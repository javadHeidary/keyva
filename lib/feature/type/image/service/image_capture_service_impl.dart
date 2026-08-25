import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:keyva/core/exceptions/result.dart';
import 'package:keyva/feature/type/image/service/image_capture_service.dart';
import 'package:keyva/feature/type/image/service/image_prepare_service.dart';
import 'package:permission_handler/permission_handler.dart';

class ImageCaptureServiceImpl implements ImageCaptureService {
  ImageCaptureServiceImpl({
    ImagePicker? picker,
    ImagePrepareService? prepare,
    Future<PermissionStatus> Function()? cameraStatus,
    Future<PermissionStatus> Function()? requestCamera,
  }) : _picker = picker ?? ImagePicker(),
       _prepare = prepare ?? const ImagePrepareServiceImpl(),
       _cameraStatus = cameraStatus,
       _requestCamera = requestCamera;

  final ImagePicker _picker;
  final ImagePrepareService _prepare;
  final Future<PermissionStatus> Function()? _cameraStatus;
  final Future<PermissionStatus> Function()? _requestCamera;

  @override
  Future<ImageCaptureOutcome> pick(ImageCaptureSource source) async {
    if (source == ImageCaptureSource.camera) {
      final permission = await _ensureCameraPermission();
      if (permission != null) {
        return permission;
      }
    }

    late final XFile? file;
    try {
      file = await _picker.pickImage(
        source: source == ImageCaptureSource.camera
            ? ImageSource.camera
            : ImageSource.gallery,
        maxWidth: ImageSizeLimits.maxEdge.toDouble(),
        maxHeight: ImageSizeLimits.maxEdge.toDouble(),
        imageQuality: ImageSizeLimits.pickerQuality,
      );
    } catch (_) {
      if (source == ImageCaptureSource.camera) {
        final status = await _status();
        if (status.isDenied ||
            status.isPermanentlyDenied ||
            status.isRestricted) {
          return const ImageCaptureDenied(isCamera: true);
        }
      }
      return const ImageCaptureFailed();
    }

    if (file == null) {
      return const ImageCaptureCancelled();
    }

    late final Uint8List raw;
    try {
      raw = await file.readAsBytes();
    } catch (_) {
      return const ImageCaptureFailed();
    }

    final prepared = await _prepare.prepare(raw);
    if (prepared is FailureResult<ImagePrepareResult>) {
      return ImageCaptureFailed(message: prepared.failure.message);
    }
    final data = (prepared as Success<ImagePrepareResult>).data;
    return ImageCaptureSuccess(
      ImageCaptureData(
        bytes: data.bytes,
        thumbnailBytes: data.thumbnailBytes,
        mimeType: data.mimeType,
        width: data.width,
        height: data.height,
      ),
    );
  }

  Future<ImageCaptureOutcome?> _ensureCameraPermission() async {
    var status = await _status();
    if (status.isGranted || status.isLimited) {
      return null;
    }
    if (status.isPermanentlyDenied || status.isRestricted) {
      return const ImageCaptureDenied(isCamera: true);
    }
    status = await _request();
    if (status.isGranted || status.isLimited) {
      return null;
    }
    if (status.isDenied) {
      return const ImageCaptureCancelled();
    }
    return const ImageCaptureDenied(isCamera: true);
  }

  Future<PermissionStatus> _status() {
    if (_cameraStatus != null) {
      return _cameraStatus();
    }
    return Permission.camera.status;
  }

  Future<PermissionStatus> _request() {
    if (_requestCamera != null) {
      return _requestCamera();
    }
    return Permission.camera.request();
  }
}
