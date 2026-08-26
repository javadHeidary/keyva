# Argon2id Key Derivation

## 1. Overview

Keyva derives 32-byte keys from user-supplied secrets (Master Password, PIN, or Backup Password) using Argon2id via `package:cryptography`. The same `CryptoService.deriveKey` entry point is used for all three secrets. Parameters and salt are stored next to the wrapped key they protect.

## 2. Purpose

A KDF turns a human-chosen password into a cryptographic key without storing the password. Argon2id is used so that deriving a key is memory-hard and slow enough to hinder offline guessing against a stolen `UserRecord` or `.keyva` file.

## 3. Architecture

| Layer | Role |
| --- | --- |
| ViewModel | Collects Master Password / PIN / backup password; does not call KDF |
| Repository / Service | `AuthRepositoryImpl`, `PinServiceImpl`, `BackupServiceImpl` call `CryptoService.deriveKey` |
| Core / Security | `CryptoServiceImpl.deriveKey` constructs `Argon2id` |
| Local Storage | `UserRecord.kdfSalt` + `kdfParameters`; PIN material JSON; backup envelope |
| Domain | Not present |

There is no separate KDF service class. Derivation is a method on `CryptoService`.

## 4. Implementation Flow

```text
Secret string (master password, PIN, or backup password)
    ↓
CryptoService.deriveKey(masterPassword, salt, parameters)
    ↓
Validate algorithm == "Argon2id" and all costs > 0 and salt non-empty
    ↓
Argon2id(memory, iterations, parallelism, hashLength).deriveKeyFromPassword
    ↓
secretKey.extractBytes() → Uint8List (32 bytes)
    ↓
Caller uses derived key (wrap/unwrap or encrypt backup), then fillRange(0, length, 0)
```

Account creation (`AuthRepositoryImpl.createAccount`):

```text
generateSalt() (16 bytes)
    ↓
defaultKdfParameters()
    ↓
deriveKey(masterPassword, salt, parameters)
    ↓
wrapVaultKey(vaultKey, derivedKey)
    ↓
zero derivedKey
    ↓
persist UserRecord { kdfSalt, kdfParameters, wrappedVaultKey }
```

Unlock uses the **stored** salt and parameters from `UserRecord`, not newly generated ones.

## 5. Important Classes & Files

| Class / File | Responsibility | Relationship |
| --- | --- | --- |
| `CryptoService.deriveKey` — `lib/core/crypto/crypto_service.dart` | Interface | Implemented by `CryptoServiceImpl` |
| `CryptoServiceImpl` — `lib/core/crypto/crypto_service_impl.dart` | Argon2id derivation | Uses `package:cryptography` `Argon2id` |
| `KdfParameters` — `lib/core/database/models/kdf_parameters.dart` | `algorithm`, `memoryCost`, `timeCost`, `parallelism`, `outputLength` | Stored on `UserRecord` and in backup/PIN JSON |
| `KeyManagementService.defaultKdfParameters` / `generateSalt` | Supplies defaults and 16-byte salt | `KeyManagementServiceImpl` |
| `SecurityConstants` — `lib/core/constants/security_constants.dart` | Default KDF numbers | Source of production parameters |
| `WrappedKeyCodec.kdfToJson` / `kdfFromJson` | Serializes KDF params for PIN material | `lib/core/security/wrapped_key_codec.dart` |

Default parameters (`SecurityConstants`):

- `kdfAlgorithm`: `'Argon2id'`
- `kdfMemoryCost`: `65536`
- `kdfTimeCost`: `3`
- `kdfParallelism`: `4`
- `kdfOutputLength`: `32`
- `saltLength`: `16`

`CryptoServiceImpl` maps `parameters.memoryCost` → Argon2 `memory`, `timeCost` → `iterations`, `parallelism` → `parallelism`, `outputLength` → `hashLength`. The password argument is named `masterPassword` on the interface even when the secret is a PIN or backup password.

## 6. Data Flow

