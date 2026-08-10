import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:keyva/core/routes/app_routing.dart';
import 'package:keyva/feature/category/controller/category_catalog_controller.dart';
import 'package:keyva/feature/type/note/data/note_vault_store.dart';
import 'package:keyva/feature/type/note/model/note_item_model.dart';
import 'package:keyva/feature/type/note/util/note_util.dart';
import 'package:keyva/shared/widget/app_dialog_widget.dart';
import 'package:keyva/shared/widget/toast_widget.dart';
import 'package:url_launcher/url_launcher.dart';

class NoteDetailsViewModel extends GetxController {
  NoteDetailsViewModel({required this.noteId});

  final String noteId;

  NoteVaultStore get _store => Get.find<NoteVaultStore>();

  List<NoteItem> get storeItems => _store.items;

  NoteItem? get item {
    for (final entry in _store.items) {
      if (entry.id == noteId) return entry;
    }
    return null;
  }

  String get headerTitle => item?.title ?? 'جزئیات یادداشت';

  String get categoryLabel {
    final note = item;
    if (note == null) return 'بدون دسته‌بندی';
    if (!Get.isRegistered<CategoryCatalogController>()) {
      return 'بدون دسته‌بندی';
    }
    return Get.find<CategoryCatalogController>().labelForCategoryId(
      note.categoryId,
    );
  }

  String get createdAtLabel {
    final note = item;
    if (note == null) return '';
    return formatNoteCreatedAt(note.createdAt);
  }

  @override
  void onInit() {
    super.onInit();
    if (item == null) {
      Get.back();
    }
  }

  void copyValue(BuildContext context, String value, String successMessage) {
    if (value.isEmpty) return;
    Clipboard.setData(ClipboardData(text: value));
    AppToast.success(context, title: successMessage);
  }

  Future<void> openNoteLink(BuildContext context, NoteLinkType type, String raw) async {
    final uriString = uriForNoteLink(type, raw);
    if (uriString == null) {
      AppToast.error(context, title: 'لینک معتبر نیست');
      return;
    }

    final uri = Uri.parse(uriString);
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!context.mounted) return;
    if (!launched) {
      AppToast.error(context, title: 'باز کردن لینک انجام نشد');
    }
  }

  void navigateToEdit() {
    Get.toNamed(AppRoutes.noteEdit, arguments: noteId)?.then((result) {
      if (result == true) {
        update();
      }
    });
  }

  void confirmDelete(BuildContext context) {
    AppDialogWidget.show(
      context,
      type: AppDialogType.warning,
      title: 'انتقال به سطل زباله',
      description:
          'این یادداشت به سطل زباله منتقل می‌شود و می‌توانید بعداً آن را بازگردانی کنید.',
      buttonText: 'انتقال به سطل زباله',
      onConfirm: () {
        _store.moveToTrash(noteId);
        Get.back();
      },
    );
  }
}
