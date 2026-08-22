# Task 10 — UI Integration and Vault Screens

This note describes the **Flutter UI that is actually wired to the Task 09 ViewModels**.

It is a learning reference and an implementation record. The source of truth is the Dart code and tests, not the architecture proposals.

Related code:

- [`lib/feature/home/view/home_view.dart`](../../lib/feature/home/view/home_view.dart)
- [`lib/feature/home/viewmodel/home_viewmodel.dart`](../../lib/feature/home/viewmodel/home_viewmodel.dart)
- [`lib/feature/home/bindings/home_bindings.dart`](../../lib/feature/home/bindings/home_bindings.dart)
- [`lib/feature/vault/view/vault_list_item_mapper.dart`](../../lib/feature/vault/view/vault_list_item_mapper.dart)
- [`lib/feature/vault/view/vault_form_submit.dart`](../../lib/feature/vault/view/vault_form_submit.dart)
- [`lib/feature/type/login/viewmodel/login_create_viewmodel.dart`](../../lib/feature/type/login/viewmodel/login_create_viewmodel.dart)
- [`lib/feature/type/login/viewmodel/login_edit_viewmodel.dart`](../../lib/feature/type/login/viewmodel/login_edit_viewmodel.dart)
- [`lib/feature/type/bank_card/viewmodel/bank_card_create_viewmodel.dart`](../../lib/feature/type/bank_card/viewmodel/bank_card_create_viewmodel.dart)
- [`lib/feature/type/bank_card/viewmodel/bank_card_edit_viewmodel.dart`](../../lib/feature/type/bank_card/viewmodel/bank_card_edit_viewmodel.dart)
- [`lib/feature/type/note/viewmodel/note_create_viewmodel.dart`](../../lib/feature/type/note/viewmodel/note_create_viewmodel.dart)
- [`lib/feature/type/note/viewmodel/note_edit_viewmodel.dart`](../../lib/feature/type/note/viewmodel/note_edit_viewmodel.dart)
- [`lib/feature/search/viewmodel/search_viewmodel.dart`](../../lib/feature/search/viewmodel/search_viewmodel.dart)
- [`lib/feature/vault/view/vault_item_navigation.dart`](../../lib/feature/vault/view/vault_item_navigation.dart)
- [`lib/feature/type/login/viewmodel/login_details_viewmodel.dart`](../../lib/feature/type/login/viewmodel/login_details_viewmodel.dart)
- [`lib/feature/type/bank_card/viewmodel/bank_card_details_viewmodel.dart`](../../lib/feature/type/bank_card/viewmodel/bank_card_details_viewmodel.dart)
- [`lib/feature/type/note/viewmodel/note_details_viewmodel.dart`](../../lib/feature/type/note/viewmodel/note_details_viewmodel.dart)
- [`test/feature/vault/vault_home_view_test.dart`](../../test/feature/vault/vault_home_view_test.dart)
- [`test/feature/vault/vault_item_form_view_test.dart`](../../test/feature/vault/vault_item_form_view_test.dart)
- [`test/feature/vault/vault_item_details_view_test.dart`](../../test/feature/vault/vault_item_details_view_test.dart)
- [`test/feature/vault/vault_item_details_navigation_test.dart`](../../test/feature/vault/vault_item_details_navigation_test.dart)

It reuses Task 09 (`VaultHomeViewModel`, `VaultItemViewModel`) and Task 05 models (`LoginItem`, `BankCardItem`, `SecureNoteItem`). It does **not** change operations, mutation, serializer, crypto, Hive, unlock, or ViewModel public APIs.

---

## 1. Overview

Task 10 is the first layer that lets real Flutter widgets talk to the encrypted vault stack. Prototype Home mock lists and type-store `add`/`update` paths for create/edit were replaced for those flows.

In simple terms, this layer answers:

1. How does Home load, search, delete, and retry without knowing about Hive or `VaultSession`?
2. How do Login / Bank Card / Secure Note forms submit a Task 05 item through `VaultItemViewModel`?
3. How are `VaultUiStatus` values turned into loading, empty, error, and list UI?

