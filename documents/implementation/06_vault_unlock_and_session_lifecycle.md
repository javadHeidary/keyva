# Task 06 — Vault Unlock and Session Lifecycle

This note describes the **runtime vault unlock/lock lifecycle that is actually in the codebase**.

It is a learning reference and an implementation record. The source of truth is the Dart code and tests, not the architecture proposals.

Related code:

- [`lib/feature/vault/session/vault_session.dart`](../../lib/feature/vault/session/vault_session.dart)
- [`lib/feature/vault/session/vault_session_impl.dart`](../../lib/feature/vault/session/vault_session_impl.dart)
- [`lib/feature/vault/service/vault_unlock_service.dart`](../../lib/feature/vault/service/vault_unlock_service.dart)
- [`lib/feature/vault/service/vault_unlock_service_impl.dart`](../../lib/feature/vault/service/vault_unlock_service_impl.dart)
- [`lib/core/di/injection_container.dart`](../../lib/core/di/injection_container.dart)
- [`test/feature/vault/vault_session_test.dart`](../../test/feature/vault/vault_session_test.dart)
- [`test/feature/vault/vault_unlock_service_test.dart`](../../test/feature/vault/vault_unlock_service_test.dart)
- [`test/core/hive_database_test.dart`](../../test/core/hive_database_test.dart)

It reuses Task 03 (`AuthRepository`, `SessionService`), Task 04 (`VaultRepository` byte API), and Task 05 (`VaultData`, `VaultSerializer`). It does **not** add CRUD, UI, PIN, biometrics, auto-lock, or schema migration.

---

## 1. Purpose

Task 06 introduces the application-level lifecycle for an unlocked vault.

In simple terms, this layer answers:

1. How do we turn a Master Password into decrypted `VaultData` in memory?
2. Where does unlocked vault state live at runtime, separate from the Vault Key?
3. How do we lock that state without leaving a partial unlock behind?
4. How do we treat a newly created account that has no persisted vault yet?

The UI still does not call this layer. ViewModels and Bindings were not changed.

---

## 2. Runtime vault lifecycle

The real pipeline composes existing boundaries. Decrypt and VaultKey storage were not reimplemented:

```text
Master Password + userId
      ↓
AuthRepository.authenticate()
      ↓
derive authentication key + unwrap VaultKey     ← Task 03
      ↓
SessionService.vaultKey                         ← in-memory VaultKey owner
      ↓
VaultRepository.loadVaultData()                 ← Task 04: AES-GCM decrypt, returns plaintext Uint8List?
      ↓
VaultSerializer.deserialize()                   ← Task 05, or empty VaultData if null
      ↓
VaultSession.unlock(vaultData)                  ← Task 06: in-memory VaultData only
```

Locking reverses both runtime stores:

```text
VaultUnlockService.lock()
      ↓
VaultSession.lock()           ← drop VaultData
AuthRepository.logout()       ← SessionService.clear() zeros VaultKey
```

`userId` is required because `AuthRepository.authenticate` identifies the account by id. There is still no username lookup.

---

## 3. VaultSession

[`VaultSession`](../../lib/feature/vault/session/vault_session.dart) is an in-memory holder for the currently unlocked `VaultData`.

```dart
abstract interface class VaultSession {
  bool get isUnlocked;
  VaultData? get vaultData;
  Future<Result<void>> unlock(VaultData vaultData);
  Future<Result<void>> lock();
}
```

[`VaultSessionImpl`](../../lib/feature/vault/session/vault_session_impl.dart):

- Starts locked: `_vaultData == null`, so `isUnlocked == false`
- `unlock` stores the `VaultData` reference (replace is allowed)
- `lock` nulls the reference and is safe when already locked
- `isUnlocked` is true exactly when `_vaultData != null`, including an empty vault
- Collections stay unmodifiable because `VaultData` already copies into `List.unmodifiable`

It does **not**:

- Persist `VaultData` or the VaultKey
- Access Hive, GetIt, `SessionService`, `CryptoService`, or the Master Password
- Hold or expose a VaultKey
- Log vault contents

The suggested `unlock(VaultData, Uint8List vaultKey)` API was not used. Task 03 already owns the VaultKey in `SessionService`. A second copy would duplicate secret ownership.

---

## 4. VaultUnlockService

[`VaultUnlockService`](../../lib/feature/vault/service/vault_unlock_service.dart) is the application-facing coordinator.

