# Task 01 — Core Infrastructure

This note describes the **core infrastructure that is actually in the codebase**.

It is a learning reference and an implementation record. The source of truth is the Dart code and tests, not the architecture proposals.

Related code:

- [`lib/main.dart`](../../lib/main.dart)
- [`lib/core/database/`](../../lib/core/database/)
- [`lib/core/constants/database_constants.dart`](../../lib/core/constants/database_constants.dart)
- [`lib/core/exceptions/result.dart`](../../lib/core/exceptions/result.dart)
- [`lib/core/exceptions/app_failure.dart`](../../lib/core/exceptions/app_failure.dart)
- [`lib/core/di/injection_container.dart`](../../lib/core/di/injection_container.dart)
- [`test/core/`](../../test/core/)

---

## Purpose

Task 01 established the local storage and application-boundary foundations that later features depend on:

1. **Hive CE** as the only local database
2. A **clear database layer** so UI and ViewModels never talk to Hive
3. A shared **Result / AppFailure** contract for expected failures
4. A single **GetIt** composition root
5. A defined **startup order** before `runApp()`

It did **not** implement vault item CRUD, authentication, or account lifecycle. Those still live in the UI prototype (in-memory stores) or in later tasks.

---

## Current architecture and responsibilities

Keyva uses **MVVM**:

```text
View (Flutter widgets)
    ↓
ViewModel (GetX)
    ↓
Repository / Service          ← not used for vault persistence yet
    ↓
DataSource                    ← not implemented yet
    ↓
HiveDatabase → Hive CE
```

### What each tool does today

| Tool | Actual responsibility in this project |
|------|----------------------------------------|
| **GetX** | UI state, Controllers/ViewModels, navigation, route Bindings |
| **GetIt** | Composition root for infrastructure (`HiveDatabase`, and later crypto services) |
| **Hive CE** | On-device boxes for users, vaults, and app settings |

### Boundary that Task 01 created

Only the database layer imports Hive APIs:

- [`HiveDatabase`](../../lib/core/database/hive_database.dart) opens boxes and owns initialization
- [`HiveErrorMapper`](../../lib/core/database/hive_error_mapper.dart) converts Hive errors into `AppFailure`
- Generated adapters live next to those files

The rest of the app must not call `Hive.box(...)` directly.

### What the UI still does

Feature screens still use **GetX Bindings** and in-memory stores, for example:

- `LoginVaultStore`
- `BankCardVaultStore`
- `NoteVaultStore`

Those stores are **not** Hive DataSources. They were left in place on purpose. Core infrastructure is ready; vault features have not been migrated onto it yet.

---

## Hive CE database initialization

Hive is a lightweight key-value database. Data is stored in **boxes**. A box is like a named map that survives app restarts.

Initialization is one method for production and tests:

```dart
HiveDatabase.initialize({String? testDatabasePath})
```

Implemented in [`lib/core/database/hive_database.dart`](../../lib/core/database/hive_database.dart).

### Same flow, two storage locations

1. If `testDatabasePath` is set → `Hive.init(testDatabasePath)` (used by tests with a temp folder)
2. Otherwise → `Hive.initFlutter()` (used by `main()` on a real device)
3. Register type adapters **once** (`_adaptersRegistered` guard)
4. Open the three boxes
5. Ensure database schema version
6. Return a `HiveDatabase` instance that holds the open boxes

There is **no** separate test database class.

### Fail closed

If anything in that sequence fails:

1. The code attempts `Hive.close()`
2. The original error is mapped through `HiveErrorMapper`
3. An `AppFailure` is thrown
4. `runApp()` is **not** called with a half-ready database

“Fail closed” means: do not continue as if the vault is usable.

### Type adapters (how custom objects are stored)

Hive natively stores primitives (`String`, `int`, `DateTime`, `Uint8List`, `Duration`, …). Custom classes need a **TypeAdapter** that knows how to write and read each field.

