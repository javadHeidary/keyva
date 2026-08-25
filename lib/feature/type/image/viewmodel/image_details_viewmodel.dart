import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keyva/feature/vault/model/image_item.dart';
import 'package:keyva/feature/vault/view/vault_list_item_mapper.dart';
import 'package:keyva/feature/vault/viewmodel/vault_home_viewmodel.dart';
import 'package:keyva/shared/utils/jalali_date_formatter.dart';
import 'package:keyva/shared/widget/app_dialog_widget.dart';

class ImageDetailsViewModel extends GetxController {
  ImageDetailsViewModel({required this.photoId});

  final String photoId;

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
