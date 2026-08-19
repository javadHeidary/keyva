# Task 08 — Vault Application Operations

This note describes the **application-level vault operation API that is actually in the codebase**.

It is a learning reference and an implementation record. The source of truth is the Dart code and tests, not the architecture proposals.

Related code:

- [`lib/feature/vault/service/vault_operation_service.dart`](../../lib/feature/vault/service/vault_operation_service.dart)
- [`lib/feature/vault/service/vault_operation_service_impl.dart`](../../lib/feature/vault/service/vault_operation_service_impl.dart)
- [`lib/core/di/injection_container.dart`](../../lib/core/di/injection_container.dart)
- [`test/feature/vault/vault_operation_service_test.dart`](../../test/feature/vault/vault_operation_service_test.dart)
- [`test/core/hive_database_test.dart`](../../test/core/hive_database_test.dart)

It reuses Task 06 (`VaultSession`) and Task 07 (`VaultDataService` typed mutations). It does **not** change models, serializer, crypto, Hive, repository APIs, or the unlock lifecycle. It does **not** add UI.

---

## 1. Overview

Task 08 is the presentation-facing vault API. ViewModels will call this layer instead of `VaultDataService`, `VaultSession`, Hive, or crypto.

In simple terms, this layer answers:

1. How does the UI get the current vault without knowing about `VaultSession`?
2. How does the UI look up one item by id across logins, cards, notes, and categories?
3. How does the UI add, update, or delete an item without choosing `addLogin` vs `addBankCard` vs …?
4. How are those mutations still forced through Task 07 persistence?

Keyva does **not** have a Clean Architecture UseCase / Domain / Interactor layer. The application boundary is a service, same as `VaultUnlockService` and `VaultDataService`:

```text
VaultOperationService / VaultOperationServiceImpl
```

The UI still does not call this layer. ViewModels and Bindings were not changed.

---

## 2. Architecture

[`VaultOperationServiceImpl`](../../lib/feature/vault/service/vault_operation_service_impl.dart) constructor dependencies:

```text
VaultDataService
VaultSession
```

Reads use `VaultSession`. Mutations go only through `VaultDataService`. This class does **not** rebuild `VaultData`, serialize, encrypt, or write Hive.

```text
ViewModel (later)
    ↓
VaultOperationService
    ↓
VaultDataService          ← mutations (Task 07)
VaultSession              ← current VaultData reads (Task 06)
    ↓
VaultData (immutable model)
    ↓
VaultSerializer → Uint8List
    ↓
VaultRepository.saveVaultData()
    ↓
AES-256-GCM → Hive VaultRecord
```

`VaultOperationService` never talks to `VaultRepository`, `VaultDataSource`, `VaultSerializer`, or `CryptoService`.

---

## 3. Implemented operations

Five methods on [`VaultOperationService`](../../lib/feature/vault/service/vault_operation_service.dart):

```dart
Future<Result<VaultData>> getVault();
Future<Result<Object>> getItemById(String id);
Future<Result<void>> addItem(Object item);
Future<Result<void>> updateItem(Object item);
Future<Result<void>> deleteItem(String id);
```

`Object` is required because `LoginItem`, `BankCardItem`, `SecureNoteItem`, and `CategoryItem` have no shared base. No sealed wrapper was added. Callers pass the concrete Task 05 model.

This layer does not generate IDs, rewrite timestamps, search, sort, or mark favorites.

### Get Vault

| | |
|---|---|
| Responsibility | Return the current unlocked `VaultData` |
| Input | none |
| Output | `Result<VaultData>` |
| Dependencies | `VaultSession` |
| Failure | locked or `vaultData == null` → `AuthenticationFailure` |

It returns the session instance. It does not copy, load from Hive, or decrypt.

### Get Item By ID

| | |
|---|---|
| Responsibility | Find one item in the current vault |
| Input | `id` |
| Output | `Result<Object>` — the concrete `LoginItem` / `BankCardItem` / `SecureNoteItem` / `CategoryItem` |
| Dependencies | `getVault()` → `VaultSession` |
| Failure | locked → `AuthenticationFailure`; missing id → `ValidationFailure` |