The project uses Hive CE’s `GenerateAdapters` annotation in [`hive_adapters.dart`](../../lib/core/database/hive_adapters.dart). The model classes themselves have **no** `@HiveType` / `@HiveField` annotations. That keeps persistence models free of Hive imports.

Generated files (checked into source control):

| File | Role |
|------|------|
| `hive_adapters.g.dart` | Adapter classes (`UserRecordAdapter`, …) |
| `hive_registrar.g.dart` | `Hive.registerAdapters()` extension |
| `hive_adapters.g.yaml` | Stable type IDs and field indexes for future schema evolution |

Assigned type IDs:

| Type | typeId |
|------|--------|
| `UserRecord` | 0 |
| `KdfParameters` | 1 |
| `WrappedVaultKey` | 2 |
| `SecuritySettings` | 3 |
| `VaultRecord` | 4 |

---

## Database boxes and persistence models

Box names are centralized in [`database_constants.dart`](../../lib/core/constants/database_constants.dart). They are not hard-coded elsewhere.

| Constant | Box name | Dart type | Contents |
|----------|----------|-----------|----------|
| `HiveBoxNames.users` | `users` | `Box<UserRecord>` | One record per local account |
| `HiveBoxNames.vaults` | `vaults` | `Box<VaultRecord>` | One encrypted vault blob per user |
| `HiveBoxNames.appSettings` | `app_settings` | `Box<dynamic>` | Database version (key/value) |

`HiveDatabase` exposes the open boxes as `users`, `vaults`, and `appSettings` so a future DataSource can use them without calling Hive globally.

### `UserRecord`

Account metadata for one local user. It does **not** contain a master password or a plaintext vault key.

| Field | Type | Meaning |
|-------|------|---------|
| `id` | `String` | Stable account id |
| `username` | `String` | Display name only |
| `createdAt` / `updatedAt` | `DateTime` | Timestamps |
| `kdfSalt` | `Uint8List` | Salt bytes to persist (not generated in this layer) |
| `kdfParameters` | `KdfParameters` | Stored KDF settings for that account |
| `wrappedVaultKey` | `WrappedVaultKey` | Encrypted vault key material |
| `securitySettings` | `SecuritySettings` | Non-secret preferences |

### `KdfParameters`

Storage metadata only: `algorithm`, `memoryCost`, `timeCost`, `parallelism`, `outputLength`.

This class does **not** run Argon2 or derive keys. It only remembers numbers/strings so a later crypto layer can reproduce derivation.

### `WrappedVaultKey`

Independent wrap payload:

- `version`
- `nonce`
- `ciphertext`
- `authenticationTag` (separate field)

### `SecuritySettings`

Non-secret flags: `biometricEnabled`, `pinEnabled`, `autoLockTimeout` (`Duration`), `preventScreenshots`.

This is **not** the UI type `SecuritySettingsUiState` in the settings feature. They are separate.

### `VaultRecord` (Option A)

Encrypted vault blob for one user:

| Field | Type | Meaning |
|-------|------|---------|
| `userId` | `String` | Owner (`UserRecord.id`) |
| `formatVersion` | `int` | Version of the encrypted vault payload |
| `nonce` | `Uint8List` | AES-GCM nonce |
| `ciphertext` | `Uint8List` | Ciphertext **including** the authentication tag |
| `updatedAt` | `DateTime` | Last change |

There is **no** `authenticationTag` field on `VaultRecord`. The tag is embedded in `ciphertext` (Option A). That is different from `WrappedVaultKey`, which stores the tag separately.

Binary fields use `Uint8List` so Hive can store them as raw bytes.

---

## Database schema versioning

This is the **database** schema version, not the vault ciphertext format version.

- Key: `HiveSettingsKeys.databaseVersion` (`databaseVersion`)
- Current value: `DatabaseConfig.currentVersion` (`1`)

On initialize ([`_ensureDatabaseVersion`](../../lib/core/database/hive_database.dart)):

| Stored value | Behavior |
|--------------|----------|
| missing (`null`) | Write `1` (fresh install) |
| `int` equal to `1` | Continue |
| anything else (wrong type, or another number) | Throw `DatabaseFailure` |

