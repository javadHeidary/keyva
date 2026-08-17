# Task 03 — Account Lifecycle and Authentication Foundation

This note describes the **account registration, Master Password unlock, user persistence, and in-memory session layer that is actually in the codebase**.

It is a learning reference and an implementation record. The source of truth is the Dart code and tests, not the architecture proposals.

Related code:

- [`lib/feature/auth/repository/`](../../lib/feature/auth/repository/)
- [`lib/core/database/user_data_source.dart`](../../lib/core/database/user_data_source.dart)
- [`lib/core/database/hive_user_data_source.dart`](../../lib/core/database/hive_user_data_source.dart)
- [`lib/core/session/`](../../lib/core/session/)
- [`lib/core/exceptions/app_failure.dart`](../../lib/core/exceptions/app_failure.dart)
- [`lib/core/di/injection_container.dart`](../../lib/core/di/injection_container.dart)
- [`test/core/database/hive_user_data_source_test.dart`](../../test/core/database/hive_user_data_source_test.dart)
- [`test/core/session/session_service_test.dart`](../../test/core/session/session_service_test.dart)
- [`test/feature/auth/auth_repository_test.dart`](../../test/feature/auth/auth_repository_test.dart)

---

## Purpose

Task 03 built the account lifecycle foundation that later vault and UI features will call.

In simple terms, this layer answers:

1. How do we create a local account from a username and Master Password without storing the password?
2. How do we prove a Master Password is correct later (by unwrapping the Vault Key)?
3. How do we persist account metadata without letting Views or ViewModels talk to Hive?
4. How do we keep an unlocked Vault Key in memory for future vault work, and drop it on logout?

It reuses Task 01 (Hive, `UserRecord`, `Result` / `AppFailure`, GetIt) and Task 02 (`CryptoService`, `KeyManagementService`, `SecurityConstants`). It does **not** encrypt a vault, change crypto parameters, or wire the existing login/register screens.

---

## Current architecture and responsibilities

Keyva still uses **MVVM**. There is no UseCase / Domain / Interactor layer. `AuthRepository` is the application service that ViewModels will call later.

```text
View (Flutter widgets)            ← still the prototype UI
    ↓
ViewModel (GetX)                  ← still fake-delay login/register
    ↓
AuthRepository                    ← new
    ↓
UserDataSource + CryptoService + KeyManagementService + SessionService
    ↓
HiveUserDataSource → HiveDatabase.users
```

### What each new piece does

| Type | Actual responsibility |
|------|------------------------|
| **`UserDataSource`** | Persist / load / update `UserRecord` only. No crypto. |
| **`HiveUserDataSource`** | Talks to `HiveDatabase.users`. Maps Hive errors through `HiveErrorMapper`. |
| **`AuthRepository`** | Registration, unlock, logout. Coordinates crypto + persistence + session. |
| **`SessionService`** | Holds the unlocked user snapshot and Vault Key in memory. |
| **`AuthenticationFailure`** | Generic unlock failure. Used for missing user, wrong password, and corrupt wrap. |

### Boundary that Task 03 created

- Views and ViewModels still do not access Hive or crypto.
- Only `HiveUserDataSource` writes the `users` box.
- Only `AuthRepositoryImpl` derives keys, wraps/unwraps, and creates sessions.
- Implementations do not look up `GetIt` themselves. Constructor injection only.

### What the UI still does

[`RegisterController`](../../lib/feature/auth/view_model/auth_register_viewmodel.dart) and [`LoginController`](../../lib/feature/auth/view_model/auth_login_viewmodel.dart) still wait and navigate. GetX Bindings were not changed. The prototype remains functional; it does not call `AuthRepository` yet.

---

## Registration flow (actual)

```text
username + Master Password
        ↓
Generate UUID v4 User ID (retry if the id already exists)
        ↓
generateSalt()                  → 16 random bytes
        ↓
defaultKdfParameters()          → Argon2id 64 MB / 3 / 4 / 32
        ↓
CryptoService.deriveKey(...)    → Derived Key
        ↓
generateVaultKey()              → 32 random bytes
        ↓
wrapVaultKey(...)               → WrappedVaultKey
        ↓
Zero Derived Key and plaintext Vault Key in the local buffers
        ↓
Create UserRecord
        ↓
UserDataSource.create
```

Implemented in [`AuthRepositoryImpl.createAccount`](../../lib/feature/auth/repository/auth_repository_impl.dart).

Important facts about this flow:

