import 'package:keyva/feature/type/image/service/image_capture_service.dart';

class ImageAddPhotoArgs {
  const ImageAddPhotoArgs({required this.folderId, required this.data});

  final String folderId;
  final ImageCaptureData data;
}
