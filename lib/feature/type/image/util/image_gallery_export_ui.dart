import 'package:flutter/material.dart';
import 'package:keyva/core/exceptions/app_failure.dart';
import 'package:keyva/core/theme/extensions/theme_extentions.dart';
import 'package:keyva/feature/type/image/service/image_gallery_export_service.dart';
import 'package:keyva/feature/type/image/widget/image_permission_dialog.dart';
import 'package:keyva/feature/vault/view/vault_user_message.dart';
import 'package:keyva/shared/widget/app_loading_widger.dart';
import 'package:keyva/shared/widget/toast_widget.dart';

String galleryExportProgressMessage(int current, int total) {
  return 'در حال ذخیره تصاویر... $current از $total';
}

String folderGalleryExportSummary(ImageGalleryFolderExportResult result) {
  if (result.saved <= 0) {
    return 'ذخیره تصاویر در گالری انجام نشد.';
  }
  if (result.saved >= result.total) {
    return '${result.total} تصویر با موفقیت در گالری ذخیره شد.';
  }
  return '${result.saved} تصویر از ${result.total} تصویر در گالری ذخیره شدند.';
}

Future<void> presentGalleryExportFailure(
  BuildContext context,
  AppFailure failure,
) async {
  if (failure is GalleryExportBusyFailure) {
    return;
  }
  if (failure is GalleryPermissionDeniedFailure && failure.permanentlyDenied) {
    await showImagePermissionDeniedDialog(
      context,
      isCamera: false,
      forSave: true,
    );
    return;
  }
  AppToast.error(
    context,
    title: 'گالری',
    message: vaultUserMessage(failure.message),
  );
}

void presentFolderExportSummary(
  BuildContext context,
  ImageGalleryFolderExportResult result,
) {
  final message = folderGalleryExportSummary(result);
  if (result.saved <= 0) {
    AppToast.error(context, title: 'گالری', message: message);
    return;
  }
  AppToast.success(context, title: 'گالری', message: message);
}

class GalleryExportProgressHandle {
  GalleryExportProgressHandle(this._notifier, this._dismiss);

  final ValueNotifier<String> _notifier;
  final VoidCallback _dismiss;
  var _closed = false;

  void update(String message) {
    if (_closed) {
      return;
    }
    _notifier.value = message;
  }

  void dismiss() {
    if (_closed) {
      return;
    }
    _closed = true;
    _dismiss();
    _notifier.dispose();
  }
}

GalleryExportProgressHandle showGalleryExportProgressDialog({
  required BuildContext context,
  required String message,
}) {
  final notifier = ValueNotifier(message);
  final navigator = Navigator.of(context, rootNavigator: true);
  final colors = context.colors;
  final route = DialogRoute<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: colors.overlay,
    builder: (dialogContext) {
      return PopScope(
        canPop: false,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: ValueListenableBuilder<String>(
            valueListenable: notifier,
            builder: (context, value, _) {
              return AppLoadingWidget.page(message: value);
            },
          ),
        ),
      );
    },
  );
  navigator.push(route);
  return GalleryExportProgressHandle(notifier, () {
    if (route.isActive) {
      navigator.removeRoute(route);
    }
  });
}
