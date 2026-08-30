import 'dart:typed_data';

import 'package:get/get.dart';
import 'package:keyva/core/di/injection_container.dart';
import 'package:keyva/feature/category/bindings/category_bindings.dart';
import 'package:keyva/feature/type/image/model/image_add_photo_args.dart';
import 'package:keyva/feature/type/image/service/image_capture_service.dart';
import 'package:keyva/feature/type/image/service/image_gallery_export_service.dart';
import 'package:keyva/feature/type/image/service/image_photo_service.dart';
import 'package:keyva/feature/type/image/viewmodel/image_add_photo_viewmodel.dart';
import 'package:keyva/feature/type/image/viewmodel/image_details_viewmodel.dart';
import 'package:keyva/feature/type/image/viewmodel/image_folder_create_viewmodel.dart';
import 'package:keyva/feature/type/image/viewmodel/image_folder_edit_viewmodel.dart';
import 'package:keyva/feature/type/image/viewmodel/image_folder_viewmodel.dart';
import 'package:keyva/feature/vault/view/vault_item_navigation.dart';
import 'package:keyva/feature/vault/viewmodel/vault_item_viewmodel.dart';

class ImageBindings extends Bindings {
  @override
  void dependencies() {
    _ensureStore();
  }

  static void _ensureStore() {
    CategoryBindings().dependencies();
  }

  static VaultItemViewModel _itemViewModel() {
    if (!Get.isRegistered<VaultItemViewModel>()) {
      Get.lazyPut(() => getIt<VaultItemViewModel>());
    }
    return Get.find<VaultItemViewModel>();
  }
}

class ImageFolderCreateBindings extends Bindings {
  @override
  void dependencies() {
    ImageBindings._ensureStore();
    final items = ImageBindings._itemViewModel();
    Get.lazyPut(() => ImageFolderCreateViewModel(items: items));
  }
}

class ImageFolderEditBindings extends Bindings {
  @override
  void dependencies() {
    ImageBindings._ensureStore();
    final items = ImageBindings._itemViewModel();
    Get.lazyPut(
      () => ImageFolderEditViewModel(
        folderId: vaultRouteItemId(),
        items: items,
      ),
    );
  }
}

class ImageFolderBindings extends Bindings {
  @override
  void dependencies() {
    ImageBindings._ensureStore();
    final folderId = vaultRouteItemId();
    final openedAfterCreate = vaultRouteOpenedAfterCreate();
    Get.lazyPut(
      () => ImageFolderViewModel(
        folderId: folderId,
        openedAfterCreate: openedAfterCreate,
        capture: getIt<ImageCaptureService>(),
        export: getIt<ImageGalleryExportService>(),
      ),
    );
  }
}

class ImageAddPhotoBindings extends Bindings {
  @override
  void dependencies() {
    ImageBindings._ensureStore();
    final args = Get.arguments;
    Get.lazyPut(
      () => ImageAddPhotoViewModel(
        args: args is ImageAddPhotoArgs ? args : _emptyArgs,
        photos: getIt<ImagePhotoService>(),
        capture: getIt<ImageCaptureService>(),
      ),
    );
  }
}

class ImageDetailsBindings extends Bindings {
  @override
  void dependencies() {
    ImageBindings._ensureStore();
    Get.lazyPut(
      () => ImageDetailsViewModel(
        photoId: vaultRouteItemId(),
        export: getIt<ImageGalleryExportService>(),
      ),
    );
  }
}

final _emptyArgs = ImageAddPhotoArgs(
  folderId: '',
  data: ImageCaptureData(
    bytes: Uint8List(0),
    thumbnailBytes: Uint8List(0),
    mimeType: '',
    width: 1,
    height: 1,
  ),
);
