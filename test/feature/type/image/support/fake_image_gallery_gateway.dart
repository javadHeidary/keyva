import 'dart:async';
import 'dart:typed_data';

import 'package:keyva/feature/type/image/service/image_gallery_gateway.dart';

class FakeImageGalleryGateway implements ImageGalleryGateway {
  bool accessGranted = true;
  bool grantOnRequest = true;
  Object? putError;
  Uint8List? lastBytes;
  String? lastName;
  int hasAccessCount = 0;
  int requestCount = 0;
  int putCount = 0;
  Completer<void>? putGate;
  int? failAtPutCount;
  final List<String> writtenPaths = [];
  final List<String> names = [];

  @override
  Future<bool> hasAccess() async {
    hasAccessCount++;
    return accessGranted;
  }

  @override
  Future<bool> requestAccess() async {
    requestCount++;
    if (grantOnRequest) {
      accessGranted = true;
    }
    return grantOnRequest;
  }

  @override
  Future<void> putImageBytes({
    required Uint8List bytes,
    required String name,
  }) async {
    putCount++;
    lastBytes = Uint8List.fromList(bytes);
    lastName = name;
    names.add(name);
    final gate = putGate;
    if (gate != null) {
      await gate.future;
    }
    final error = putError;
    if (error != null) {
      throw error;
    }
    if (failAtPutCount != null && putCount == failAtPutCount) {
      throw Exception('platform');
    }
  }
}
