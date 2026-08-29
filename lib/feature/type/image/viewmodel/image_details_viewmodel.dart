import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keyva/core/exceptions/result.dart';
import 'package:keyva/feature/type/image/service/image_gallery_export_service.dart';
import 'package:keyva/feature/type/image/util/image_gallery_export_ui.dart';
import 'package:keyva/feature/vault/model/image_item.dart';
import 'package:keyva/feature/vault/view/vault_list_item_mapper.dart';
import 'package:keyva/feature/vault/viewmodel/vault_home_viewmodel.dart';
import 'package:keyva/shared/utils/jalali_date_formatter.dart';
import 'package:keyva/shared/widget/app_dialog_widget.dart';
import 'package:keyva/shared/widget/toast_widget.dart';

class ImageDetailsViewModel extends GetxController {
  ImageDetailsViewModel({
    required this.photoId,
    required ImageGalleryExportService export,
  }) : _export = export;

  final String photoId;
  final ImageGalleryExportService _export;

  final canExport = false.obs;
  final isExporting = false.obs;

  VaultHomeViewModel? get _vaultHome => Get.isRegistered<VaultHomeViewModel>()
      ? Get.find<VaultHomeViewModel>()
      : null;

  ImageItem? get item {
    final found = findVaultItemById(_vaultHome?.vault.value, photoId);
    return found is ImageItem ? found : null;
  }

  String get headerTitle => 'جزئیات تصویر';

  String get createdAtLabel {
    final photo = item;
    if (photo == null) return '';
    return formatJalaliDate(photo.createdAt);
  }

  String? get note {
    final value = item?.note?.trim();
    if (value == null || value.isEmpty) return null;
    return value;
  }

  @override
  void onInit() {
    super.onInit();
    if (item == null) {
      Get.back();
    }
  }

  void onImageDecoded(bool success) {
    canExport.value = success;
  }

  Future<void> saveToGallery(BuildContext context) async {
    final photo = item;
    if (photo == null || isExporting.value || !canExport.value) {
      return;
    }

    isExporting.value = true;
    try {
      final result = await _export.export(
        blobId: photo.blobId,
        mimeType: photo.mimeType,
      );
      if (!context.mounted) return;
      if (result is FailureResult<void>) {
        await presentGalleryExportFailure(context, result.failure);
        return;
      }
      AppToast.success(
        context,
        title: 'گالری',
        message: 'تصویر با موفقیت در گالری ذخیره شد.',
      );
    } finally {
      isExporting.value = false;
    }
  }

  void confirmDelete(BuildContext context) {
    final photo = item;
    final vault = _vaultHome;
    if (photo == null || vault == null) return;
    AppDialogWidget.show(
      context,
      type: AppDialogType.warning,
      title: 'حذف تصویر',
      description: 'این تصویر برای همیشه حذف می‌شود. این کار قابل بازگشت نیست.',
      buttonText: 'حذف',
      cancelText: 'انصراف',
      onConfirm: () {
        vault.deleteItem(photo.id);
        Get.back();
      },
    );
  }
}
