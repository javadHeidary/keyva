# Hive CE Local Storage

## 1. Overview

Keyva persists structured local data with Hive CE (`hive_ce` / `hive_ce_flutter`). Three boxes hold user metadata, encrypted vault records, and app settings. Hive boxes are **not** opened with Hive’s built-in box encryption. Vault plaintext is encrypted at the repository layer before a `VaultRecord` is written.

## 2. Purpose

Hive CE provides an offline, file-based store with generated TypeAdapters for `UserRecord`, `VaultRecord`, and nested types. It is the only database used by the app.

## 3. Architecture

| Layer | Role |
| --- | --- |
| Presentation / ViewModel | Must not touch Hive |
| Repository | `AuthRepositoryImpl`, `VaultRepositoryImpl`, `SettingsRepositoryImpl` |
| Data Source | `HiveUserDataSource`, `HiveVaultDataSource` |
| Local Storage | `HiveDatabase` wraps three `Box` instances |
| Encryption | `VaultRepositoryImpl` + `EncryptedBlobStoreImpl` (not Hive) |
| Domain | Not present |

Pattern: ViewModel → Repository / Service → DataSource → Hive.

## 4. Implementation Flow

```text
main()
    ↓
HiveDatabase.initialize()
    ↓
Hive.initFlutter()  (or Hive.init(path) in tests)
    ↓
Hive.registerAdapters()  (once)
    ↓
openBox users / vaults / app_settings
    ↓
_ensureDatabaseVersion (must be 1 or missing → write 1)
    ↓
initDependencies(database)
```

Per-operation:

```text
Repository / Service
    ↓
UserDataSource or VaultDataSource
    ↓
Box.put / get / delete
    ↓
catch → HiveErrorMapper → FailureResult
```

## 5. Important Classes & Files

| Class / File | Responsibility | Relationship |
| --- | --- | --- |
| `HiveDatabase` — `lib/core/database/hive_database.dart` | Opens boxes, version check, `close()` | Injected as GetIt singleton |
| `HiveBoxNames` / `HiveSettingsKeys` / `DatabaseConfig` — `lib/core/constants/database_constants.dart` | Box names and settings keys | Used by database, limiter, pause store, settings |
| `UserDataSource` / `HiveUserDataSource` | CRUD for `UserRecord` keyed by user id | Used by `AuthRepositoryImpl` |
| `VaultDataSource` / `HiveVaultDataSource` | CRUD for `VaultRecord` keyed by `userId` | Used by `VaultRepositoryImpl` and account delete |
| `UserRecord` | Username, KDF salt/params, wrapped Vault Key, `SecuritySettings`, avatar | Users box |
| `VaultRecord` | `formatVersion`, `nonce`, `ciphertext` (ciphertext + trailing GCM tag), `updatedAt` | Vaults box |
| `KdfParameters`, `WrappedVaultKey`, `SecuritySettings` | Nested Hive types | Stored inside `UserRecord` |
| `hive_adapters.dart` + generated `hive_adapters.g.dart` / `hive_registrar.g.dart` | `@GenerateAdapters` for the five types | Registered via `Hive.registerAdapters()` |
| `HiveErrorMapper` | Exception → `DatabaseFailure` / `UnknownFailure` | Data sources and initialize |
| `HiveAutoLockPauseStore` | Reads/writes `lastBackgroundedAt` in `app_settings` | Auto lock |

Boxes:

- `users` — `Box<UserRecord>`
- `vaults` — `Box<VaultRecord>`
- `app_settings` — `Box<dynamic>`

`app_settings` keys include `databaseVersion`, `activeUserId`, `themePreference`, `lastBackgroundedAt`, `onboardingCompleted`, `itemTypeGuide:<type>`, PIN/biometric attempt and lockout timestamps (`pinFailedAttempts:$userId`, etc.).

Image bytes are **not** in Hive. They are files under the app support directory via `EncryptedBlobStoreImpl`.

## 6. Data Flow

**Persisted (Hive):**

- User metadata and wrapped Vault Key (`UserRecord`).
- Encrypted vault JSON blob (`VaultRecord.ciphertext`).
- Non-secret app flags (theme, onboarding, active user id, lockout counters, last background timestamp).

**Not persisted in Hive:**

- Master Password
- PIN
- Plaintext Vault Key
- Decrypted `VaultData`
- Image plaintext (encrypted files beside Hive)

**Where encryption happens:** `VaultRepositoryImpl.saveVaultData` encrypts with the in-memory Vault Key, then writes Hive. `HiveVaultDataSource` only stores the already-encrypted `VaultRecord`.

`UserRecord.kdfSalt` and `wrappedVaultKey` are stored in the users box without an additional Hive cipher. The Vault Key inside `wrappedVaultKey` is AES-GCM ciphertext.

## 7. Security Considerations

- No Hive AES box key is configured in `HiveDatabase.initialize`.
- Duplicate `create` for an existing user/vault id returns `DatabaseFailure` (fail closed on collision).
- Database version must equal `DatabaseConfig.currentVersion` (`1`). Any other stored version throws `DatabaseFailure` during initialize.
- Lockout counters live in `app_settings` as integers, not in secure storage.
- `HiveAutoLockPauseStore` swallows read/write errors (empty `catch`).

## 8. Error Handling

Data source methods wrap Hive calls in `try/catch` and return `FailureResult(HiveErrorMapper.map(error))`.

`HiveDatabase.initialize` throws the mapped failure after attempting `Hive.close()`.

Missing records return `Success(null)` from `findById` / `findByUserId`, not a failure.

## 9. Edge Cases

- Adapters register only once (`_adaptersRegistered`) so tests that call initialize repeatedly do not double-register.
- `listIds` stringifies Hive keys.
- `VaultDataSource.update` fails if the key does not exist; `VaultRepositoryImpl.saveVaultData` creates when absent and updates when present.
- Account deletion removes the vault row then the user row and verifies both are gone (`_verifyAccountDeleted`).

## 10. Testing

- `test/core/hive_database_test.dart`
- `test/core/database/hive_user_data_source_test.dart`
- `test/core/database/hive_vault_data_source_test.dart`
- `test/core/hive_error_mapper_test.dart`

## 11. Technical Decisions

- Hive CE with generated adapters rather than a SQL database, consistent with offline-first local storage.
- Application-layer AES-GCM for vault payloads instead of Hive encryption, so encryption uses the session Vault Key (see [Vault Encryption](03_vault_encryption_aes_gcm.md)).
- Typed boxes for users and vaults; untyped `app_settings` for flags and counters.
- Single-record-per-user vault: one `VaultRecord` keyed by `userId`, not one Hive object per login item.

## 12. Limitations / Notes

- There is no migration path beyond “version must be 1”.
- `SettingsRepositoryImpl` writes theme/onboarding/guides to `app_settings` directly (repository talking to `HiveDatabase`, not a dedicated settings data source).
- Hive file locations follow `Hive.initFlutter()` defaults; the exact OS path is not encoded in application code except the optional `testDatabasePath`.

## 13. Summary

Hive CE stores three boxes: users (including wrapped Vault Key and KDF metadata), vaults (AES-GCM ciphertext + nonce), and app settings. Data sources isolate box access. Encryption of vault contents is performed by `VaultRepositoryImpl`, not by Hive. Images use `EncryptedBlobStore`, not Hive.

Related: [Vault Key Management](04_vault_key_management.md), [Vault Lifecycle](17_vault_process_lifecycle.md), [Error Handling](15_error_handling_result_pattern.md).