Keyva still uses **MVVM + GetX + GetIt**. There is no second state-management package.

```text
Flutter UI
 ↓
VaultHomeViewModel / VaultItemViewModel   ← Task 09
 ↓
VaultOperationService                     ← Task 08
 ↓
VaultDataService                          ← Task 07
 ↓
Encrypted persistence                     ← Tasks 04–06
```

Widgets do not import `VaultDataService`, repositories, Hive, serializer, or crypto.

---

## 2. UI Architecture

```text
User interaction
      ↓
HomeView / Login|Card|Note form views
      ↓
HomeController (chrome + navigation) + form ViewModels (fields)
      ↓
VaultHomeViewModel / VaultItemViewModel
      ↓
VaultOperationService
      ↓
VaultDataService → serialize → encrypt → Hive
```

`HomeController` is still the GetX controller for Home chrome (FAB, type chips, category chips, account header). Vault list data comes from `VaultHomeViewModel.visibleItems`, mapped to `VaultListItem` in [`vault_list_item_mapper.dart`](../../lib/feature/vault/view/vault_list_item_mapper.dart). `CategoryItem` rows are skipped in that mapping. Search matching stays in `VaultHomeViewModel.searchItems`.

Form screens keep existing `TextEditingController`s on `LoginFormViewModel` / `BankCardFormViewModel` / `NoteFormViewModel`. Those classes do not call operations. Create/edit subclasses assemble a Task 05 model and call [`submitVaultItem`](../../lib/feature/vault/view/vault_form_submit.dart), which runs `VaultItemViewModel.create` or `updateItem`.

GetIt still owns ViewModel factories. Bindings do:

```text
Get.lazyPut(() => getIt<VaultHomeViewModel>())
Get.lazyPut(() => getIt<VaultItemViewModel>())   ← per create/edit route
```

---

## 3. Implemented Screens

| Screen | Role |
|---|---|
| Home (`HomeView`) | Vault list, load/empty/error/retry, pull-to-refresh, FAB create-by-type |
| Search (`AppSearchWidget`) | Delegates query to `VaultHomeViewModel.searchItems` |
| Type list (`TypeListItemView`) | Items of one `VaultItemType`; back returns to Home |
| Login / Bank card / Secure note details | Read-only Task 05 fields from the loaded vault snapshot |
| Login create / edit | Task 05 `LoginItem` via `VaultItemViewModel` |
| Bank card create / edit | Task 05 `BankCardItem` via `VaultItemViewModel` (includes `cardHolder`) |
| Secure note create / edit | Task 05 `SecureNoteItem` via `VaultItemViewModel` |

Navigation:

```text
Vault Home / Search / Type list
   ├── Item tap → matching details route (id argument)
   │      └── «ویرایش» → matching edit route
   └── FAB / empty CTA → create
          └── success → type list + details (create removed from the stack)
```

Detail screens are Login, Bank Card, and Secure Note. They read `VaultHomeViewModel.vault` through `findVaultItemById`. They do not talk to Hive, `VaultRepository`, `VaultDataService`, or `CryptoService`.

The More menu stays copy + delete. Edit is not a More action. Primary path is always Tap → Detail → Edit.

Password and CVV are masked by default on details (`•` + eye toggle). List subtitles never include password, PAN, or CVV.

Password strength stays on the Login form and Login details (`PasswordStrengthBarWidget` on the form; strength label on details).

---

## 4. State Rendering

Home reads `VaultHomeViewModel.status`:

| Status | UI |
|---|---|
| `initial` / `loading` | `AppLoadingWidget` page (unless a vault snapshot already exists; then Home chrome stays) |
| `empty` | Same Home chrome as loaded; items section shows `AppEmptyWidget.vault` (card layout + create CTA). Not a full-page empty Home. |
| `loaded` / `submitting` / `success` | List chrome; submitting keeps the previous list and disables extra deletes |
| `error` | `VaultErrorView` + retry when no snapshot; if a snapshot exists, the list stays |

Form screens:

