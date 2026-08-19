# Task 09 — Vault Presentation and ViewModels

This note describes the **Presentation/ViewModel layer that is actually in the codebase**.

It is a learning reference and an implementation record. The source of truth is the Dart code and tests, not the architecture proposals.

Related code:

- [`lib/feature/vault/viewmodel/vault_ui_status.dart`](../../lib/feature/vault/viewmodel/vault_ui_status.dart)
- [`lib/feature/vault/viewmodel/vault_home_viewmodel.dart`](../../lib/feature/vault/viewmodel/vault_home_viewmodel.dart)
- [`lib/feature/vault/viewmodel/vault_item_viewmodel.dart`](../../lib/feature/vault/viewmodel/vault_item_viewmodel.dart)
- [`lib/core/di/injection_container.dart`](../../lib/core/di/injection_container.dart)
- [`test/feature/vault/vault_home_viewmodel_test.dart`](../../test/feature/vault/vault_home_viewmodel_test.dart)
- [`test/feature/vault/vault_item_viewmodel_test.dart`](../../test/feature/vault/vault_item_viewmodel_test.dart)
- [`test/core/hive_database_test.dart`](../../test/core/hive_database_test.dart)

It reuses Task 08 (`VaultOperationService`) and Task 05 models (`VaultData`, `LoginItem`, `BankCardItem`, `SecureNoteItem`, `CategoryItem`). It does **not** change operations, mutation, serializer, crypto, Hive, or the unlock lifecycle. It does **not** add or rewire screens.

---

## 1. Overview

Task 09 is the first GetX ViewModel layer that talks to the encrypted vault stack. Prototype screens still use in-memory stores (`HomeController`, `LoginCreateViewModel`, `LoginVaultStore`). Those were not changed. Task 10 can bind widgets to these ViewModels.

In simple terms, this layer answers:

1. How does the Home screen load, search, and delete without knowing about Hive or `VaultSession`?
2. How does create/update submit a Task 05 item and get loading / success / error state back?
3. How are `Result` / `AppFailure` values turned into presentation state the UI can switch on?

Keyva still uses **MVVM + GetX**. There is no UseCase / Domain / Interactor layer. The ViewModels call `VaultOperationService` the same way Task 08 called `VaultDataService`.

```text
UI                    ← still prototype screens / mock stores
 ↓
VaultHomeViewModel / VaultItemViewModel   ← this task
 ↓
VaultOperationService
```

---

## 2. Architecture

Both ViewModels extend `GetxController` and take one constructor dependency:

```text
VaultOperationService
```

They do **not** take `VaultDataService`, `VaultSession`, `VaultRepository`, `VaultSerializer`, or `CryptoService`. They do not call `Get.find()` or `getIt` internally.

```text
UI (Task 10+)
      ↓
VaultHomeViewModel / VaultItemViewModel
      ↓
VaultOperationService          ← Task 08
      ↓
VaultDataService               ← mutations (Task 07)
VaultSession                   ← current VaultData reads (Task 06)
      ↓
VaultData (immutable model)
      ↓
VaultSerializer → Uint8List
      ↓
VaultRepository.saveVaultData()
      ↓
AES-256-GCM → Hive VaultRecord
```

Bypassing the application layer would let a ViewModel choose `addLogin` vs `addBankCard`, talk to Hive, or hold a VaultKey. Task 08 already owns type dispatch and persistence routing. The ViewModel only coordinates UI state and calls that API.

Existing type-specific form ViewModels (`LoginFormViewModel`, and so on) still hold `TextEditingController`s and mock stores. They are not this layer.

---

## 3. Implemented ViewModels

Two ViewModels. Not four type-specific copies. Task 08 already dispatches `addItem(Object)` / `updateItem(Object)` / `deleteItem(id)`.

### VaultHomeViewModel

| | |
|---|---|
| File | [`vault_home_viewmodel.dart`](../../lib/feature/vault/viewmodel/vault_home_viewmodel.dart) |
| Responsibility | Load the current vault, expose items for a list, search in memory, delete through operations, refresh after a successful delete |
| Dependency | `VaultOperationService operations` |
| Operations used | `getVault()`, `deleteItem(id)` |

Exposed GetX state:

