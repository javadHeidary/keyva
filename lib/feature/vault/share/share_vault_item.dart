import 'package:flutter/material.dart';
import 'package:keyva/feature/vault/share/share_confirm_dialog.dart';
import 'package:keyva/feature/vault/share/share_sheet_service.dart';
import 'package:keyva/shared/widget/toast_widget.dart';

Future<void> shareVaultItem({
  required BuildContext context,
  required ShareSheetService shareSheet,
  required String text,
  required String subject,
  Future<bool> Function(BuildContext context) confirmShare =
      showShareConfirmDialog,
}) async {
  final confirmed = await confirmShare(context);
  if (!confirmed) return;
  if (!context.mounted) return;

  final result = await shareSheet.shareText(text: text, subject: subject);
  if (!context.mounted) return;
  if (result == ShareSheetResult.unavailable) {
    AppToast.error(
      context,
      title: 'اشتراک‌گذاری',
      message: 'اشتراک‌گذاری انجام نشد',
    );
  }
}