| Status | UI |
|---|---|
| Field validation | Existing Persian `Form` validators |
| `submitting` | `AppButtonWidget.isLoading` (duplicate taps ignored) |
| `success` | Refresh Home vault; create opens Detail above Type list; edit `Get.back` to Detail |
| `error` | `VaultSubmitErrorText` from mapped `AppFailure.message` |

Users do not see `HiveException`, `CryptoException`, or repository types. Known `AppFailure` strings are mapped to Persian in [`vault_user_message.dart`](../../lib/feature/vault/view/vault_user_message.dart). Strings that look like exceptions fall back to a generic Persian error.

---

## 5. User Flows

### Load Vault

`HomeController.onReady` calls `loadVault()` when status is still `initial`. Pull-to-refresh calls `refreshVault()`.

### Search

Home search chip opens `AppSearchWidget`. `SearchViewModel` calls `searchItems(query)` and displays the mapped `visibleItems`. An `ever` worker on `visibleItems` re-applies results without clearing the query, so returning from Detail/Edit does not show stale titles. Empty/whitespace query restores the in-memory full list. Closing search resets the query. Persist count is not increased (Task 09 already guarantees that).

### Create

FAB or empty CTA → type create route → field controllers → Task 05 model (UI generates `id` / timestamps) → `VaultItemViewModel.create` → `refreshVault()` → `openCreatedVaultItem`.

That helper pops Create (and any extra type list under it) until `/shell` or `/home`, then pushes Type list for that kind and Detail for the new id:

```text
/shell
  → /type-list (VaultItemType)
    → /login/details | /bank-card/details | /note/details
```

Back from Detail → type list. Type-list header back → Home. Create is not left on the stack.

Login maps the first website string to `LoginItem.website`. Note maps body → `content`. Bank card maps `bankTitle` → `bankName`, `expiry` → `expiryDate`.

### Detail

List tap → details route with item id. The screen hydrates from the already-loaded `VaultHomeViewModel.vault` snapshot (`findVaultItemById`). Missing item → `Get.back`. Category names come from `VaultData.categories`.

Sensitive fields: login password and bank-card CVV are hidden by default with an eye toggle. Secure note details show title + content only.

### Edit

Detail «ویرایش» → existing edit route with the same item id (not `offNamed`). The form hydrates from the already-loaded `VaultHomeViewModel.vault` snapshot (`findVaultItemById`). It does not call `getItemById` from the widget. Missing item → `Get.back`. Submit uses `updateItem` and preserves `id` / `createdAt`. Back from Edit returns to Detail.

### Delete

More menu → `حذف` → `AppDialogWidget` confirm → `VaultHomeViewModel.deleteItem(id)`. Copy actions in the same menu read the Task 05 object already in memory, not mock stores. Detail footer delete uses the same confirm path and then pops Detail.

### Retry

`VaultErrorView` retry button calls `loadVault()`.

---

## 6. RTL / Responsive Support

- App locale remains `fa_IR` in `KeyvaApp`.
- Home list padding uses `EdgeInsetsDirectional.only` for start/end.
- Home search hint sits in an `Expanded` text with ellipsis so RTL + narrow width does not overflow.
- New error/submit helpers use `EdgeInsetsDirectional` where padding is directional.
- Existing LTR-safe shared widgets were left in place unless a change was required.
- Design tokens reused: `AppColors` / `AppTypography` / `AppSpacing` / `AppRadius` / `AppSized` / `AppResponsive` / theme extensions. Shared widgets: `AppListItemWidget`, `AppEmptyWidget`, `AppLoadingWidget`, `AppFabWidget`, `AppDialogWidget`, `AppButtonWidget`, `AppSearchHeaderWidget`.

---

## 7. Testing

Widget tests use fakes, not Hive. They pump `GetMaterialApp` + `AppTheme` + `AppResponsive.init`. ViewModels are constructed with [`FakeVaultOperationService`](../../test/feature/vault/support/fake_vault_operation_service.dart).