- Username is stored as a display name. It is not the account identity.
- User ID is a UUID v4 string from `CryptoService.generateSecureBytes(16)` with RFC 4122 version/variant bits set. There is no `uuid` package.
- Master Password is a method argument only. It is never written to Hive.
- Derived Key and plaintext Vault Key are overwritten with zeros after wrap. They are not persisted.
- Registration does **not** create a session. The caller must `authenticate` later.
- Registration does **not** create a `VaultRecord`. That is deferred (Task 03 explicitly skipped vault CRUD).
- Crypto failures during derive/wrap stay `CryptoFailure`. Persist failures stay `DatabaseFailure`.

Default security preferences on a new account come from `SecuritySettings.initial()`:

- `biometricEnabled = false`
- `pinEnabled = false`
- `autoLockTimeout = 1 minute`
- `preventScreenshots = false`

Those flags are stored. PIN, biometrics, and auto-lock are not implemented here.

---

## Authentication / unlock flow (actual)

```text
User ID + Master Password
        ↓
UserDataSource.findById
        ↓
stored salt + stored KdfParameters
        ↓
CryptoService.deriveKey
        ↓
KeyManagementService.unwrapVaultKey
        ↓
SessionService.setAuthenticated(userId, username, vaultKey)
```

Successful unwrap is the proof that the Master Password is correct. There is no separate password hash.

If anything in this path fails (unknown user, Hive error on load, KDF failure, unwrap failure, tampered wrap):

1. `SessionService.clear()` runs (so a previous session cannot linger)
2. The method returns `AuthenticationFailure` with message `Unable to unlock your vault.`

`authenticate` never returns `DatabaseFailure`, `CryptoFailure`, or `VaultDecryptionFailure`. Callers cannot tell from the failure type whether the user exists, the password was wrong, or the wrapped key was corrupt.

The Derived Key buffer is zeroed after unwrap, whether unwrap succeeded or not.

---

## Logout flow (actual)

```text
AuthRepository.logout
        ↓
SessionService.clear
        ↓
overwrite Vault Key bytes with zeros
        ↓
drop session snapshot
```

Logout does **not**:

- delete the `UserRecord`
- close or clear Hive boxes
- change the wrapped key
- create a `VaultRecord`

After logout, `isAuthenticated` is false and `vaultKey` is `null`. Authenticated work that reads `SessionService.current` / `vaultKey` cannot use the previous session.

Dart does not guarantee memory zeroization. `fillRange(0, ...)` is a best-effort overwrite of the `Uint8List` we still hold.

---

## User persistence

Interface: [`user_data_source.dart`](../../lib/core/database/user_data_source.dart)  
Implementation: [`hive_user_data_source.dart`](../../lib/core/database/hive_user_data_source.dart)

| Method | Behavior |
|--------|----------|
| `create` | `put(user.id, user)` if the key is free; otherwise `DatabaseFailure` |
| `findById` | `Success(record)` or `Success(null)` if missing |
| `exists` | `containsKey` |
| `update` | `put` if the key exists; otherwise `DatabaseFailure` |

The Hive box key is `UserRecord.id`. Unexpected Hive errors go through `HiveErrorMapper` (`DatabaseFailure` / `UnknownFailure`). The mapper still does not copy Hive exception text.

This DataSource never opens the `vaults` box.

`UserRecord` fields were not changed. Hive adapters were not regenerated.

---

## Session

Files under [`lib/core/session/`](../../lib/core/session/):

- `AuthenticatedSession` — `userId` + `username` only
- `SessionService` / `SessionServiceImpl`

```text
SessionService
├── current        → AuthenticatedSession? (non-sensitive)
├── isAuthenticated
├── vaultKey       → Uint8List? (in memory only)
├── setAuthenticated(...)
└── clear()
```

Default state is locked: `current == null`, `isAuthenticated == false`, `vaultKey == null`.

The Vault Key is available to future vault code through `SessionService.vaultKey`. It is not a field on `AuthenticatedSession`, so a caller that only needs “who is unlocked?” does not have to touch key material.

`setAuthenticated` clears any previous key before storing the new one.

Nothing in this layer writes session state to Hive, SharedPreferences, or secure storage.

There is no session timeout, app lock, PIN, or biometric unlock.

---

## Failures

Added on the existing sealed `AppFailure` hierarchy:

| Type | Default message | Used when |
|------|-----------------|-----------|
| `AuthenticationFailure` | `Unable to unlock your vault.` | Any failed `authenticate` path |

Not added in this task: `ValidationFailure`, `NotFoundFailure`, `SessionFailure`, `BackupFailure`, `RestoreFailure`, `SecurityFailure`.

Registration still uses the older types: `CryptoFailure` for derive/wrap, `DatabaseFailure` for persist. Unlock always collapses to `AuthenticationFailure`.

---

## GetIt dependency injection

Still one composition root: [`injection_container.dart`](../../lib/core/di/injection_container.dart).

