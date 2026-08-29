# Error Handling & Result Pattern

## 1. Overview

Keyva does not use thrown exceptions as the primary control flow for expected failures. Repository, service, and crypto operations return a sealed `Result<T>` that is either `Success<T>` or `FailureResult<T>` carrying an `AppFailure`. Views and ViewModels map those failures to user-visible Persian strings.

## 2. Purpose

The pattern exists so that:

- Callers can distinguish success from failure without `try/catch` on every call.
- Failures are typed (`AuthenticationFailure`, `CryptoFailure`, `DatabaseFailure`, …) instead of opaque `Exception` objects.
- Sensitive details from Hive, cryptography, or platform APIs are not forwarded into UI or logs.

## 3. Architecture

There is no Domain / UseCase layer.

| Layer | Role |
| --- | --- |
| Presentation | Toasts, form `errorMessage` observables, dialogs |
| ViewModel | Inspects `Result`, maps `AppFailure` to UI strings |
| Service / Repository | Returns `Result<T>`; maps exceptions at the boundary |
| Data Source | Catches Hive/IO errors and maps via `HiveErrorMapper` |
| Core / Security | `CryptoErrorMapper` collapses crypto exceptions to `CryptoFailure` |
| Domain | Not present |

`lib/core/exceptions/app_exceptions.dart` is empty. Failures live in `app_failure.dart`.

## 4. Implementation Flow

```text
Operation (crypto, Hive, auth, vault, backup)
    ↓
try/catch at DataSource / CryptoService / SecureStorage
    ↓
Mapper → AppFailure
    ↓
FailureResult<T>  (or Success<T>)
    ↓
Service / Repository (may replace the failure, e.g. auth fail-closed)
    ↓
ViewModel
    ↓
vaultUserMessage / dedicated UI string
    ↓
Toast, inline error, or dialog
```

Authentication failures are normalized. `AuthRepositoryImpl._authenticationFailed()` always returns `AuthenticationFailure` and calls `SessionService.clear()`, even if the underlying step was a crypto error.

## 5. Important Classes & Files

| Class / File | Responsibility | Relationship |
| --- | --- | --- |
| `Result<T>` — `lib/core/exceptions/result.dart` | Sealed success/failure wrapper | Used across repositories and services |
| `Success<T>` | Holds `data` | `isSuccess == true` |
| `FailureResult<T>` | Holds `AppFailure failure` | `isFailure == true` |
| `AppFailure` — `lib/core/exceptions/app_failure.dart` | Sealed failure type with `message` | Subclassed per failure kind |
| `CryptoErrorMapper` — `lib/core/crypto/crypto_error_mapper.dart` | Maps thrown objects to `CryptoFailure` | Used by `CryptoServiceImpl` |
| `HiveErrorMapper` — `lib/core/database/hive_error_mapper.dart` | `HiveError` → `DatabaseFailure`; else `UnknownFailure` | Used by Hive data sources and `HiveDatabase.initialize` |
| `vaultUserMessage` — `lib/feature/vault/view/vault_user_message.dart` | Maps English `AppFailure.message` values to Persian UI copy | Used by auth, vault, settings, backup ViewModels |

`AppFailure` subclasses present in code:

- `DatabaseFailure`
- `CryptoFailure`
- `VaultDecryptionFailure`
- `AuthenticationFailure`
- `BiometricCancelledFailure`, `BiometricUnavailableFailure`, `BiometricAuthFailedFailure`, `BiometricNotConfiguredFailure`, `BiometricLockedOutFailure`
- `ValidationFailure`
- `UnknownFailure`
- Backup: `InvalidBackupFormatFailure`, `UnsupportedBackupVersionFailure`, `WrongBackupPasswordFailure`, `BackupIntegrityFailure`, `BackupPayloadValidationFailure`, `BackupExportFailure`, `BackupRestorePersistenceFailure`
- `ScreenProtectionFailure`
- `PinLimitFailure`
- Gallery export: `GalleryPermissionDeniedFailure` (`permanentlyDenied`), `GallerySaveFailure`

Callers typically pattern-match with `is FailureResult<T>` / `is Success<T>` rather than using helper methods beyond `isSuccess` / `isFailure`.

## 6. Data Flow

