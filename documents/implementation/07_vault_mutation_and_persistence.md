# Task 07 — Vault Mutation and Persistence

This note describes the **application-level vault mutation and persistence layer that is actually in the codebase**.

It is a learning reference and an implementation record. The source of truth is the Dart code and tests, not the architecture proposals.

Related code:

- [`lib/feature/vault/service/vault_data_service.dart`](../../lib/feature/vault/service/vault_data_service.dart)
- [`lib/feature/vault/service/vault_data_service_impl.dart`](../../lib/feature/vault/service/vault_data_service_impl.dart)
- [`lib/core/di/injection_container.dart`](../../lib/core/di/injection_container.dart)
- [`test/feature/vault/vault_data_service_test.dart`](../../test/feature/vault/vault_data_service_test.dart)
- [`test/core/hive_database_test.dart`](../../test/core/hive_database_test.dart)

It reuses Task 04 (`VaultRepository.saveVaultData`), Task 05 (`VaultData`, `VaultSerializer`), and Task 06 (`VaultSession`, `VaultUnlockService`). It does **not** change models, crypto, Hive adapters, or the unlock lifecycle. It does **not** add UI.

---

## 1. Purpose

Task 07 is the first layer that changes unlocked `VaultData` and writes it back through the encrypted persistence path.

In simple terms, this layer answers:

1. How do we add, update, or delete a login, card, note, or category without mutating existing objects?
2. How do we persist that change only after it is serializable?
3. How do we keep RAM and disk aligned when a save fails?
4. How do we stop two overlapping mutations from overwriting each other?

The UI still does not call this layer. ViewModels and Bindings were not changed.

---

## 2. Mutation layer

[`VaultDataService`](../../lib/feature/vault/service/vault_data_service.dart) is the application coordinator. [`VaultDataServiceImpl`](../../lib/feature/vault/service/vault_data_service_impl.dart) constructor dependencies:

```text
VaultSerializer
VaultRepository
VaultSession
```

It does **not** take `CryptoService` or `SessionService`. AES-GCM still happens inside `VaultRepository.saveVaultData()`. The VaultKey stays in `SessionService`.

The composed path:

```text
Mutation request
      ↓
VaultDataService
      ↓
new immutable VaultData
      ↓
VaultSerializer.serialize()
      ↓
Uint8List
      ↓
VaultRepository.saveVaultData()
      ↓
AES-256-GCM → Hive VaultRecord
      ↓
VaultSession.unlock(new VaultData)
```

Runtime ownership stays split:

```text
SessionService  → VaultKey
VaultSession    → VaultData
```

---

## 3. Supported operations

Twelve methods, all `Future<Result<void>>`:

| Collection | Add | Update | Delete |
|------------|-----|--------|--------|
| Login | `addLogin(LoginItem)` | `updateLogin(LoginItem)` | `deleteLogin(String id)` |
| Bank card | `addBankCard(BankCardItem)` | `updateBankCard(BankCardItem)` | `deleteBankCard(String id)` |
| Secure note | `addSecureNote(SecureNoteItem)` | `updateSecureNote(SecureNoteItem)` | `deleteSecureNote(String id)` |
| Category | `addCategory(CategoryItem)` | `updateCategory(CategoryItem)` | `deleteCategory(String id)` |

Callers supply complete immutable items, including `id` and timestamps. This layer does not generate IDs, rewrite timestamps, search, sort, or mark favorites.

Category referential integrity is unchanged from Task 05:

- `categoryId == null` is valid
- an item may reference a missing category
- deleting a category does not delete or rewrite its items

---

## 4. Immutable VaultData updates

Task 05 models have no `copyWith`. Mutations copy the target collection (`[...items, item]`, `List.of(...)` then replace/remove), then construct a **new** `VaultData` via `_rebuild`.

The other three collections are passed through as-is. `version` is copied from the current vault, not reset.

The previous `VaultData` instance is left unchanged. Session collections remain `List.unmodifiable` because the `VaultData` constructor still wraps them.

---

## 5. Add flow

```text
require unlocked VaultSession
      ↓
reject if the collection already has this id  → ValidationFailure
      ↓
append to a copied list
      ↓
new VaultData
      ↓
serialize → persist → replace session
```

Duplicate ids are not silently ignored. Empty ids pass the duplicate check (if unique) and then fail in `VaultSerializer` as `ValidationFailure`.

---

## 6. Update flow

```text
require unlocked VaultSession
      ↓
find index by id
      ↓
missing id → ValidationFailure (do not insert)
      ↓
replace at the same index (order preserved)
      ↓
new VaultData → serialize → persist → replace session
```

---

## 7. Delete flow

```text
require unlocked VaultSession
      ↓
find index by id
      ↓
missing id → ValidationFailure (do not succeed)
      ↓
remove from a copied list
      ↓
new VaultData → serialize → persist → replace session
```

---

## 8. Serialization boundary

[`VaultSerializer`](../../lib/feature/vault/serialization/vault_serializer.dart) still owns `VaultData` ↔ `Uint8List`.

