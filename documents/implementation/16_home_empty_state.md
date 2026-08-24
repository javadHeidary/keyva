# Task 16 — Home Empty Vault State

This document describes the implemented Home empty-vault UX. It does not change Vault encryption, `VaultData`, Hive `VaultRecord`, or persistence.

## Why a full-screen empty Home was incorrect

A newly created account loads an empty `VaultData` (`logins`, `bankCards`, `secureNotes`, and `categories` are all empty). `VaultHomeViewModel` still reports `VaultUiStatus.empty`.

Home previously swapped the **entire body** for `AppEmptyWidget.vault` with `AppEmptyLayout.page`. That hid:

- Account identity header
- Search chip
- Item type rows (Login / Bank Card / Secure Note)
- Category chips

The first-run screen no longer looked like Home. The empty state belongs to the **items/content** section only.

## Home structure

```
Home (Scaffold + FAB)
 ├── initial / loading → Home chrome (no page spinner)
 ├── error (no snapshot) → VaultErrorView + retry
 └── _VaultContent (empty, loaded, submitting, success, snapshot retry, or first load)
      ├── Account header + search chip + lock (open-lock icon while VaultSession is unlocked)
      ├── Type summaries (always, including 0 counts)
      ├── Category chips
      └── Items section
           ├── First load without snapshot → no empty flash
           ├── List
           ├── Empty vault → AppEmptyWidget.vault (card, message only)
           └── Filter with zero rows → type/filter empty (no Add button)
```

`VaultUiStatus.empty` is not an error. Home treats it like a successful load with no items.

## Empty content

When `HomeController.visibleItems` is empty after a successful load:

- If the vault has no login / card / note items: `AppEmptyWidget.vault` in the items card
  - Title: هنوز چیزی اضافه نکرده‌اید
  - Description: اولین اطلاعات خود را به کیوا اضافه کنید.
  - No Add button (the Home FAB is the only create entry)
- If the vault has items but the current type/category filter matches none: `AppEmptyWidget.typeList` or `AppEmptyWidget.filteredResults` (no Add button, no search-no-results copy on Home)

The widget uses `AppEmptyLayout.card` inside `_SectionCard`. There is no page layout, illustration, or `Spacer`-based full screen.

## First login

New account → unlock → Home:

- Header, search chip, type selector, category chips, and FAB remain
- Items section shows the vault empty state
- Search chip stays visible; opening search with an empty vault keeps idle copy (`برای جستجو تایپ کنید`) even after typing, so the user does not see a misleading “no results” miss

## Create flow

The expandable FAB is the only create entry. Child buttons call `onAddItemForType` → `loginCreate` / `bankCardCreate` / `noteCreate` → `VaultItemViewModel.create` → `submitVaultItem` → `VaultHomeViewModel.refreshVault`.

There is no empty-state Add button. The FAB does not write vault data and does not skip `VaultItemViewModel`.

After the first save, Home chrome stays and the created item appears in the list; the content empty state is gone.

## Delete last item

`VaultHomeViewModel.deleteItem` reloads the vault. When collections are empty again, status is `empty` and the items section shows the content empty state. Navigation stays on Home.

## Type filter empty

`HomeController.selectType` / category chips still filter `visibleItems`. Zero matches keep chrome and show a content empty widget for that filter. Type summary rows are not hidden when counts are zero; tapping a type still opens `TypeListItemView`.

## Tests

[`test/feature/vault/vault_home_view_test.dart`](../../test/feature/vault/vault_home_view_test.dart):

- Empty vault: header, type selector, FAB, content empty without Add; no page `AppEmptyWidget.vault`
- Expanding the FAB opens login create without `addItem`
- Refresh after create: item listed, empty gone, chrome remains
- Delete last item: content empty returns, chrome remains
- Type filter with zero rows: content empty, chrome remains
- Empty vault search: idle, not `موردی یافت نشد`
- Existing loading, loaded, error, retry, search, and delete tests remain

ViewModel empty status tests are unchanged (`VaultUiStatus.empty`).

## Files changed

- `lib/feature/home/view/home_view.dart`
- `lib/feature/home/viewmodel/home_viewmodel.dart`
- `lib/shared/widget/app_empty_widget.dart`
- `lib/shared/widget/app_fab_widget.dart`
- `lib/feature/search/viewmodel/search_viewmodel.dart`
- `lib/shared/widget/app_search_widget.dart`
- `test/feature/vault/vault_home_view_test.dart`
- `documents/implementation/10_ui_integration_vault_screens.md`
- `documents/implementation/16_home_empty_state.md`