```text
initDependencies(HiveDatabase database)
        ↓
registerSingleton<HiveDatabase>
        ↓
registerLazySingleton<UserDataSource>         → HiveUserDataSource
        ↓
registerLazySingleton<CryptoService>          → CryptoServiceImpl
        ↓
registerLazySingleton<KeyManagementService>   → KeyManagementServiceImpl
        ↓
registerLazySingleton<SessionService>         → SessionServiceImpl
        ↓
registerLazySingleton<AuthRepository>         → AuthRepositoryImpl(...)
```

`AuthRepositoryImpl` receives `UserDataSource`, `CryptoService`, `KeyManagementService`, and `SessionService` through its constructor.

`main()` is unchanged: Hive initialize → `initDependencies` → `runApp`. Nothing in startup creates an account or unlocks a session.

---

## What is persisted vs kept only in memory

### Persisted (Hive `users` box)

- `UserRecord.id` (UUID v4)
- `username`
- timestamps
- KDF salt (16 bytes, not secret)
- `KdfParameters` actually used for that account
- `WrappedVaultKey` (version, nonce, ciphertext, authentication tag)
- `SecuritySettings` (non-secret preferences)

After a normal first launch with no registration, the `users` box is still empty.

### Never persisted by this design

| Value | Where it exists |
|--------|------------------|
| Master Password | `createAccount` / `authenticate` argument only |
| Derived Key | Temporary `Uint8List` during derive/wrap/unwrap; then overwritten |
| Plaintext Vault Key | Returned by unwrap into `SessionService`; overwritten on `clear()` |
| Session snapshot | RAM only |

---

## Important implementation decisions

1. **No UseCase layer.** Architecture forbids it. `AuthRepository` is the application flow.
2. **No `VaultRecord` on register.** Architecture wants User + Vault atomically. This task’s scope forbids vault CRUD, so a newly created user has no vault blob yet.
3. **No session on register.** Unlock is a separate call. Auto-login after registration is left for UI wiring.
4. **Wrap/unwrap go through `KeyManagementService`**, matching Task 02, not through `CryptoService` directly.
5. **UUID v4 from the existing CSPRNG**, not a new dependency.
6. **Same `AuthenticationFailure` for every unlock miss.** That avoids user-exists / wrong-password oracles.
7. **Failed unlock clears any existing session.** Fail closed.
8. **Best-effort zeroing of key buffers.** Documented as not guaranteed Dart memory wiping.
9. **Username policy stays in the UI.** The repository stores whatever display string it is given. Persian-character rules are not enforced here.
10. **Existing GetX auth screens were left as stubs** so the prototype still navigates.

---

## Tests and what they verify

KDF cases use production Argon2id parameters (64 MB) and a 2-minute timeout, same as Task 02.

| Test file | What it actually checks |
|-----------|-------------------------|
| [`test/core/database/hive_user_data_source_test.dart`](../../test/core/database/hive_user_data_source_test.dart) | create + findById round trip; exists false then true; update username; duplicate id → `DatabaseFailure` without replacing the original; update missing id → `DatabaseFailure`; unknown id → `null` |
| [`test/core/session/session_service_test.dart`](../../test/core/session/session_service_test.dart) | default locked; `setAuthenticated` stores user id / username / vault key; `clear` drops session and overwrites the vault-key bytes with zeros |
| [`test/feature/auth/auth_repository_test.dart`](../../test/feature/auth/auth_repository_test.dart) | register stores UUID v4, 16-byte salt, production KDF fields, wrapped key; no session after register; password and derived key are not in the persisted record; two accounts get different ids and salts; correct password unlocks and creates a session whose vault key is not the ciphertext; wrong password / unknown id / tampered wrap → `AuthenticationFailure` and no session; failed unlock clears a previous session; logout zeros the key and leaves the `UserRecord` in Hive |
| [`test/core/hive_database_test.dart`](../../test/core/hive_database_test.dart) | `initDependencies` also registers `UserDataSource`, `SessionService`, and `AuthRepository` |

---

## What is not implemented yet

This account/auth foundation does **not** provide:

- Vault CRUD or an empty encrypted `VaultRecord` at registration
- Login item / bank card / secure note / category persistence
- Wiring GetX login/register ViewModels to `AuthRepository`
- Account selection UI (login still only has a password field)
- Session timeout, manual lock, or auto-lock
- PIN or biometric unlock
- Master Password change
- Account deletion or switching
- Backup / restore
- Username Persian validation inside the repository
- Rate limiting of Master Password attempts
- Running Argon2id on a background isolate (still on the calling isolate)

Feature screens still use in-memory GetX stores. They do not call `AuthRepository` or `SessionService` yet.