| Field | Type | Meaning |
|---|---|---|
| `status` | `Rx<VaultUiStatus>` | `initial`, `loading`, `loaded`, `empty`, `error`, `submitting` |
| `vault` | `Rxn<VaultData>` | last successful snapshot; `null` until the first success |
| `visibleItems` | `RxList<Object>` | search-filtered flatten of logins, cards, notes, categories |
| `searchQuery` | `RxString` | last query passed to `searchItems` (untrimmed as received) |
| `errorMessage` | `Rxn<String>` | last mapped `AppFailure.message` |

Public methods:

```dart
Future<void> loadVault();
Future<void> refreshVault();
void searchItems(String query);
Future<void> deleteItem(String id);
```

`refreshVault()` is `loadVault()`. The name is not `refresh()` because `GetxController` already has `refresh()`.

`visibleItems` holds concrete Task 05 models (`LoginItem`, …) as `Object`. It does not use `VaultListItem` or `IconData`.

This ViewModel does not call `addItem`, `updateItem`, or `getItemById`.

### VaultItemViewModel

| | |
|---|---|
| File | [`vault_item_viewmodel.dart`](../../lib/feature/vault/viewmodel/vault_item_viewmodel.dart) |
| Responsibility | Validate a complete Task 05 item, then create or update it through operations |
| Dependency | `VaultOperationService operations` |
| Operations used | `addItem(item)`, `updateItem(item)` |

Exposed GetX state:

| Field | Type | Meaning |
|---|---|---|
| `status` | `Rx<VaultUiStatus>` | `initial`, `submitting`, `success`, `error` |
| `errorMessage` | `Rxn<String>` | last mapped failure message |
| `currentItem` | `Rxn<Object>` | last item that passed local validation |

Public methods:

```dart
Future<void> create(Object item);
Future<void> updateItem(Object item);
```

`updateItem` is not named `update()` because `GetxController.update()` already exists.

Callers supply a complete model, including `id` and timestamps. This ViewModel does not generate ids. It does not hold `TextEditingController`s. Local validation runs before the operation is called.

---

## 4. Presentation State

Shared enum in [`vault_ui_status.dart`](../../lib/feature/vault/viewmodel/vault_ui_status.dart):

```dart
enum VaultUiStatus {
  initial,
  loading,
  loaded,
  empty,
  error,
  submitting,
  success,
}
```

GetX `.obs` is still the state mechanism. The enum is the value the UI can switch on. There is no second state-management package and no sealed state class.

| Status | Who sets it | When |
|---|---|---|
| `initial` | constructor default | nothing has run yet |
| `loading` | `VaultHomeViewModel.loadVault` | before `getVault()` |
| `loaded` | Home `_applyVisibleItems` | vault has at least one item (search may still yield an empty list) |
| `empty` | Home `_applyVisibleItems` | all four collections are empty |
| `error` | both ViewModels | local validation failed, or `FailureResult` from operations |
| `submitting` | Home `deleteItem`; Item `create` / `updateItem` | operation in flight |
| `success` | `VaultItemViewModel` only | `addItem` / `updateItem` returned `Success` |

Home does not use `success`. After a successful delete it calls `loadVault()`, so the next status is `loading` then `loaded` or `empty`.

Item does not use `loading`, `loaded`, or `empty`.

On Home load or delete failure, previous `vault` / `visibleItems` are left in place. `_setError` only writes `status` and `errorMessage`.

---

## 5. Vault Loading

```text
status = loading
errorMessage = null
      ↓
VaultOperationService.getVault()
      ↓
FailureResult  → status = error, errorMessage = failure.message
Success        → vault = data, then _applyVisibleItems(data)
```

`_applyVisibleItems`:

- all collections empty → `visibleItems` cleared, `status = empty`
- otherwise flatten, filter by the current trimmed `searchQuery`, `status = loaded`

`refreshVault()` is the same path. A later load re-applies the current query, so a filter survives reload.

The ViewModel does not decrypt, deserialize, or read Hive. `getVault()` returns the unlocked session `VaultData` from Task 08.

---

## 6. Search

Search is **only** in `VaultHomeViewModel.searchItems`. Task 08 has no search API. There is no second persisted collection.

```text
searchQuery = query          ← stored as received
read vault.value
      ↓
null vault → return (status unchanged)
otherwise → _applyVisibleItems (in memory)
```

It never calls `addItem`, `updateItem`, or `deleteItem`. Tests assert `persistCount == 0` and that the fake vault instance is unchanged.

Matching is case-insensitive `contains` on trimmed query. Empty / whitespace query matches every item.

Flatten order (stable, no sort):

```text
logins → bankCards → secureNotes → categories
```

Fields searched:

| Type | Fields |
|---|---|
| `LoginItem` | `title`, `username`, `website`, `notes` |
| `BankCardItem` | `title`, `cardHolder`, `bankName`, `notes` |
| `SecureNoteItem` | `title`, `content` |
| `CategoryItem` | `name` |

`id`, `cardNumber`, and `cvv` are not searched.

Presentation effect:

- vault empty → stay `empty`, `visibleItems` empty
- vault has items, some match → `loaded` with those items
- vault has items, none match → `loaded` with empty `visibleItems`

---

## 7. Create / Update / Delete

### Create

```text
UI
 ↓
VaultItemViewModel.create(item)
 ↓
local _isValid(item)          ← if false: error, operation not called
 ↓
currentItem = item
status = submitting
 ↓
VaultOperationService.addItem(item)
 ↓
VaultDataService typed add
 ↓
serialize → saveVaultData → session replace
```

Success → `status = success`. Failure → `status = error`, `errorMessage = failure.message`. `currentItem` stays set if validation passed.

### Update

Same path through `updateItem(item)` → `VaultOperationService.updateItem(item)`.

### Delete

```text
UI
 ↓
VaultHomeViewModel.deleteItem(id)
 ↓
status = submitting
 ↓
VaultOperationService.deleteItem(id)
 ↓
Failure → error, previous vault / visibleItems kept
Success → loadVault()   ← list matches the session again
```

While submitting, the previous list is not cleared.

Local validation (Item ViewModel, before any operation):

| Item | Required non-empty |
|---|---|
| `LoginItem` | `id`, `title`, `username`, `password` |
| `BankCardItem` | `id`, `title`, `cardNumber`, `cardHolder`, `expiryDate`, `cvv`, `bankName` |
| `SecureNoteItem` | `id`, `title`, `content` |
| `CategoryItem` | `id`, `name` |
| any other `Object` | invalid |

Invalid input uses `ValidationFailure().message` (`Vault data is invalid`) and does not set `currentItem`. Serializer rules (duplicate ids, version) stay in Task 07/08.

---

## 8. Error Mapping

ViewModels do not catch Hive, crypto, or serializer exceptions. Those already became `AppFailure` below this layer. Mapping is:

```text
AppFailure
    ↓
status = error
errorMessage = failure.message
```

Messages are the existing generic defaults:

| Failure | Message written to `errorMessage` |
|---|---|
| `AuthenticationFailure` | `Unable to unlock your vault.` |
| `ValidationFailure` | `Vault data is invalid` |
| `CryptoFailure` | `Cryptographic operation failed` |
| `DatabaseFailure` | `Database operation failed` |

The UI sees `VaultUiStatus.error` and a `String?`. It does not receive `Result`, `HiveError`, `CryptoException`, serializer internals, or repository types.

Local validation uses the same `ValidationFailure` message so invalid input and operation-layer validation look the same to widgets.

---

## 9. Dependency Injection

Still one composition root: [`injection_container.dart`](../../lib/core/di/injection_container.dart).

ViewModels are **factories**, not lazy singletons. Each `GetxController` has its own Rx state.

```text
registerLazySingleton<VaultOperationService>  → VaultOperationServiceImpl
registerFactory<VaultHomeViewModel>           → VaultHomeViewModel     ← new
registerFactory<VaultItemViewModel>           → VaultItemViewModel     ← new
```

```dart
getIt.registerFactory<VaultHomeViewModel>(
  () => VaultHomeViewModel(operations: getIt<VaultOperationService>()),
);
getIt.registerFactory<VaultItemViewModel>(
  () => VaultItemViewModel(operations: getIt<VaultOperationService>()),
);
```

GetX Bindings were not changed. Task 10 can later do `Get.lazyPut(() => getIt<VaultHomeViewModel>())`.

---

## 10. Testing

Tests use fakes, not Hive or Argon2id. `_FakeVaultOperationService` records calls, can delay with a `Completer` so tests observe `loading` / `submitting`, and counts mutations so search can assert `persistCount == 0`. ViewModels are constructed with the fake. Tests do not use `Get.put` or GetIt.