| File | Scenarios |
|---|---|
| [`vault_home_view_test.dart`](../../test/feature/vault/vault_home_view_test.dart) | loading, loaded items (categories omitted; secrets not in subtitles), empty, error + retry, search filters then restores, search screen delegates to ViewModel, confirmed delete calls `deleteItem` |
| [`vault_item_form_view_test.dart`](../../test/feature/vault/vault_item_form_view_test.dart) | Login fields, validation errors, submitting, successful `addItem` then Detail (Create gone), failure banner, edit hydrates from loaded vault |
| [`vault_item_details_view_test.dart`](../../test/feature/vault/vault_item_details_view_test.dart) | Login / Bank Card / Secure Note details show Task 05 fields; password and CVV hidden by default; Detail refreshes after vault update |
| [`vault_item_details_navigation_test.dart`](../../test/feature/vault/vault_item_details_navigation_test.dart) | Home/Search tap → Detail; «ویرایش» → Edit; back Edit → Detail → list; More is copy/delete not Edit; create → Detail → type list → Home; search results are not stale |

GetX is process-global, so [`dart_test.yaml`](../../dart_test.yaml) sets `concurrency: 1` for stable widget tests.

---

## 8. Files changed

| File | Change |
|---|---|
| `lib/feature/vault/view/vault_list_item_mapper.dart` | created — Task 05 → `VaultListItem` |
| `lib/feature/vault/view/vault_user_message.dart` | created — generic Persian error copy |
| `lib/feature/vault/view/vault_form_submit.dart` | created — create/update submit helper |
| `lib/feature/vault/view/vault_error_view.dart` | created — Home error/retry + form error text |
| `lib/feature/home/view/home_view.dart` | status rendering, refresh, hide trash, directional padding |
| `lib/feature/home/viewmodel/home_viewmodel.dart` | vault list, item tap → details, confirmed delete |
| `lib/feature/home/view/type_list_item_view.dart` | capture type at construction so later Detail args cannot overwrite it |
| `lib/feature/vault/view/vault_item_navigation.dart` | details route helper + post-create stack (type list + details) |
| `lib/feature/vault/view/vault_form_submit.dart` | optional `onSuccess` so create can open Detail instead of `Get.back` |
| `lib/feature/search/viewmodel/search_viewmodel.dart` | searchItems + `ever(visibleItems)` so results are not stale |
| Login / Bank Card / Note details ViewModels + views | Task 05 snapshot via `findVaultItemById`; masked secrets; «ویرایش» reuses edit |
| `test/feature/vault/vault_item_details_view_test.dart` | created |
| `test/feature/vault/vault_item_details_navigation_test.dart` | created |
| `lib/feature/home/bindings/home_bindings.dart` | register `VaultHomeViewModel` factory |
| `lib/feature/home/util/vault_more_actions.dart` | copy/delete from Task 05 models |
| `lib/feature/search/viewmodel/search_viewmodel.dart` | delegate to `searchItems` |
| `lib/shared/widget/app_search_widget.dart` | show ViewModel results; empty query can show the full list |
| `lib/shared/widget/app_more_widget.dart` | optional `onPressed` / destructive delete action |
| Login / Bank Card / Note create+edit ViewModels + Bindings + form scaffolds | submit through `VaultItemViewModel` |
| `lib/feature/type/bank_card/viewmodel/bank_card_form_viewmodel.dart` + form content | `cardHolder` field required by Task 09 validation |
| `test/feature/vault/vault_home_view_test.dart` | created |
| `test/feature/vault/vault_item_form_view_test.dart` | created |
| `dart_test.yaml` | widget-test-safe concurrency |

Task 05–09 models and services, serializer, crypto, Hive adapters, and authentication were not modified.

---

## Security limitations / explicit non-goals

### Security limitations

- Home list, search results, and details still hold plaintext Task 05 objects in `VaultHomeViewModel` (same as Task 09). Subtitles avoid password, PAN, and CVV. Details mask password and CVV by default. The more menu can still copy those values after an explicit tap.
- Form controllers hold plaintext while the screen is open. They are disposed in `onClose`.

### Explicit non-goals

This task does **not** provide:

- Settings, onboarding, authentication, or backup/restore changes
- Category cascade / trash / favorites
- A UseCase / Domain / DTO layer
- A second state-management framework
- Changes to Argon2id, AES-GCM, `VaultRecord`, or Hive schema
