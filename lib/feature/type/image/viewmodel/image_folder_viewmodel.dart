import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keyva/core/exceptions/result.dart';
import 'package:keyva/core/routes/app_routing.dart';
import 'package:keyva/feature/home/viewmodel/home_viewmodel.dart';
import 'package:keyva/feature/type/image/model/image_add_photo_args.dart';
import 'package:keyva/feature/type/image/service/image_capture_service.dart';
import 'package:keyva/feature/type/image/service/image_gallery_export_service.dart';
import 'package:keyva/feature/type/image/util/image_gallery_export_ui.dart';
import 'package:keyva/feature/type/image/widget/image_permission_dialog.dart';
import 'package:keyva/feature/type/image/widget/image_source_sheet.dart';
import 'package:keyva/feature/vault/model/image_folder.dart';
import 'package:keyva/feature/vault/model/image_item.dart';
import 'package:keyva/feature/vault/view/vault_list_item_mapper.dart';
import 'package:keyva/feature/vault/view/vault_user_message.dart';
import 'package:keyva/feature/vault/viewmodel/vault_home_viewmodel.dart';
import 'package:keyva/shared/widget/toast_widget.dart';

class ImageFolderViewModel extends GetxController {
  ImageFolderViewModel({
    required this.folderId,
    required ImageCaptureService capture,
    required ImageGalleryExportService export,
  }) : _capture = capture,
       _export = export;

  final String folderId;
  final ImageCaptureService _capture;
  final ImageGalleryExportService _export;
  final isPicking = false.obs;
  final isExporting = false.obs;
  final exportProgressMessage = ''.obs;

  bool get isBusy => isPicking.value || isExporting.value;

  VaultHomeViewModel? get _vaultHome => Get.isRegistered<VaultHomeViewModel>()
      ? Get.find<VaultHomeViewModel>()
      : null;

  ImageFolder? get folder {
    final found = findVaultItemById(_vaultHome?.vault.value, folderId);
    return found is ImageFolder ? found : null;
  }

  List<ImageItem> get photos {
    final data = _vaultHome?.vault.value;
    if (data == null) return const [];
    final items = [
      for (final image in data.images)
        if (image.folderId == folderId) image,
    ];
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  String get headerTitle => folder?.title ?? 'پوشه تصاویر';

  String get overlayMessage {
    if (isExporting.value) {
      return exportProgressMessage.value;
    }
    return 'در حال آماده‌سازی تصویر...';
  }

  @override
  void onInit() {
    super.onInit();
    if (folder == null) {
      Get.back();
    }
  }

  void openPhoto(String photoId) {
    Get.toNamed(AppRoutes.imageDetails, arguments: photoId);
  }

  void navigateToEdit() {
    Get.toNamed(AppRoutes.imageFolderEdit, arguments: folderId);
  }

  Future<void> togglePin(BuildContext context) async {
    final current = folder;
    if (current == null || !Get.isRegistered<HomeController>()) return;
    final listItem = mapVaultListItem(
      current,
      vault: _vaultHome?.vault.value,
    );
    if (listItem == null) return;
    await Get.find<HomeController>().toggleItemPin(context, listItem);
  }

  void confirmDelete(BuildContext context) {
    final current = folder;
    if (current == null || !Get.isRegistered<HomeController>()) return;
    final listItem = mapVaultListItem(
      current,
      vault: _vaultHome?.vault.value,
    );
    if (listItem == null) return;
    Get.find<HomeController>().confirmDelete(
      context,
      listItem,
      onDeleted: Get.back,
    );
  }

  Future<void> saveAllToGallery(BuildContext context) async {
    if (isBusy) return;
    final items = photos;
    if (items.isEmpty) return;

    isExporting.value = true;
    exportProgressMessage.value = galleryExportProgressMessage(0, items.length);
    try {
      final result = await _export.exportFolder(
        images: items,
        onProgress: (current, total) {
          exportProgressMessage.value = galleryExportProgressMessage(
            current,
            total,
          );
        },
      );
      if (!context.mounted) return;
      if (result is FailureResult<ImageGalleryFolderExportResult>) {
        await presentGalleryExportFailure(context, result.failure);
        return;
      }
      presentFolderExportSummary(
        context,
        (result as Success<ImageGalleryFolderExportResult>).data,
      );
    } finally {
      isExporting.value = false;
    }
  }

  Future<void> addPhoto(BuildContext context) async {
    if (isBusy) return;
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
          isPicking.value = false;
          await Get.toNamed(
            AppRoutes.imageAddPhoto,
            arguments: ImageAddPhotoArgs(
              folderId: folderId,
              data: data,
            ),
          );
          await _vaultHome?.refreshVault();
      }
    } finally {
      isPicking.value = false;
    }
  }
}