| Data | Where it exists | Lifetime |
| --- | --- | --- |
| Master Password / PIN / backup password | Memory in ViewModel controllers and repository call stack | Cleared from text fields in `finally` on register/login; not persisted |
| Salt | Generated, then stored (`UserRecord.kdfSalt`, PIN JSON, backup envelope) | Persisted |
| `KdfParameters` | Same places as salt | Persisted |
| Derived Key | Memory only | Zeroed with `fillRange` after wrap/unwrap in auth, PIN, backup, and master-password change |

The Master Password is never written to Hive or secure storage.

PIN derivation uses a **separate** salt stored in flutter_secure_storage PIN material, not `UserRecord.kdfSalt`.

Backup derivation uses salt stored inside the `.keyva` envelope.

## 7. Security Considerations

- Algorithm string must equal `SecurityConstants.kdfAlgorithm` (`Argon2id`); otherwise `deriveKey` returns `CryptoFailure` without running Argon2.
- Zero or negative costs, or empty salt, fail closed (`CryptoFailure`).
- Callers zero the derived key after use in account create, authenticate, change password, PIN wrap/unwrap, and backup encrypt/decrypt.
- There is **no** attempt limiter on Master Password KDF. Rate limiting exists only for PIN and biometric (`UnlockAttemptLimiter`).
- `changeMasterPassword` generates a **new** salt and `defaultKdfParameters()` then re-derives. It does not keep the old salt.

## 8. Error Handling

Failures become `FailureResult(CryptoFailure())` or `CryptoErrorMapper.map(error)` on thrown exceptions.

`AuthRepositoryImpl.authenticate` maps any derive/unwrap failure to `AuthenticationFailure` via `_authenticationFailed()`.

`PinServiceImpl.unwrapVaultKey` records a PIN failure and returns `AuthenticationFailure`.

`BackupServiceImpl.decryptBackup` maps derive failure to `BackupIntegrityFailure` (not `WrongBackupPasswordFailure`; wrong password is detected on AES-GCM decrypt).

## 9. Edge Cases

- Interface parameter name `masterPassword` is reused for PIN and backup password.
- Tests inject `FastKeyManagementService` (`test/core/security/support/fast_key_management_service.dart`) to avoid slow Argon2 in suites; production always uses `CryptoServiceImpl`.
- Master-password policy (min length 8) is enforced at UI / `changeMasterPassword` / register, not inside `deriveKey`.

## 10. Testing

- `test/core/crypto/crypto_service_test.dart` — includes derivation behavior.
- `test/core/crypto/key_management_service_test.dart` — uses derived keys for wrap/unwrap.
- `test/feature/auth/auth_repository_test.dart` — create/authenticate paths that call KDF.
- `test/core/security/master_password_policy_test.dart` — policy, not Argon2 itself.

## 11. Technical Decisions

- Argon2id from `package:cryptography` rather than a custom KDF.
- Parameters stored per user (and per PIN material / backup file) so future parameter changes can apply to new wraps without a global constant-only design. `changeMasterPassword` already writes `defaultKdfParameters()` onto the user.
- Same derive API for master password, PIN, and backup password to avoid a second KDF implementation.

## 12. Limitations / Notes

- `deriveKey` runs on the calling isolate. There is no background-isolate KDF in this codebase.
- PIN wrap/unwrap uses the same production Argon2id parameters as the Master Password (`defaultKdfParameters()`), so PIN unlock pays the same memory/time cost.
- Memory cost `65536` is the value stored in `SecurityConstants`; the unit expected by `package:cryptography` Argon2id is whatever that package documents (KiB). The codebase does not convert units.
- No progressive KDF upgrade path exists except rewriting parameters on master-password change.
- Derived keys are `Uint8List`; wiping uses `fillRange`, which is best-effort in Dart (the list may still be copied by the runtime).

## 13. Summary

Argon2id in `CryptoServiceImpl.deriveKey` produces a 32-byte key from a secret plus salt and stored `KdfParameters`. Defaults are memory 65536, time 3, parallelism 4. Salt is persisted; the password and derived key are not. PIN and backup each have their own salt. Master-password change rotates salt and parameters.

Related: [Vault Key Management](04_vault_key_management.md), [Master Password](01_master_password_account_lifecycle.md), [Backup](09_secure_backup_restore.md), [PIN](06_pin_authentication_lockout.md).
