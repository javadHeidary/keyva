# Task 04 — Encrypted Vault Persistence Foundation

This note describes the **encrypted vault persistence foundation that is actually in the codebase**.

It is a learning reference and an implementation record. The source of truth is the Dart code and tests, not the architecture proposals.

Related code:

- [`lib/core/database/vault_data_source.dart`](../../lib/core/database/vault_data_source.dart)
- [`lib/core/database/hive_vault_data_source.dart`](../../lib/core/database/hive_vault_data_source.dart)
- [`lib/feature/vault/repository/vault_repository.dart`](../../lib/feature/vault/repository/vault_repository.dart)
- [`lib/feature/vault/repository/vault_repository_impl.dart`](../../lib/feature/vault/repository/vault_repository_impl.dart)
- [`lib/core/database/models/vault_record.dart`](../../lib/core/database/models/vault_record.dart)
- [`lib/core/crypto/encrypted_payload.dart`](../../lib/core/crypto/encrypted_payload.dart)
- [`lib/core/di/injection_container.dart`](../../lib/core/di/injection_container.dart)
- [`test/core/database/hive_vault_data_source_test.dart`](../../test/core/database/hive_vault_data_source_test.dart)
- [`test/feature/vault/vault_repository_test.dart`](../../test/feature/vault/vault_repository_test.dart)

---

## Purpose

Task 04 connects Task 01 Hive storage, Task 02 AES-GCM, and Task 03’s in-memory Vault Key so opaque vault bytes can be encrypted and persisted.

In simple terms, this layer answers:

1. How do we store encrypted vault bytes in Hive without putting plaintext on disk?
2. How do we use the authenticated session Vault Key without touching the Master Password?
3. How do we map `EncryptedPayload` (separate authentication tag) onto `VaultRecord` (Option A, tag inside `ciphertext`)?
4. How do we load, save, and delete that blob without inventing login/card/note models yet?

It reuses Task 01 (`VaultRecord`, `HiveDatabase.vaults`, `HiveErrorMapper`, `Result` / `AppFailure`, GetIt), Task 02 (`CryptoService`, `EncryptedPayload`, `SecurityConstants`), and Task 03 (`SessionService`). It does **not** define vault item types, change crypto parameters, or wire the existing UI.

---

## Architecture

Keyva still uses **MVVM**. There is no UseCase / Domain / Interactor layer. `VaultRepository` is the application coordinator.

```text
View (Flutter widgets)            ← still the prototype UI
    ↓
ViewModel (GetX)                  ← still in-memory vault stores
    ↓
VaultRepository                   ← new
    ↓
VaultDataSource + CryptoService + SessionService
    ↓
HiveVaultDataSource → HiveDatabase.vaults
```

The encryption path is:

```text
SessionService.vaultKey
        ↓
VaultRepository
        ↓
CryptoService.encrypt / decrypt
        ↓
AES-256-GCM
        ↓
EncryptedPayload
        ↓
Option A concat / split
        ↓
VaultRecord
        ↓
Hive vaults box
```

### What each new piece does

| Type | Actual responsibility |
|------|------------------------|
| **`VaultDataSource`** | Persist / load / update / delete `VaultRecord` only. No crypto. |
| **`HiveVaultDataSource`** | Talks to `HiveDatabase.vaults`. Hive key is `userId`. Maps Hive errors through `HiveErrorMapper`. |
| **`VaultRepository`** | Load / save / delete opaque `Uint8List` vault bytes. Coordinates session + encrypt/decrypt + Option A mapping. |

### Boundary that Task 04 created

- Views and ViewModels still do not access Hive or crypto.
- Only `HiveVaultDataSource` writes the `vaults` box.
- Only `VaultRepositoryImpl` encrypts, decrypts, and concatenates/splits the authentication tag.
- The Master Password never enters this layer.
- Implementations do not look up `GetIt` themselves. Constructor injection only.

### What the UI still does