Search order matches `VaultData` field order: logins, bankCards, secureNotes, categories. IDs are unique per collection, not globally. First match wins. The method never returns `null`; a miss is `FailureResult(ValidationFailure())`. `NotFoundFailure` was not added.

### Add Item

| | |
|---|---|
| Responsibility | Append a new item by dispatching to the matching Task 07 method |
| Input | concrete item (`Object`) |
| Output | `Result<void>` from `VaultDataService` |
| Dependencies | `VaultDataService` |
| Failure | unknown type → `ValidationFailure` here; otherwise the data-service result unchanged |

```text
LoginItem      → addLogin
BankCardItem   → addBankCard
SecureNoteItem → addSecureNote
CategoryItem   → addCategory
other          → ValidationFailure (data service is not called)
```

Duplicate ids, empty ids, locked vault, serialize errors, and save errors stay in Task 07.

### Update Item

| | |
|---|---|
| Responsibility | Replace an existing item; never insert |
| Input | concrete item with the same id |
| Output | `Result<void>` from `VaultDataService` |
| Dependencies | `VaultDataService` |
| Failure | unknown type → `ValidationFailure` here; missing id → `ValidationFailure` from Task 07 |

Same type dispatch as add, using `updateLogin` / `updateBankCard` / `updateSecureNote` / `updateCategory`.

### Delete Item

| | |
|---|---|
| Responsibility | Remove an existing item after locating its collection |
| Input | `id` |
| Output | `Result<void>` |
| Dependencies | `VaultSession` (existence check), then `VaultDataService` |
| Failure | locked → `AuthenticationFailure`; missing id → `ValidationFailure` **without** calling the data service |

```text
getVault()
      ↓
id in logins      → deleteLogin
id in bankCards   → deleteBankCard
id in secureNotes → deleteSecureNote
id in categories  → deleteCategory
not found         → ValidationFailure
```

---

## 4. Immutability

This layer does **not** construct a new `VaultData`. That stays in `VaultDataServiceImpl`:

```text
Current VaultData (VaultSession)
      ↓
Task 07 copies the target collection and builds a new VaultData
      ↓
serialize → saveVaultData → VaultSession.unlock(candidate)
```

`VaultOperationService` only selects which Task 07 method to call. There is no second mutable vault cache. Session lists remain `List.unmodifiable` because the `VaultData` constructor still wraps them.

---

## 5. Error handling

Existing `Result<T>` / `FailureResult<T>` / `AppFailure` types are reused. Exceptions are not the normal control flow. `NotFoundFailure` and `SessionFailure` were not added.

| Case | Type | Where |
|------|------|--------|
| Vault locked / no `VaultData` | `AuthenticationFailure` | `getVault`, `getItemById`, `deleteItem`; mutations via Task 07 |
| Missing id on get or delete | `ValidationFailure` | this layer |
| Missing id on update | `ValidationFailure` | Task 07 |
| Duplicate id on add | `ValidationFailure` | Task 07 |
| Unsupported `Object` type | `ValidationFailure` | this layer |
| Serializer / save / encrypt / Hive | `ValidationFailure`, `CryptoFailure`, or `DatabaseFailure` | Task 07 / repository, returned unchanged |

Messages stay the existing generic defaults. This layer does not copy item fields, ids, or `exception.toString()` into failures.

---

## 6. Dependency injection

Still one composition root: [`injection_container.dart`](../../lib/core/di/injection_container.dart).

```text
registerLazySingleton<VaultDataService>        → VaultDataServiceImpl
registerLazySingleton<VaultOperationService>   → VaultOperationServiceImpl   ← new
```

```dart
getIt.registerLazySingleton<VaultOperationService>(
  () => VaultOperationServiceImpl(
    vaultData: getIt<VaultDataService>(),
    vaultSession: getIt<VaultSession>(),
  ),
);
```

`VaultOperationServiceImpl` receives both dependencies through its constructor. It does not call `Get.find()` or look up GetIt itself.

