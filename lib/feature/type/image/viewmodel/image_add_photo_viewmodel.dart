import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keyva/core/exceptions/result.dart';
import 'package:keyva/feature/type/image/model/image_add_photo_args.dart';
import 'package:keyva/feature/type/image/service/image_capture_service.dart';
import 'package:keyva/feature/type/image/service/image_photo_service.dart';
import 'package:keyva/feature/type/image/widget/image_permission_dialog.dart';
import 'package:keyva/feature/type/image/widget/image_source_sheet.dart';
import 'package:keyva/feature/vault/view/vault_user_message.dart';
import 'package:keyva/feature/vault/viewmodel/vault_home_viewmodel.dart';
import 'package:keyva/shared/widget/toast_widget.dart';

class ImageAddPhotoViewModel extends GetxController {
  ImageAddPhotoViewModel({
    required this.args,
    required ImagePhotoService photos,
    required ImageCaptureService capture,
  }) : _photos = photos,
       _capture = capture,
       captured = args.data.obs;

  final ImageAddPhotoArgs args;
  final ImagePhotoService _photos;
  final ImageCaptureService _capture;

  final Rx<ImageCaptureData> captured;
  final noteController = TextEditingController();
  final isSubmitting = false.obs;
  final isPicking = false.obs;
  final submitError = Rxn<String>();

  String get folderId => args.folderId;

  @override
  void onInit() {
    super.onInit();
    if (folderId.isEmpty || captured.value.bytes.isEmpty) {
      Get.back();
    }
  }

  Future<void> retake(BuildContext context) async {
    if (isPicking.value || isSubmitting.value) return;
    final source = await showImageSourceSheet(context);
    if (source == null || !context.mounted) return;

    isPicking.value = true;
    try {
      final outcome = await _capture.pick(source);
      if (!context.mounted) return;
      switch (outcome) {
        case ImageCaptureCancelled():
          return;
        case ImageCaptureDenied(:final isCamera):
          await showImagePermissionDeniedDialog(
            context,
            isCamera: isCamera,
          );
        case ImageCaptureFailed(:final message):
          AppToast.error(
            context,
            title: 'افزودن تصویر',
            message: vaultUserMessage(message),
          );
        case ImageCaptureSuccess(:final data):
          captured.value = data;
      }
    } finally {
      isPicking.value = false;
    }
  }

  Future<void> submit() async {
    if (isSubmitting.value) return;
    isSubmitting.value = true;
    submitError.value = null;
    try {
      final data = captured.value;
      final note = noteController.text.trim();
      final result = await _photos.addPhoto(
        folderId: folderId,
        bytes: data.bytes,
        thumbnailBytes: data.thumbnailBytes,
        note: note.isEmpty ? null : note,
        mimeType: data.mimeType,
        width: data.width,
        height: data.height,
      );
      if (result is FailureResult<void>) {
        submitError.value = vaultUserMessage(result.failure.message);
        return;
      }
      if (Get.isRegistered<VaultHomeViewModel>()) {
        await Get.find<VaultHomeViewModel>().refreshVault();
      }
      Get.back(result: true);
    } finally {
      isSubmitting.value = false;
    }
  }

  @override
  void onClose() {
    noteController.dispose();
    super.onClose();
  }
}
