# Auto Lock

## 1. Overview

Auto lock locks the vault when the app has been in the background for the account’s `SecuritySettings.autoLockTimeout`. `AppLockController` observes `WidgetsBinding` lifecycle, shows a privacy overlay while inactive/backgrounded, persists `lastBackgroundedAt`, and calls `VaultUnlockService.lock` when the timeout elapses. Allowed timeouts are immediate, 30 seconds, 1 minute, and 5 minutes.

## 2. Purpose

Limit how long decrypted `VaultData` and the Vault Key remain in memory after the user leaves the app, without requiring a manual lock every time.

## 3. Architecture

| Layer | Role |
| --- | --- |
| Presentation | `PrivacyOverlayLayer` in `KeyvaApp.builder`; settings auto-lock sheet |
| ViewModel | `SettingsViewModel.setAutoLockTimeout`; `AuthStartupViewModel` on splash |
| Controller | `AppLockController` (GetX, permanent) |
| Service | `VaultUnlockService.lock` |
| Repository | `AuthRepository.setAutoLockTimeout` / `currentSecuritySettings` |
| Local Storage | `UserRecord.securitySettings.autoLockTimeout`; `app_settings.lastBackgroundedAt` |
| Domain | Not present |

`AppLockController` is constructed in `main.dart`, not GetIt.

## 4. Implementation Flow

```text
AppLifecycleState.inactive / hidden / paused / detached
    ↓
overlayVisible = true
    ↓
on paused/hidden/detached: write lastBackgroundedAt, start timer for remaining timeout
    ↓
timeout 0 → lock immediately
    ↓
timer fire or resume after elapsed ≥ timeout
    ↓
VaultUnlockService.lock
    ↓
Get.offAllNamed(/auth/accounts) unless already on an auth route
```

```text
AppLifecycleState.resumed
    ↓
if background duration ≥ timeout → lock
    else clear lastBackgroundedAt
    ↓
overlayVisible = false
```

Settings change:

```text
SettingsViewModel.setAutoLockTimeout
    ↓
AuthRepository.setAutoLockTimeout (reject negative)
    ↓
AppLockController.onTimeoutChanged
    ↓
if currently backgrounded, reschedule timer
```

Cold start with leftover pause timestamp:

```text
AuthStartupViewModel / AppLockController.applyPersistedPause
    ↓
if authenticated and (timeout == 0 or now - pausedAt ≥ timeout) → lock
```

**Critical section:** `beginCriticalSection` / `endCriticalSection` increment a hold count. `_lock` returns immediately if `_criticalHoldCount > 0`. Used around account deletion so auto-lock does not navigate mid-wipe.

Manual lock: `SettingsViewModel.lock` / `onLogoutConfirmed` call `VaultUnlockService.lock` directly (not via the timer).

## 5. Important Classes & Files

| Class / File | Responsibility | Relationship |
| --- | --- | --- |
| `AppLockController` — `lib/core/session/app_lock_controller.dart` | Lifecycle observer, timer, overlay flag, lock | `WidgetsBindingObserver` |
| `AutoLockPolicy` — `lib/core/security/auto_lock_policy.dart` | `immediate`, `thirtySeconds`, `oneMinute`, `fiveMinutes` + Persian labels | Settings UI |
| `AutoLockPauseStore` / `HiveAutoLockPauseStore` | Persist UTC millis | `lastBackgroundedAt` |
| `PrivacyOverlay` / `PrivacyOverlayLayer` | Full-screen absorb pointer overlay | Hides UI in recents / inactive |
| `SecuritySettings.autoLockTimeout` | Per-account duration | Default 1 minute |
| `AuthStartupViewModel._persistedPauseRequiresLock` | Splash lock if needed | |

Default cached timeout in the controller if settings fail to load: `AutoLockPolicy.oneMinute`.

## 6. Data Flow

| Data | Where |
| --- | --- |
| Timeout | Hive `UserRecord`; cached in controller `_cachedTimeout` / `_pausedTimeout` |
| Pause timestamp | Hive `app_settings` as UTC epoch millis |
| Overlay | `overlayVisible` RxBool |
| Vault Key / VaultData | Cleared when `_unlock.lock()` runs |

Foreground idle time does **not** start the auto-lock timer. The timer runs only after a background/paused transition.

## 7. Security Considerations

- Privacy overlay covers the UI on inactive/paused so app switcher snapshots are obscured (solid black or white). This is separate from Android FLAG_SECURE (`ScreenProtectionService`).
- Immediate timeout (`Duration.zero`) locks as soon as the app is backgrounded (or on persisted pause).
- Lock navigates away from vault routes.
- Pause store write/read errors are swallowed; failure to persist pause means process death might not lock on next start if the in-memory session is also gone (typical Android kill). If the process survived, the in-memory timer still applies.

## 8. Error Handling

`setAutoLockTimeout` with negative duration returns `ValidationFailure`. `AutoLockPolicy.isSupported` exists for UI values; `AuthRepository.setAutoLockTimeout` only checks `timeout.isNegative`, not membership in `AutoLockPolicy.values`.

Load timeout uses last cached value if `currentSecuritySettings` is not `Success`.

Lock is guarded by `_locking` so concurrent lifecycle events do not double-lock.

## 9. Edge Cases

- Overlay shows on `inactive` without starting the background timer; timer starts on `hidden` / `paused` / `detached`.
- If already on auth routes, navigation after lock is skipped.
- `applyPersistedPause` no-ops when not authenticated.
- Changing timeout while backgrounded uses the new timeout for remaining time (`onTimeoutChanged`).
- Tests inject `clock` and `startTimer`.

## 10. Testing

- `test/core/session/app_lock_controller_test.dart`
- `test/core/session/auto_lock_pause_store_test.dart`
- `test/core/session/privacy_overlay_test.dart`
- `test/feature/auth/auth_startup_viewmodel_test.dart` (persisted pause)
- `test/feature/backup/backup_restore_lock_test.dart` (lock interaction with restore)

## 11. Technical Decisions

- Lifecycle-based lock rather than a global idle pointer detector.
- Persist pause time so a killed-and-restored process can still lock if a session were still authenticated.
- Privacy overlay independent of screenshot FLAG_SECURE.
- Critical section so long mutations are not interrupted by auto-lock navigation.

## 12. Limitations / Notes

- No auto-lock after prolonged foreground use.
- Overlay color is theme black/white only; it is not a blur of vault content.
- `AuthRepository.setAutoLockTimeout` does not validate that the duration is one of `AutoLockPolicy.values`.

## 13. Summary

`AppLockController` watches app lifecycle, covers the UI with a privacy overlay, and locks via `VaultUnlockService` when the configured background timeout elapses (including immediate). Timeout is stored per account. Manual lock and logout use the same unlock service. Startup can lock from a persisted pause timestamp.

Related: [Session](05_authentication_session_lifecycle.md), [Security Settings](16_security_settings_master_password_change.md), [Vault Lifecycle](17_vault_process_lifecycle.md).