The mutation layer does not reimplement schema rules. After building a candidate, it calls `serialize`. Empty ids, duplicate ids, and unsupported versions still become `ValidationFailure`. On that failure the session is not updated and `saveVaultData` is not called.

---

## 9. Persistence boundary

The mutation layer only persists through:

```dart
vaults.saveVaultData(serializedBytes);
```

It never opens a Hive box. Task 04 still create-or-updates `VaultRecord` and encrypts with `SessionService.vaultKey`. The first successful mutation after an empty unlock therefore creates the vault row.

---

## 10. Atomic mutation behavior

Session state is replaced only after both serialize and save succeed:

```text
current VaultData
      ↓
candidate VaultData
      ↓
serialize
      ↓
saveVaultData
      ↓
SUCCESS
      ↓
VaultSession.unlock(candidate)
```

If serialize or save fails, `VaultSession` still holds the previous `VaultData`. That prevents RAM = new data / disk = old data.

`VaultSession.unlock` is used only as a replace of in-memory `VaultData`. The session stays unlocked. The VaultKey is not touched.

---

## 11. Concurrent mutation handling

`VaultDataServiceImpl` serializes operations with an in-process future chain (`_enqueue` / `_tail`). No extra package.

```text
addLogin(A) enqueued
      ↓
persist + session update
      ↓
addLogin(B) reads the updated session
      ↓
persist + session update
```

Two overlapping `addLogin` futures therefore both apply. A failed mutation still completes the queue so the next call can run.

---

## 12. Locked-state behavior

Every mutation requires `VaultSession.isUnlocked` and a non-null `vaultData`.

If the vault is locked:

```text
add / update / delete → AuthenticationFailure
```

That matches `VaultRepositoryImpl` when there is no authenticated session. The service does not authenticate, unlock, load from Hive, or read the VaultKey.

---

## 13. Failure handling

Existing `Result<T>` / `FailureResult<T>` / `AppFailure` types are reused. `NotFoundFailure` and `SessionFailure` were not added.

| Case | Type |
|------|------|
| Vault locked / no `VaultData` | `AuthenticationFailure` |
| Duplicate id | `ValidationFailure` |
| Missing id on update/delete | `ValidationFailure` |
| Serializer reject (empty id, bad version, …) | `ValidationFailure` |
| Save / encrypt / Hive errors | `CryptoFailure` or `DatabaseFailure` from the repository |

Messages stay the existing generic defaults. They do not include passwords, card numbers, CVVs, notes, raw JSON, `exception.toString()`, or the VaultKey.

---

## 14. Tests

KDF cases use production Argon2id parameters (64 MB) and a 2-minute timeout, same as Task 03.

| Test file | What it actually checks |
|-----------|-------------------------|
| [`vault_data_service_test.dart`](../../test/feature/vault/vault_data_service_test.dart) | Real Hive + `CryptoServiceImpl` + `AuthRepositoryImpl`: login/card/note/category add, update, delete; duplicate and missing ids → `ValidationFailure`; category delete does not cascade; previous `VaultData` is unchanged and session lists throw `UnsupportedError`; mutate → lock → unlock restores items; Hive ciphertext is not plaintext and does not contain passwords/PAN/CVV/notes; JSON has no `vaultKey`; a failing `saveVaultData` wrapper leaves the previous session; empty id → `ValidationFailure` and unchanged session; locked vault → `AuthenticationFailure`; concurrent `addLogin(A)` and `addLogin(B)` both persist |
| [`hive_database_test.dart`](../../test/core/hive_database_test.dart) | `initDependencies` also registers `VaultDataService` |

Task 01–06 tests were not weakened and still pass.

---

## 15. Security limitations / explicit non-goals

### Security limitations

- While unlocked, plaintext `VaultData` and the VaultKey still live in the Dart heap. This task only replaces or leaves session references; it does not zeroize item fields.
- The mutation queue is single-isolate only. It does not coordinate across isolates or processes.
- There is no conflict resolution beyond “run one mutation at a time.”
- Callers must still go through Task 06 to unlock. This layer will not recover a locked vault.

### GetIt registration

Still one composition root: [`injection_container.dart`](../../lib/core/di/injection_container.dart).

```text
registerLazySingleton<VaultUnlockService>  → VaultUnlockServiceImpl
registerLazySingleton<VaultDataService>    → VaultDataServiceImpl     ← new
```

`VaultDataServiceImpl` receives `serializer`, `vaults`, and `vaultSession` through its constructor. Implementations do not look up GetIt themselves.

### Explicit non-goals

This task does **not** provide:

- UI, GetX ViewModels, or Bindings
- Search, sort, filter, or favorites
- Password generation or strength
- Category cascade / referential integrity
- Backup / restore
- PIN, biometrics, or auto-lock
- Master Password change
- Schema migration or Hive adapters for vault items
- Changes to Argon2id, AES-GCM, `SecurityConstants`, `UserRecord`, or `VaultRecord`
- A second VaultKey store
- A second DI container
- A UseCase / Domain / Interactor layer