Login/register ViewModels, GetX Bindings, and in-memory type stores (`login_vault_store`, `note_vault_store`, `bank_card_vault_store`) were not changed. The prototype remains functional; it does not call `VaultRepository` yet.

---

## VaultDataSource

Interface: [`lib/core/database/vault_data_source.dart`](../../lib/core/database/vault_data_source.dart)

```dart
abstract interface class VaultDataSource {
  Future<Result<void>> create(VaultRecord vault);
  Future<Result<VaultRecord?>> findByUserId(String userId);
  Future<Result<void>> update(VaultRecord vault);
  Future<Result<void>> delete(String userId);
}
```

Implementation: [`HiveVaultDataSource`](../../lib/core/database/hive_vault_data_source.dart), positional constructor `HiveVaultDataSource(this._database)`.

| Method | Behavior |
|--------|----------|
| `create` | If `vaults.containsKey(userId)` → `DatabaseFailure`. Else `put(userId, vault)`. |
| `findByUserId` | `Success(box.get(userId))`. Missing record is `Success(null)`, not a failure. |
| `update` | If the key is missing → `DatabaseFailure`. Else `put`. |
| `delete` | `vaults.delete(userId)` only. Never touches the `users` box. |

Unexpected Hive errors are caught and mapped with `HiveErrorMapper`. The DataSource does **not** encrypt, decrypt, read `SessionService`, or know the Vault Key.

---

## VaultRepository

Interface: [`lib/feature/vault/repository/vault_repository.dart`](../../lib/feature/vault/repository/vault_repository.dart)

```dart
abstract interface class VaultRepository {
  Future<Result<Uint8List?>> loadVaultData();
  Future<Result<void>> saveVaultData(Uint8List plaintext);
  Future<Result<void>> deleteVault();
}
```

Implementation: [`VaultRepositoryImpl`](../../lib/feature/vault/repository/vault_repository_impl.dart)

Named constructor, matching `AuthRepositoryImpl`:

```dart
VaultRepositoryImpl({
  required VaultDataSource vaults,
  required CryptoService crypto,
  required SessionService session,
})
```

The payload is an opaque `Uint8List`. There is no `VaultData`, `LoginItem`, `BankCardItem`, `SecureNoteItem`, or `CategoryItem` type in this layer.

Every method requires an authenticated session (`isAuthenticated`, `current != null`, `vaultKey != null`). Otherwise it returns `AuthenticationFailure`. User id comes from `SessionService.current.userId`. The Vault Key comes only from `SessionService.vaultKey`.

`deleteVault` removes the `VaultRecord` for the current user. It does not clear the session and does not delete `UserRecord`.

---

## Encryption flow (save)

```text
plaintext Uint8List
        ↓
require authenticated session
        ↓
SessionService.vaultKey
        ↓
CryptoService.encrypt(plaintext, key)
        ↓
EncryptedPayload
        ↓
validate version / nonce length / tag length
        ↓
ciphertext || authenticationTag
        ↓
VaultRecord(formatVersion = vaultEncryptionVersion, updatedAt = DateTime.now())
        ↓
findByUserId → missing create() / present update()
```

The repository does not generate a nonce. `CryptoService.encrypt` already uses a fresh AES-GCM nonce. The session Vault Key is not overwritten after encrypt.

---

## Decryption flow (load)

```text
require authenticated session
        ↓
VaultDataSource.findByUserId(current.userId)
        ↓
missing → Success(null)   (does not auto-create)
        ↓
validate formatVersion, nonce length, ciphertext length
        ↓
split last authenticationTagLength bytes = tag
        ↓
remainder = ciphertext
        ↓
EncryptedPayload(version: formatVersion, ...)
        ↓
CryptoService.decrypt(payload, vaultKey)
        ↓
plaintext Uint8List
```

Malformed records (unknown `formatVersion`, wrong nonce size, ciphertext shorter than the tag) return `CryptoFailure` before decrypt is called. AES-GCM authentication failure from `CryptoService.decrypt` is returned as `VaultDecryptionFailure`.

