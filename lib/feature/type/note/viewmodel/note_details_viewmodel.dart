import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:keyva/core/routes/app_routing.dart';
import 'package:keyva/feature/home/viewmodel/home_viewmodel.dart';
import 'package:keyva/feature/type/note/util/note_util.dart';
import 'package:keyva/feature/vault/model/secure_note_item.dart';
import 'package:keyva/feature/vault/share/share_confirm_dialog.dart';
import 'package:keyva/feature/vault/share/share_sheet_service.dart';
import 'package:keyva/feature/vault/share/share_vault_item.dart';
import 'package:keyva/feature/vault/share/vault_item_share_formatter.dart';
import 'package:keyva/feature/vault/view/vault_list_item_mapper.dart';
import 'package:keyva/feature/vault/viewmodel/vault_home_viewmodel.dart';
import 'package:keyva/shared/utils/jalali_date_formatter.dart';
import 'package:keyva/shared/widget/toast_widget.dart';
import 'package:url_launcher/url_launcher.dart';

class NoteDetailsViewModel extends GetxController {
  NoteDetailsViewModel({
    required this.noteId,
    required this.shareSheet,
    this.formatter = const VaultItemShareFormatter(),
    this.confirmShare,
  });

  final String noteId;
  final ShareSheetService shareSheet;
  final VaultItemShareFormatter formatter;
  final Future<bool> Function(BuildContext context)? confirmShare;

  VaultHomeViewModel? get _vaultHome => Get.isRegistered<VaultHomeViewModel>()
      ? Get.find<VaultHomeViewModel>()
      : null;

  SecureNoteItem? get item {
    final data = _vaultHome?.vault.value;
    final found = findVaultItemById(data, noteId);
    return found is SecureNoteItem ? found : null;
  }

  String get headerTitle => item?.title ?? 'جزئیات یادداشت';

  String get categoryLabel => vaultCategoryLabel(
    _vaultHome?.vault.value,
    item?.categoryId,
  );

  String get createdAtLabel {
    final note = item;
    if (note == null) return '';
    return formatJalaliDate(note.createdAt);
  }

  @override
  void onInit() {
    super.onInit();
    if (item == null) {
      Get.back();
    }
  }

  void copyValue(
    BuildContext context,
    String value,
    String title,
    String successMessage,
  ) {
    if (value.isEmpty) return;
    Clipboard.setData(ClipboardData(text: value));
    AppToast.success(context, title: title, message: successMessage);
  }

  Future<void> openNoteLink(
    BuildContext context,
    NoteLinkType type,
    String raw,
  ) async {
    final uriString = uriForNoteLink(type, raw);
    if (uriString == null) {
      AppToast.error(
        context,
        title: 'باز کردن لینک',
        message: 'لینک معتبر نیست',
      );
      return;
    }

    final uri = Uri.parse(uriString);
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!context.mounted) return;
    if (!launched) {
      AppToast.error(
        context,
        title: 'باز کردن لینک',
        message: 'باز کردن لینک انجام نشد',
      );
    }
  }

  void navigateToEdit() {
    Get.toNamed(AppRoutes.noteEdit, arguments: noteId);
  }

  void confirmDelete(BuildContext context) {
    final note = item;
    if (note == null || !Get.isRegistered<HomeController>()) return;
    final listItem = mapVaultListItem(note);
    if (listItem == null) return;
    Get.find<HomeController>().confirmDelete(
      context,
      listItem,
      onDeleted: Get.back,
    );
  }

  Future<void> togglePin(BuildContext context) async {
    final note = item;
    if (note == null || !Get.isRegistered<HomeController>()) return;
    final listItem = mapVaultListItem(note);
    if (listItem == null) return;
    await Get.find<HomeController>().toggleItemPin(context, listItem);
  }

  Future<void> shareItem(BuildContext context) async {
    final note = item;
    if (note == null) return;
    await shareVaultItem(
      context: context,
      shareSheet: shareSheet,
      text: formatter.formatSecureNote(note, categoryName: categoryLabel),
      subject: VaultItemShareFormatter.noteSubject,
      confirmShare: confirmShare ?? showShareConfirmDialog,
    );
  }
}