```dart
abstract interface class VaultUnlockService {
  Future<Result<void>> unlock({
    required String userId,
    required String masterPassword,
  });

  Future<Result<void>> lock();
}
```

[`VaultUnlockServiceImpl`](../../lib/feature/vault/service/vault_unlock_service_impl.dart) constructor dependencies:

```text
AuthRepository
VaultRepository
VaultSerializer
VaultSession
```

It does **not** take `CryptoService` or `SessionService`. Unwrap happens inside `AuthRepository`. AES-GCM decrypt happens inside `VaultRepository.loadVaultData()`.

---

## 5. Authentication boundary

`AuthRepository` remains responsible for:

- loading the `UserRecord`
- Argon2id derive
- unwrap of `WrappedVaultKey`
- `SessionService.setAuthenticated(...)` on success
- collapsing every unlock miss to `AuthenticationFailure`
- clearing the session on failed authenticate and on `logout()`

`VaultUnlockService` only calls `authenticate` and `logout`. It does not derive keys or unwrap the VaultKey.

---

## 6. VaultKey ownership

There is still **one** runtime VaultKey store: [`SessionService`](../../lib/core/session/session_service.dart).

| Owner | What it holds |
|-------|----------------|
| `SessionService` | Authenticated identity + plaintext VaultKey in RAM |
| `VaultSession` | Decrypted `VaultData` in RAM |
| Hive | `WrappedVaultKey` on `UserRecord`; AES-GCM ciphertext on `VaultRecord` |

Rules that the implementation follows:

- `VaultSession` never stores, serializes, or logs the VaultKey
- `VaultData` has no key field; serializer JSON keys stay `version`, `logins`, `bankCards`, `secureNotes`, `categories`
- The VaultKey is never written to Hive by this task
- `lock()` / failed unlock after authenticate call `AuthRepository.logout()`, which zeros the key via `SessionService.clear()`

---

## 7. Repository boundary

[`VaultRepository`](../../lib/feature/vault/repository/vault_repository.dart) is still byte-oriented:

```dart
Future<Result<Uint8List?>> loadVaultData();
Future<Result<void>> saveVaultData(Uint8List plaintext);
Future<Result<void>> deleteVault();
```

`loadVaultData()` already decrypts with `SessionService.vaultKey` and returns plaintext bytes, or `Success(null)` when no `VaultRecord` exists.

Task 04 files were not modified. The unlock service never calls `saveVaultData` or `deleteVault`.

---

## 8. Serializer boundary

[`VaultSerializer`](../../lib/feature/vault/serialization/vault_serializer.dart) still owns `VaultData` ↔ `Uint8List`.

It does not know about authentication, VaultKey, Hive, or GetIt. Invalid JSON and unsupported `VaultData.version` still return `ValidationFailure`. Task 05 was not modified.

---

## 9. Unlock flow

Implemented in `VaultUnlockServiceImpl.unlock`:

```text
authenticate(userId, masterPassword)
        ↓
if failure → VaultSession.lock() → return AuthenticationFailure
        ↓
VaultRepository.loadVaultData()
        ↓
if failure → lock VaultSession + logout → return existing failure
        ↓
plaintext == null
        → in-memory VaultData(version: 1, empty lists)
        → do not persist
plaintext != null
        → VaultSerializer.deserialize
        → if failure → lock + logout → return ValidationFailure
        ↓
VaultSession.unlock(vaultData)
```

A missing vault is not treated as corruption. `Success(null)` becomes an empty `VaultData` with `VaultData.currentVersion` (`1`). That empty vault stays in RAM only until a later task saves it.

---

## 10. Lock flow

`VaultUnlockService.lock()`:

1. `VaultSession.lock()` — `_vaultData = null`, `isUnlocked == false`
2. `AuthRepository.logout()` — `SessionService.clear()` zeros and drops the VaultKey

Calling lock while already locked is safe. Subsequent `vaultSession.vaultData` is `null`.

This task does not add auto-lock timers, lifecycle observers, PIN, or biometrics.

---

## 11. Failure handling

Existing `Result<T>` / `FailureResult<T>` / `AppFailure` types are reused. No new failure class was added.