Empty plaintext is valid: AES-GCM ciphertext may be zero bytes plus a 16-byte tag.

---

## `VaultRecord` persistence format

Unchanged Hive model from Task 01 (typeId 4):

| Field | Type | Stored meaning |
|-------|------|----------------|
| `userId` | `String` | Owner. Also the Hive box key. Equals `UserRecord.id`. |
| `formatVersion` | `int` | Written as `SecurityConstants.vaultEncryptionVersion` (`1`). |
| `nonce` | `Uint8List` | 12-byte AES-GCM nonce from `EncryptedPayload.nonce`. |
| `ciphertext` | `Uint8List` | AES-GCM ciphertext **plus** the 16-byte authentication tag (Option A). |
| `updatedAt` | `DateTime` | `DateTime.now()` on each save. |

There is still no `authenticationTag` field on `VaultRecord`. Hive adapters were not regenerated.

One vault per user: the Hive key is `userId`, so a second save updates the same record.

---

## Authentication-tag handling (Option A)

Task 02’s `EncryptedPayload` keeps the tag in a separate field. `VaultRecord` does not. Mapping lives only in `VaultRepositoryImpl`.

On save:

```text
VaultRecord.ciphertext
  = EncryptedPayload.ciphertext
  || EncryptedPayload.authenticationTag
```

On load:

```text
tagSize = SecurityConstants.authenticationTagLength   // 16
authenticationTag = last 16 bytes of VaultRecord.ciphertext
ciphertext        = remaining prefix
EncryptedPayload.version = VaultRecord.formatVersion
```

The tag size is **not** a new constant. It is the existing `SecurityConstants.authenticationTagLength`. Lengths are validated before the split. A record that is too short fails closed as `CryptoFailure`.

---

## Session / Vault Key relationship

```text
Master Password
        ↓
Argon2id                          ← AuthRepository (Task 03)
        ↓
Derived Key
        ↓
unwrap WrappedVaultKey
        ↓
Vault Key
        ↓
SessionService.setAuthenticated
        ↓
VaultRepository                   ← this task
        ↓
CryptoService.encrypt / decrypt
```

`VaultRepository` never sees the Master Password and never derives a key. If the session is missing, operations fail with `AuthenticationFailure`. Logout (Task 03) zeros the in-memory Vault Key; this layer does not call `SessionService.clear()`.

---

## Persisted vs in-memory data

### Persisted (Hive `vaults` box)

- `userId`
- `formatVersion`
- AES-GCM nonce
- ciphertext including the authentication tag
- `updatedAt`

### Never persisted by this design

| Value | Where it exists |
|--------|------------------|
| Master Password | Not used by this layer |
| Derived Key | Not used by this layer |
| Plaintext Vault Key | `SessionService` RAM only |
| Plaintext vault bytes | `saveVaultData` argument / `loadVaultData` return value only |
| `EncryptedPayload` | In-memory crypto DTO; not a Hive type |

After a normal first launch, or after registration without a save, the `vaults` box is empty. Registration still does not create a `VaultRecord`.

---

## Error handling

Existing `AppFailure` types only. No new failure classes.

| Situation | Result |
|-----------|--------|
| Unauthenticated save / load / delete | `AuthenticationFailure` |
| Duplicate create or update of a missing record | `DatabaseFailure` |
| Hive exception | `HiveErrorMapper` → `DatabaseFailure` or `UnknownFailure` |
| Unsupported `formatVersion`, short ciphertext, wrong nonce/tag size | `CryptoFailure` |
| AES-GCM authentication failure (tamper, wrong key) | `VaultDecryptionFailure` from `CryptoService.decrypt` |
| Encrypt/decrypt unexpected crypto errors | `CryptoFailure` (passed through) |

Messages stay generic. Nonce, ciphertext, authentication tag, Vault Key, and library exception text are not copied into `AppFailure.message`.

---

## GetIt registrations

Still one composition root: [`injection_container.dart`](../../lib/core/di/injection_container.dart).