---

## 7. Testing

Tests use fakes, not Hive or Argon2id. `_FakeVaultSession` holds in-memory `VaultData`. `_FakeVaultDataService` records whether a mutation was requested, applies immutable collection copies on success, and can return a configured `AppFailure`.

| Test file | What it actually checks |
|-----------|-------------------------|
| [`vault_operation_service_test.dart`](../../test/feature/vault/vault_operation_service_test.dart) | `getVault` returns the session vault; locked → `AuthenticationFailure`; `getItemById` hit (login and card) and miss → `ValidationFailure`; add appends a login and leaves siblings unchanged with `persistCount == 1`; bank-card add dispatches; unknown add type → `ValidationFailure` and no persist; update replaces only the target; missing update id → `ValidationFailure` and unchanged vault; unknown update type → `ValidationFailure`; delete removes only the target; missing delete id → `ValidationFailure` and **does not** call the data service; bank-card delete dispatches; `CryptoFailure` / `DatabaseFailure` / `AuthenticationFailure` / `ValidationFailure` from the fake data service are returned as-is without applying the mutation; note and category add/update/delete also dispatch |
| [`hive_database_test.dart`](../../test/core/hive_database_test.dart) | `initDependencies` also registers `VaultOperationService` |

Architectural guarantees the tests enforce:

- Mutations go through `VaultDataService` (fake `persistCount` / `lastMutation` / `mutationRequested`)
- A missing delete does not call the data service
- An update of a missing id is not an implicit create
- Unrelated items stay in place
- Data-service failures propagate without a second error type

---

## 8. Architectural constraints

`VaultOperationServiceImpl` does **not** import or call:

- Hive
- `VaultDataSource` / `HiveVaultDataSource`
- `VaultRepository`
- `VaultSerializer`
- `CryptoService`
- `SessionService` (VaultKey owner)

It also does not:

- Rebuild `VaultData`
- Serialize or encrypt
- Unlock, lock, or authenticate
- Access GetIt or GetX

Forbidden dependency direction that was not implemented:

```text
VaultOperationService → VaultRepository
VaultOperationService → Hive
VaultOperationService → Serializer
VaultOperationService → CryptoService
```

Required direction that was implemented:

```text
VaultOperationService → VaultDataService   (mutations)
VaultOperationService → VaultSession       (reads)
```

---

## 9. Files changed

| File | Change |
|------|--------|
| [`lib/feature/vault/service/vault_operation_service.dart`](../../lib/feature/vault/service/vault_operation_service.dart) | created — interface |
| [`lib/feature/vault/service/vault_operation_service_impl.dart`](../../lib/feature/vault/service/vault_operation_service_impl.dart) | created — implementation |
| [`lib/core/di/injection_container.dart`](../../lib/core/di/injection_container.dart) | register `VaultOperationService` |
| [`test/feature/vault/vault_operation_service_test.dart`](../../test/feature/vault/vault_operation_service_test.dart) | created — unit tests with fakes |
| [`test/core/hive_database_test.dart`](../../test/core/hive_database_test.dart) | assert GetIt registration |

Task 05–07 models, `VaultDataService` API, serializer, crypto, Hive adapters, `UserRecord`, and `VaultRecord` were not modified.

---

## Security limitations / explicit non-goals

### Security limitations

- While unlocked, plaintext `VaultData` is still readable from `VaultSession`. This layer returns those objects; it does not copy them into a sanitized DTO or zeroize fields.
- `getItemById` / `addItem` / `updateItem` use `Object`. Callers must pattern-match the concrete type.

### Explicit non-goals

This task does **not** provide:

- UI, GetX ViewModels, or Bindings
- Search, sort, filter, or favorites
- Password generation or strength
- Category cascade / referential integrity
- Backup / restore
- PIN, biometrics, or auto-lock
- Master Password change
- A UseCase / Domain / Interactor layer
- A second DI container
- Changes to Argon2id, AES-GCM, `SecurityConstants`, `UserRecord`, or `VaultRecord`
- Changes to Task 07’s typed mutation API