| Test file | What it actually checks |
|---|---|
| [`vault_home_viewmodel_test.dart`](../../test/feature/vault/vault_home_viewmodel_test.dart) | initial state; `loading` then `loaded` with flattened items; empty vault → `empty`; `AuthenticationFailure` / `DatabaseFailure` → generic `errorMessage`; `refreshVault` reloads; search match order; login/card/note/category field match; no matches stay `loaded` with empty list; empty query restores all items; search does not mutate the fake vault; search on empty vault stays `empty`; current query survives reload; delete sets `submitting` then refreshes without the item; last-item delete → `empty`; delete `ValidationFailure` keeps previous items; delete `CryptoFailure` maps the generic crypto message |
| [`vault_item_viewmodel_test.dart`](../../test/feature/vault/vault_item_viewmodel_test.dart) | initial state; create `submitting` then `success` with `addItem` receiving the same item; `ValidationFailure` / `CryptoFailure` / `AuthenticationFailure` → presentation error; empty title / unknown type / empty required fields do not call `addItem`; update `submitting` then `success` with `updateItem`; update `DatabaseFailure`; invalid update does not call the operation |
| [`hive_database_test.dart`](../../test/core/hive_database_test.dart) | `initDependencies` also registers `VaultHomeViewModel` and `VaultItemViewModel` |

Architectural guarantees the tests enforce:

- Home search does not increment fake `persistCount`
- Failed Home mutations leave the previous list visible
- Item local validation skips the operation
- Failure messages are the generic `AppFailure` strings, not exception `toString()`

---

## 11. Architectural Constraints

`VaultHomeViewModel` and `VaultItemViewModel` do **not** import or call:

- Hive
- `VaultDataSource` / `HiveVaultDataSource`
- `VaultRepository`
- `VaultSerializer`
- `CryptoService`
- `VaultDataService`
- `VaultSession`
- `SessionService`

They also do not:

- Rebuild `VaultData`
- Serialize, encrypt, or write Hive
- Unlock, lock, or authenticate
- Navigate, build widgets, or use `TextEditingController` / `GlobalKey`
- Look up GetIt or `Get.find()`

Forbidden direction that was not implemented:

```text
ViewModel → VaultDataService
ViewModel → VaultRepository
ViewModel → Hive
ViewModel → Serializer
ViewModel → CryptoService
```

Required direction that was implemented:

```text
ViewModel → VaultOperationService
```

---

## 12. Files changed

| File | Change |
|---|---|
| [`lib/feature/vault/viewmodel/vault_ui_status.dart`](../../lib/feature/vault/viewmodel/vault_ui_status.dart) | created — shared `VaultUiStatus` |
| [`lib/feature/vault/viewmodel/vault_home_viewmodel.dart`](../../lib/feature/vault/viewmodel/vault_home_viewmodel.dart) | created — load, search, delete |
| [`lib/feature/vault/viewmodel/vault_item_viewmodel.dart`](../../lib/feature/vault/viewmodel/vault_item_viewmodel.dart) | created — create, update |
| [`lib/core/di/injection_container.dart`](../../lib/core/di/injection_container.dart) | register both ViewModel factories |
| [`test/feature/vault/vault_home_viewmodel_test.dart`](../../test/feature/vault/vault_home_viewmodel_test.dart) | created — unit tests with a fake operations service |
| [`test/feature/vault/vault_item_viewmodel_test.dart`](../../test/feature/vault/vault_item_viewmodel_test.dart) | created — unit tests with a fake operations service |
| [`test/core/hive_database_test.dart`](../../test/core/hive_database_test.dart) | assert GetIt registration of both ViewModels |

Task 05–08 models and services, serializer, crypto, Hive adapters, `UserRecord`, `VaultRecord`, GetX Bindings, and prototype UI ViewModels were not modified.

---

## Security limitations / explicit non-goals

### Security limitations

- After a successful load, plaintext `VaultData` and item fields (including passwords, PAN, CVV, note content) live in Home `vault` / `visibleItems` and in Item `currentItem`. This layer does not copy them into a sanitized DTO or zeroize fields.
- Search runs on those in-memory plaintext fields. Card number and CVV are excluded from the match list; they remain on the loaded objects.

### Explicit non-goals

This task does **not** provide:

- Home / login / card / note screen layouts, navigation, theme, or Bindings
- Wiring of `HomeController` or type form ViewModels to `VaultOperationService`
- Id or timestamp generation
- Sort, favorites, password generation, or strength
- Category cascade / referential integrity
- Backup / restore
- PIN, biometrics, or auto-lock
- Master Password change
- A UseCase / Domain / Interactor / DTO layer
- A second DI container
- Changes to Argon2id, AES-GCM, `SecurityConstants`, `UserRecord`, or `VaultRecord`
