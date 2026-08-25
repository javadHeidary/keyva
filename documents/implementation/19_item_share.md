# Task 19 — Secure Item Sharing

This note describes the **native Share Sheet flow for vault items that is actually wired in the codebase**.

It is a learning reference and an implementation record. The source of truth is the Dart code and tests, not the architecture proposals.

Related code:

- [`lib/feature/vault/share/vault_item_share_formatter.dart`](../../lib/feature/vault/share/vault_item_share_formatter.dart)
- [`lib/feature/vault/share/share_sheet_service.dart`](../../lib/feature/vault/share/share_sheet_service.dart)
- [`lib/feature/vault/share/share_sheet_service_impl.dart`](../../lib/feature/vault/share/share_sheet_service_impl.dart)
- [`lib/feature/vault/share/share_confirm_dialog.dart`](../../lib/feature/vault/share/share_confirm_dialog.dart)
- [`lib/feature/vault/share/share_vault_item.dart`](../../lib/feature/vault/share/share_vault_item.dart)
- [`lib/feature/vault/share/vault_item_share_ui.dart`](../../lib/feature/vault/share/vault_item_share_ui.dart)
- [`lib/feature/type/login/viewmodel/login_details_viewmodel.dart`](../../lib/feature/type/login/viewmodel/login_details_viewmodel.dart)
- [`lib/feature/type/bank_card/viewmodel/bank_card_details_viewmodel.dart`](../../lib/feature/type/bank_card/viewmodel/bank_card_details_viewmodel.dart)
- [`lib/feature/type/note/viewmodel/note_details_viewmodel.dart`](../../lib/feature/type/note/viewmodel/note_details_viewmodel.dart)
- [`test/feature/vault/share/vault_item_share_formatter_test.dart`](../../test/feature/vault/share/vault_item_share_formatter_test.dart)
- [`test/feature/vault/share/share_sheet_service_impl_test.dart`](../../test/feature/vault/share/share_sheet_service_impl_test.dart)
- [`test/feature/vault/share/vault_item_share_viewmodel_test.dart`](../../test/feature/vault/share/vault_item_share_viewmodel_test.dart)
- [`test/feature/vault/share/vault_item_share_view_test.dart`](../../test/feature/vault/share/vault_item_share_view_test.dart)

It does **not** change Vault encryption, `VaultSerializer`, `VaultRepository`, clipboard auto-clear, list more-menu actions, or add Telegram/WhatsApp-specific APIs. Settings “share the app” is Task 20.

---

## Purpose

From each item details screen, the user can share the complete user-facing fields of that vault item through the **operating system Share Sheet** (`share_plus`). Destinations are whatever the OS offers (Messages, email, Telegram, WhatsApp, and other installed targets).

Sharing is an explicit two-step action: a warning dialog, then the system sheet. Cancel stops the flow. The clipboard is never used as the sharing mechanism.

---

## Flow

```text
Details header Share icon
 ↓
Warning dialog (confirm / انصراف)
 ↓
VaultItemShareFormatter (plain text)
 ↓
ShareSheetService.shareText
 ↓
Native Share Sheet
```

`ShareSheetService` is a GetIt lazy singleton (`ShareSheetServiceImpl`). Details ViewModels receive it through bindings. They do not construct `share_plus` themselves.

Results:

- `shared` / `dismissed` — no toast
- `unavailable` or a platform throw — generic toast `اشتراک‌گذاری انجام نشد` with no payload
- dialog cancel / barrier dismiss — no sheet, no clipboard, no logs

---

## Templates

Application name in every header: **Keyva**.

| Type | Header | Always included | Omitted when empty |
|------|--------|-----------------|--------------------|
| Login | `Keyva — اطلاعات ورود` | عنوان, نام کاربری, رمز عبور, دسته‌بندی | وب‌سایت, یادداشت |
| Bank card | `Keyva — اطلاعات کارت` | عنوان, بانک, شماره کارت (grouped), تاریخ انقضا (`MM / YY`), نام دارنده, CVV2, دسته‌بندی | یادداشت |
| Secure note | `Keyva — یادداشت` | عنوان, دسته‌بندی, توضیحات (content on the next line) | — |

Never included: `id`, `categoryId`, `createdAt`, `updatedAt`, `isPinned`, password strength.

Category uses the same `vaultCategoryLabel` as details (`بدون دسته‌بندی` when missing). Bank title prefers `displayBankTitle` from the details ViewModel.

Email targets get `subject` equal to the header line.

---

## Security

- Sensitive values appear only in the Share Sheet text after confirmation.
- Nothing is written to logs, exceptions, or crash reports: no passwords, card numbers, PIN, Master Password, Vault Key, or note body.
- `ShareSheetServiceImpl` swallows platform errors and returns `unavailable` without attaching the payload.
- Copy-to-clipboard remains a separate per-field action. Share does not call `Clipboard.setData`.

---

## UI

The Share icon (`AppIcon.share`, key `vault-item-share`) is a trailing header action on login, bank card, and secure note details, next to the existing pin toggle.

Confirm dialog copy:

- Title / confirm: `اشتراک‌گذاری`
- Body: warns that the item includes sensitive data and will be sent to the chosen app
- Cancel: `انصراف`

---

## Tests

Formatter tests lock the template, Keyva header, optional-field omission, grouped card number, CVV, and exclusion of ids/timestamps.

A fake `ShareSheetService` covers confirm → native share invocation, cancel → no share, dismissed → no error toast, and no clipboard writes.

Widget tests cover the header icon on all three details screens and the confirm/cancel dialog.