```text
initDependencies(HiveDatabase database)
        ↓
registerSingleton<HiveDatabase>
        ↓
registerLazySingleton<UserDataSource>         → HiveUserDataSource
        ↓
registerLazySingleton<VaultDataSource>        → HiveVaultDataSource   ← new
        ↓
registerLazySingleton<CryptoService>          → CryptoServiceImpl
        ↓
registerLazySingleton<KeyManagementService>   → KeyManagementServiceImpl
        ↓
registerLazySingleton<SessionService>         → SessionServiceImpl
        ↓
registerLazySingleton<AuthRepository>         → AuthRepositoryImpl(...)
        ↓
registerLazySingleton<VaultRepository>        → VaultRepositoryImpl(...)  ← new
```

`VaultRepositoryImpl` receives `VaultDataSource`, `CryptoService`, and `SessionService` through its constructor.

`main()` is unchanged: Hive initialize → `initDependencies` → `runApp`. Nothing in startup encrypts or creates a vault.

---

## Tests

Tests use a real temp Hive database, real `CryptoServiceImpl`, and real `SessionServiceImpl`. They do not mock AES.

| Test file | What it actually checks |
|-----------|-------------------------|
| [`test/core/database/hive_vault_data_source_test.dart`](../../test/core/database/hive_vault_data_source_test.dart) | create + find round trip; missing user → `null`; update ciphertext; duplicate create → `DatabaseFailure` without replacing the original; update missing → `DatabaseFailure`; delete one vault leaves another; delete does not remove `UserRecord`; closed box → `DatabaseFailure` without leaking Hive/path text |
| [`test/feature/vault/vault_repository_test.dart`](../../test/feature/vault/vault_repository_test.dart) | unauthenticated save/load/delete → `AuthenticationFailure`; save → Hive → load round-trips plaintext; persisted ciphertext does not contain plaintext; two saves use different nonces and keep one Hive key; persisted bytes reconstruct `EncryptedPayload` that decrypts; tampered ciphertext/tag and wrong Vault Key → `VaultDecryptionFailure`; short ciphertext / `formatVersion` 99 fail closed; missing record → `Success(null)`; second save updates; `deleteVault` leaves `UserRecord` and the session; repository works from `SessionService.vaultKey` with no Master Password |
| [`test/core/hive_database_test.dart`](../../test/core/hive_database_test.dart) | `initDependencies` also registers `VaultDataSource` and `VaultRepository` |

---

## Security considerations

1. **Vault Key comes only from `SessionService`.** No second derivation, no Master Password as AES key.
2. **AES-256-GCM only through `CryptoService`.** The repository does not call the cryptography package.
3. **Fresh nonce on every save**, generated inside `CryptoService.encrypt`.
4. **Option A is a persistence mapping**, not a change to the crypto API. `EncryptedPayload` still has a separate tag.
5. **Malformed records fail closed** before decrypt. Tampering fails as `VaultDecryptionFailure` with a generic message.
6. **Hive stores ciphertext, not plaintext.** Tests assert the distinctive plaintext bytes are absent from the stored blob.
7. **Delete is vault-only.** Account metadata and the in-memory Vault Key stay until auth/session code changes them.
8. **No logging of plaintext, keys, nonces, or ciphertext.**

---

## Explicit non-goals

This persistence foundation does **not** provide:

- `VaultData` / login / bank card / secure note / category models or CRUD
- An empty encrypted `VaultRecord` at registration
- Wiring GetX ViewModels or Bindings to `VaultRepository`
- Changes to Argon2id, AES-GCM parameters, `SecurityConstants`, `UserRecord`, `WrappedVaultKey`, or Hive adapters
- A UseCase / Domain / Interactor layer
- Session timeout, auto-lock, PIN, or biometric unlock
- Master Password change, account deletion, backup / restore
- A second DI file or GetIt lookups inside implementations

Feature screens still use in-memory GetX stores. They do not call `VaultRepository` yet.