| Case | Result | Runtime state |
|------|--------|----------------|
| Wrong password / unknown user | `AuthenticationFailure` | VaultSession locked; SessionService already cleared by auth |
| Tampered ciphertext / auth tag | `VaultDecryptionFailure` | lock + logout |
| Malformed vault envelope | `CryptoFailure` (from repository) | lock + logout |
| Invalid JSON / unsupported version | `ValidationFailure` | lock + logout |
| Missing `VaultRecord` | success with empty `VaultData` | unlocked |

Failure messages stay the existing generic defaults. They do not include passwords, card numbers, CVVs, note content, raw JSON, `exception.toString()`, or the VaultKey.

---

## 12. Atomic unlock behavior

`VaultSession` becomes unlocked only after authenticate, load/decrypt, and deserialize have all succeeded.

If any later step fails after a successful authenticate:

```text
VaultSession.lock()
AuthRepository.logout()
```

That prevents these inconsistent states:

- VaultKey in `SessionService` with no `VaultData`
- leftover `VaultData` after a failed re-unlock (wrong password clears `SessionService` first; the service then locks `VaultSession`)

Auth failure does not call `logout()` again; `AuthRepository.authenticate` already cleared the session. The service still `lock()`s `VaultSession` in case a previous vault was open.

---

## 13. DI registration

Still one composition root: [`injection_container.dart`](../../lib/core/di/injection_container.dart).

```text
registerLazySingleton<VaultSerializer>      → VaultSerializerImpl
registerLazySingleton<AuthRepository>       → AuthRepositoryImpl
registerLazySingleton<VaultRepository>      → VaultRepositoryImpl
registerLazySingleton<VaultSession>         → VaultSessionImpl          ← new
registerLazySingleton<VaultUnlockService>   → VaultUnlockServiceImpl    ← new
```

`VaultUnlockServiceImpl` receives `auth`, `vaults`, `serializer`, and `vaultSession` through its constructor. Implementations do not look up GetIt themselves.

---

## 14. Tests

KDF cases use production Argon2id parameters (64 MB) and a 2-minute timeout, same as Task 03.

| Test file | What it actually checks |
|-----------|-------------------------|
| [`vault_session_test.dart`](../../test/feature/vault/vault_session_test.dart) | Starts locked; unlock stores `VaultData` and sets `isUnlocked`; data is accessible only while unlocked; lock clears data; lock twice is safe; unlock replaces previous data; mutating the source list does not change session collections; exposed lists throw `UnsupportedError` |
| [`vault_unlock_service_test.dart`](../../test/feature/vault/vault_unlock_service_test.dart) | Real Hive + `CryptoServiceImpl` + `AuthRepositoryImpl`: successful unlock restores original `VaultData`; wrong password → `AuthenticationFailure` and locked session; tampered ciphertext → `VaultDecryptionFailure` and locked; invalid JSON and version `99` → `ValidationFailure` and locked; missing vault → empty `VaultData(version: 1)` without writing Hive; failed re-unlock after success leaves everything locked; `lock()` zeros the VaultKey; Hive ciphertext is not plaintext JSON and does not contain passwords/cards/CVVs/notes; serialized `VaultData` has no `vaultKey` key and does not contain the live VaultKey bytes |
| [`hive_database_test.dart`](../../test/core/hive_database_test.dart) | `initDependencies` also registers `VaultSession` and `VaultUnlockService` |

Task 01–05 tests were not weakened and still pass.

---

## 15. Security limitations / explicit non-goals

### Security limitations

- VaultKey and `VaultData` live in Dart heap memory while unlocked. This task only clears references (and zeros the VaultKey buffer via existing `SessionService.clear()`). It does not attempt VM-level memory zeroization.
- Empty initial vaults are not persisted. Until a later save task runs, killing the process drops that empty in-memory vault.
- There is no attempt-rate limiting, auto-lock timer, or background isolate for Argon2id.

### Explicit non-goals

This task does **not** provide:

- Login / bank card / secure note / category CRUD
- UI, GetX ViewModels, or Bindings
- PIN or biometric unlock
- Auto-lock / lifecycle observers
- Backup / restore
- Master Password change
- Schema migration
- Cloud sync or a backend
- Hive adapters for vault item models
- Changes to Argon2id, AES-GCM, `SecurityConstants`, `UserRecord`, `VaultRecord`, or the Task 04/05 contracts
- A UseCase / Domain / Interactor layer
- A second VaultKey store inside `VaultSession`
- A second DI container
