import 'package:flutter/material.dart';
import 'package:keyva/feature/home/model/vault_models.dart';
import 'package:keyva/feature/vault/model/bank_card_item.dart';
import 'package:keyva/feature/vault/model/login_item.dart';
import 'package:keyva/feature/vault/model/secure_note_item.dart';
import 'package:keyva/shared/widget/app_more_widget.dart';

List<AppMoreAction> vaultMoreActionsForItem(
  VaultListItem item, {
  Object? source,
  VoidCallback? onDelete,
}) {
  final actions = <AppMoreAction>[];

  switch (source) {
    case LoginItem login:
      actions.add(
        AppMoreAction(
          label: 'کپی نام کاربری',
          value: login.username,
          toastMessage: 'نام کاربری کپی شد',
        ),
      );
      actions.add(
        AppMoreAction(
          label: 'کپی رمز عبور',
          value: login.password,
          toastMessage: 'رمز عبور کپی شد',
        ),
      );
    case BankCardItem card:
      actions.add(
        AppMoreAction(
          label: 'کپی شماره کارت',
          value: card.cardNumber,
          toastMessage: 'شماره کارت کپی شد',
        ),
      );
      actions.add(
        AppMoreAction(
          label: 'کپی CVV2',
          value: card.cvv,
          toastMessage: 'CVV2 کپی شد',
        ),
      );
      actions.add(
        AppMoreAction(
          label: 'کپی تاریخ انقضا',
          value: card.expiryDate,
          toastMessage: 'تاریخ انقضا کپی شد',
        ),
      );
    case SecureNoteItem note:
      actions.add(
        AppMoreAction(
          label: 'کپی محتوای یادداشت',
          value: note.content,
          toastMessage: 'متن یادداشت کپی شد',
        ),
      );
    default:
      break;
  }

  if (onDelete != null) {
    actions.add(
      AppMoreAction(
        label: 'حذف',
        onPressed: onDelete,
        isDestructive: true,
      ),
    );
  }

  return actions;
}