There is **no** migration from v1 to v2. An unknown version fails closed instead of rewriting or discarding data.

---

## `Result<T>` and `AppFailure`

Implemented in:

- [`lib/core/exceptions/result.dart`](../../lib/core/exceptions/result.dart)
- [`lib/core/exceptions/app_failure.dart`](../../lib/core/exceptions/app_failure.dart)

### Why `Result` exists

Some failures are **expected** (wrong password, corrupt database, unsupported schema). Throwing those through the UI as raw exceptions would leak Hive/crypto details.

`Result<T>` is a sealed type with two outcomes:

- `Success<T>` — holds `data`
- `FailureResult<T>` — holds an `AppFailure`

Helpers: `isSuccess`, `isFailure`.

Repositories and services that can fail are expected to return `Result<T>` rather than leaking platform exceptions. Task 01 defined the types; vault repositories that use them are not implemented yet.

### `AppFailure`

All application-level failures share a generic `message`. The message is **not** the original Hive/crypto exception text.

Types currently in code:

| Type | Default message |
|------|-----------------|
| `DatabaseFailure` | `Database operation failed` |
| `UnknownFailure` | `An unexpected error occurred` |
| `CryptoFailure` | `Cryptographic operation failed` |
| `VaultDecryptionFailure` | `Unable to decrypt vault data` |

`DatabaseFailure` and `UnknownFailure` are the ones the database layer uses. The crypto-related subtypes exist on the same sealed hierarchy so later layers share one failure model.

There are still **no** auth/backup/session/validation failure types.

---

## Database error mapping

[`HiveErrorMapper.map`](../../lib/core/database/hive_error_mapper.dart) is the database error boundary:

| Incoming value | Result |
|----------------|--------|
| already an `AppFailure` | returned unchanged |
| `HiveError` | `DatabaseFailure` with the generic message |
| anything else | `UnknownFailure` with the generic message |

The mapper **does not** copy `HiveError.message` into `AppFailure.message`. Paths, box names, or payload bytes must not appear in failures (or logs).

`HiveDatabase.initialize` uses this mapper in its `catch` block.

This is not a global app-wide error handler. It only translates database-layer errors.

---

## GetIt dependency injection

Single composition root: [`lib/core/di/injection_container.dart`](../../lib/core/di/injection_container.dart)

```text
getIt = GetIt.instance
initDependencies(HiveDatabase database)
```

`main()` creates the database first, then calls `initDependencies(database)`.

`HiveDatabase` is registered as a **singleton** (the instance that was just initialized).

The same method also registers cryptographic services (`CryptoService`, `KeyManagementService`) as lazy singletons. Those services are not part of the Hive database layer; they share this file because the project allows **one** GetIt container.

Implementations are not supposed to call `GetIt` internally. GetIt belongs at the composition root. ViewModels still receive many UI dependencies through GetX Bindings — that split remains.

The empty stub `core_dependencies.dart` was removed so there is only one DI entry point. [`global_bindigns.dart`](../../lib/core/di/global_bindigns.dart) is unused leftover and was not part of this infrastructure.

---

## Application startup flow

[`lib/main.dart`](../../lib/main.dart):

```text
WidgetsFlutterBinding.ensureInitialized()
        ↓
HiveDatabase.initialize()          // Hive.initFlutter, adapters, boxes, version
        ↓
initDependencies(database)         // GetIt
        ↓
runApp(KeyvaApp)
```

`KeyvaApp` is unchanged in behavior: `GetMaterialApp`, Persian locale, existing routes, splash as `initialRoute`.

If `initialize()` throws, Flutter never reaches `runApp()` with open-but-invalid storage.

Tests do **not** go through `main()`. They call `HiveDatabase.initialize(testDatabasePath: ...)` themselves.

---

## What is persisted vs what is not

### Persisted (Hive)

These **can** be stored once later code writes them:

- `UserRecord` (including salt, KDF parameters, wrapped key, security preferences)
- `VaultRecord` (nonce + ciphertext blob, not plaintext logins/cards/notes)
- `databaseVersion` in `app_settings`

After a normal first launch, the only written value is **database version `1`**. The `users` and `vaults` boxes are opened empty. There is no seed account and no vault write in this layer.

### Not persisted as plaintext Hive records

- Master password
- Plaintext vault key
- PIN secret material
- `VaultData` / login / bank card / secure note / category items as their own boxes

Those vault items are **not** Hive models in `lib/core/database/models/`. If they exist in the app today, they live in memory in the feature stores.

`KdfParameters` and `WrappedVaultKey` are **shapes for storage**. This task does not generate salts, wrap keys, or encrypt vaults.

---

## Important architectural decisions

1. **Reuse existing folders.** Failures live in `lib/core/exceptions/` (already in the project), not a new `core/errors/` package.
2. **One initialize method** with optional `testDatabasePath` instead of a test-only database.
3. **GenerateAdapters** so persistence models stay Hive-free.
4. **`VaultRecord` Option A** — authentication tag inside `ciphertext`. **`WrappedVaultKey`** keeps a separate `authenticationTag`.
5. **`Uint8List` for binary fields** — Hive-native and binary-safe.
6. **No silent migration.** Unknown `databaseVersion` → `DatabaseFailure`.
7. **Generic failure messages** — never rethrow Hive text.
8. **Do not migrate GetX vault stores in this task.** Hive is available; UI still uses in-memory stores.
9. **`SecuritySettings` (Hive)** and **`SecuritySettingsUiState` (settings UI)** are different types and are not wired together.
10. **`app_settings` is an untyped box** because it currently stores a single integer version, not a typed record.

---

## Tests and what they verify

| Test file | What it actually checks |
|-----------|-------------------------|
| [`test/core/result_test.dart`](../../test/core/result_test.dart) | `Success` holds data and reports `isSuccess`; `FailureResult` holds `AppFailure` and reports `isFailure` |
| [`test/core/hive_error_mapper_test.dart`](../../test/core/hive_error_mapper_test.dart) | `HiveError` → `DatabaseFailure` without leaking the original message; existing `AppFailure` passed through; other errors → `UnknownFailure` without leaking details |
| [`test/core/hive_database_test.dart`](../../test/core/hive_database_test.dart) | `initialize(testDatabasePath:)` opens all three boxes and writes version `1`; version `99` then re-init throws `DatabaseFailure`; `initDependencies` registers `HiveDatabase` (and the crypto services that share that method) |

Tests use a temp directory and the **same** `HiveDatabase.initialize` as production. They close Hive in `tearDown`.

`test/widget_test.dart` is an old Flutter counter smoke test. It does not validate Keyva or Hive. `test/bank_card_seed_pan_test.dart` is unrelated to this infrastructure.

---

## What is not implemented yet

The following are **not** provided by this core infrastructure (and still are not how the vault UI works):

- Hive DataSources (`HiveUserDataSource`, `HiveVaultDataSource`, …)
- Repositories that create/load/delete accounts or vaults
- Account creation, login, unlock, logout, account switching
- Writing `UserRecord` / `VaultRecord` as part of a user flow
- Session management
- PIN / biometric unlock
- Backup and restore
- Schema migrations (`1` → `2`)
- Moving feature vault stores off GetX / RAM onto Hive
- Feature-specific failures such as `AuthenticationFailure`, `BackupFailure`, `RestoreFailure`, `SessionFailure`, `ValidationFailure`

Cryptographic **services** exist in `lib/core/crypto/` and are registered from `initDependencies`. They are outside the scope of this database-infrastructure note. This layer still does not encrypt a vault or create an account.

Empty leftovers that were not part of the working infrastructure:

- [`lib/core/exceptions/app_exceptions.dart`](../../lib/core/exceptions/app_exceptions.dart)
- [`lib/core/di/global_bindigns.dart`](../../lib/core/di/global_bindigns.dart)