```text
Thrown exception or invalid input
    ↓
Mapper or explicit FailureResult construction
    ↓
AppFailure (typed, generic English message)
    ↓
Optionally replaced (auth fail-closed → AuthenticationFailure)
    ↓
ViewModel reads failure.message or switches on type
    ↓
UI string (often Persian)
```

Raw exception objects are not stored on `AppFailure`. `CryptoErrorMapper.map` returns the same `AppFailure` if the error already is one; otherwise `CryptoFailure`. `HiveErrorMapper` returns the same `AppFailure` if already mapped; `HiveError` becomes `DatabaseFailure`; any other object becomes `UnknownFailure`.

`HiveDatabase.initialize` throws the mapped `AppFailure` rather than wrapping it in `Result`, because initialization runs before the DI graph is ready.

## 7. Security Considerations

- Authentication unwrap/KDF failures are not distinguished from a wrong password. `authenticate` and PIN unwrap return `AuthenticationFailure`.
- `vaultUserMessage` strips strings containing `Exception`, `Hive`, or `Error:` and substitutes a generic Persian message.
- Crypto decrypt authentication-tag mismatch becomes `VaultDecryptionFailure` in `CryptoServiceImpl.decrypt`; backup maps that to `WrongBackupPasswordFailure` so a wrong backup password is not described as a vault-key problem.
- Sensitive values (master password, PIN, Vault Key, derived keys) are not placed on `AppFailure.message`.

## 8. Error Handling

This document *is* the error-handling feature.

ViewModel examples:

- `LoginController.login` maps `AuthenticationFailure` to `wrongPasswordMessage` (`رمز اشتباه است`); other failures go through `vaultUserMessage`.
- `RegisterController.createAccount` uses `vaultUserMessage(created.failure.message)`.
- `SettingsViewModel._changeMasterPasswordFailureMessage` maps `AuthenticationFailure` to “رمز اصلی فعلی صحیح نیست.”
- `VaultHomeViewModel` stores `failure.message` (English defaults) on `errorMessage` unless a later UI mapper is applied.

There is no global error interceptor.

## 9. Edge Cases

- `Success<void>(null)` is used for operations with no payload.
- `HiveDatabase.initialize` throws `AppFailure` on adapter/box/version failure and attempts `Hive.close()` first.
- `SecureStorageServiceImpl` maps all catch-all errors to `UnknownFailure`.
- Duplicate Hive keys (`create` when the id already exists) return `DatabaseFailure` without throwing.
- `VaultDataServiceImpl._enqueue` serializes mutations; a failed mutation does not update `VaultSession`.

## 10. Testing

- `test/core/result_test.dart` — `Success` / `FailureResult` flags and payload.
- `test/core/crypto/crypto_error_mapper_test.dart` — mapper behavior.
- `test/core/hive_error_mapper_test.dart` — Hive vs unknown mapping.
- `test/feature/vault/vault_user_message_test.dart` — UI string mapping.

## 11. Technical Decisions

- Sealed `Result<T>` instead of Dart `Either` from a third-party package.
- Typed `AppFailure` hierarchy rather than a single error code enum.
- Fail-closed authentication: crypto/database detail is discarded at the auth boundary.
- English default `message` values on failures; Persian mapping at the UI edge via `vaultUserMessage` or ViewModel-specific strings.

## 12. Limitations / Notes

- `SettingsRepositoryImpl` methods such as `changeMasterPassword` and `savePin` throw `UnimplementedError`. Settings security operations go through `AuthRepository`, `PinService`, and `BiometricService` from `SettingsViewModel`, not through those repository methods.
- Some ViewModels expose raw English `failure.message` (for example vault home). Others always translate.
- `Result` has no `map` / `fold` helpers; every call site uses `is` checks.

## 13. Summary

Keyva uses a sealed `Result<T>` plus an `AppFailure` hierarchy. Data sources and crypto map exceptions into failures. Authentication replaces underlying failures with `AuthenticationFailure` and clears the session. ViewModels convert failures into UI state. There is no UseCase layer and no exception-based happy path for vault or auth operations.

Related: [Vault Encryption](03_vault_encryption_aes_gcm.md), [Authentication & Session](05_authentication_session_lifecycle.md), [Hive CE](10_hive_ce_local_storage.md).
