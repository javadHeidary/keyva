# Authentication & Session Lifecycle

## 1. Overview

Authentication proves a secret (Master Password, PIN, or biometric wrap) and places a Vault Key into `SessionService`. `VaultUnlockService` then decrypts vault bytes into `VaultSession`. Routing uses `SessionGuard` / `UnlockedRedirectMiddleware` based on `SessionService.isAuthenticated`. Locking clears both session key and decrypted vault data.

## 2. Purpose

The session is the in-memory unlocked state. Without it, repositories refuse to encrypt/decrypt. The split between `SessionService` (identity + Vault Key) and `VaultSession` (decrypted `VaultData`) keeps crypto key handling separate from the item graph.

## 3. Architecture

| Layer | Role |
| --- | --- |
| Presentation | Login/unlock views; `GetMaterialApp` middlewares |
| ViewModel | `LoginController`, `RegisterController`, `AuthStartupViewModel` |
| Service | `VaultUnlockServiceImpl` |
| Repository | `AuthRepositoryImpl.authenticate` / `openSession` / `logout` |
| Core | `SessionServiceImpl`, `AuthenticatedSession`, `VaultSessionImpl` |
| Local Storage | Not used for session (memory only); `activeUserId` is a hint |
| Domain | Not present |

## 4. Implementation Flow

**Master Password unlock**

```text
LoginController.login
    ↓
VaultUnlockService.unlock(userId, masterPassword)
    ↓
AuthRepository.authenticate
    ↓
deriveKey → unwrapVaultKey → openSession
    ↓
reset PIN and biometric failed attempts
    ↓
_openVault:
    VaultRepository.loadVaultData
    deserialize or VaultData.initial()
    VaultSession.unlock
    ScreenProtectionService.applyPersisted
```

**PIN / biometric unlock**

```text
PinService / BiometricService.unwrapVaultKey
    ↓
AuthRepository.openSession(userId, vaultKey)
    ↓
_openVault (same as above)
```

**Failure**

```text
_failClosed:
    VaultSession.lock
    AuthRepository.logout
    return FailureResult
```

Biometric **prompt** failures (`BiometricCancelledFailure` and related) are returned without `_failClosed` so a cancel does not always tear down a session that was not opened. Crypto/session failures still fail closed.

**Process start**

```text
Splash → AuthStartupViewModel.resolveInitialRoute
    ↓
if session authenticated AND pause timestamp exceeds auto-lock → lock → accounts
    ↓
else if authenticated → shell
    ↓
else if onboarding incomplete → onboarding
    ↓
else accounts
```

Cold start normally has no authenticated session; `SessionServiceImpl` starts empty.

## 5. Important Classes & Files

| Class / File | Responsibility | Relationship |
| --- | --- | --- |
| `SessionService` — `lib/core/session/session_service.dart` | `current`, `isAuthenticated`, `vaultKey`, `setAuthenticated`, `updateUsername`, `clear` | Singleton |
| `SessionServiceImpl` | In-memory `_current` + `_vaultKey` | Zeros key on clear/replace |
| `AuthenticatedSession` — `lib/core/session/authenticated_session.dart` | `userId`, `username` only | Does not contain Vault Key |
| `VaultSession` / `VaultSessionImpl` | `isUnlocked`, `vaultData`, `unlock`, `lock` | Holds `VaultData?` |
| `VaultUnlockService` / `VaultUnlockServiceImpl` | `unlock`, `unlockWithPin`, `unlockWithBiometric`, `lock` | Orchestrates auth + decrypt |
| `SessionGuard` — `lib/core/routes/session_guard.dart` | Redirects locked users to `/auth/accounts` | GetX middleware |
| `UnlockedRedirectMiddleware` | Redirects already-authenticated users to `/shell` | Auth routes |
| `AuthStartupViewModel` | Initial route | Splash bindings |
| `openSession` | Sets session, writes `activeUserId` | Called after unwrap |

`AppRoutes` attaches `_sessionGuard` to protected pages and unlocked-redirect on auth pages (`lib/core/routes/app_routing.dart`).

## 6. Data Flow

**Created:** `openSession` after successful unwrap.

**Destroyed:** `SessionService.clear` via `logout`, `_authenticationFailed`, `deleteAccount`, or `VaultUnlockService.lock`.

| Item | Unlocked | Locked |
| --- | --- | --- |
| `AuthenticatedSession` | non-null | null |
| `vaultKey` | 32-byte list | null (zeroed) |
| `VaultSession.vaultData` | `VaultData` | null |
| Blob cache | may hold plaintext images | `clearCache` on lock |

`isAuthenticated` is `_current != null`. It does not check that `vaultKey` is non-null; `setAuthenticated` always sets both together, and `clear` clears both.

## 7. Security Considerations

- Vault Key only in memory; wiped on `clear`.
- Successful master-password unlock resets PIN and biometric attempt counters.
- `loadVaultData` requires authenticated session + vault key.
- Route guards use `isAuthenticated`, not `VaultSession.isUnlocked`. In the implemented unlock path both are set together; a hypothetical session without `VaultSession.unlock` would still pass `SessionGuard`.
- Screen protection is re-applied after vault open.

## 8. Error Handling

`authenticate` maps all failures to `AuthenticationFailure` and clears session.

`VaultUnlockService` maps load/deserialize failures through `_failClosed`.

UI: `LoginController` uses `wrongPasswordMessage` for `AuthenticationFailure` on master-password login; PIN/biometric have remaining-attempt strings and lockout dialogs.

## 9. Edge Cases

- Empty vault ciphertext → `VaultData.initial()` (default categories, empty item lists).
- `resolveUnlockUserId`: prefer `activeUserId` if that user still exists; else if exactly one account, that id; else `AuthenticationFailure` (multi-account must pick from the list).
- `AuthStartupViewModel` can lock on startup if a persisted pause timestamp is present and the session is still authenticated (process not killed).
- `lock()` order: blob cache, vault session, then `logout`.

## 10. Testing

- `test/core/session/session_service_test.dart`
- `test/feature/auth/auth_session_lifecycle_test.dart`
- `test/feature/vault/vault_unlock_service_test.dart`
- `test/feature/vault/vault_session_test.dart`
- `test/feature/auth/auth_startup_viewmodel_test.dart`

## 11. Technical Decisions

- Two objects (`SessionService` vs `VaultSession`) instead of one “session” blob.
- GetX middleware for route gating rather than checking auth in every View.
- Unlock service owns the decrypt+deserialize step so PIN/bio/master share `_openVault`.

## 12. Limitations / Notes

- No idle timer while the app stays in the foreground; auto-lock is lifecycle-based (see [Auto Lock](08_auto_lock.md)).
- `SessionGuard` does not inspect `VaultSession`.
- Biometric cancel does not call `_failClosed`.

## 13. Summary

Unlock derives or unwraps a Vault Key, stores it in `SessionService`, decrypts Hive vault bytes, and places `VaultData` in `VaultSession`. Lock clears blob cache, drops `VaultData`, and zeros the Vault Key. Routes follow `isAuthenticated`.

Related: [Master Password](01_master_password_account_lifecycle.md), [PIN](06_pin_authentication_lockout.md), [Biometric](07_biometric_authentication.md), [Auto Lock](08_auto_lock.md), [Vault Lifecycle](17_vault_process_lifecycle.md).
