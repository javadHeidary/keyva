# Task 13 — Security Settings and Master Password Management

This note describes the **Security Settings controls and Master Password change flow that are actually wired in the codebase**.

It is a learning reference and an implementation record. The source of truth is the Dart code and tests, not the architecture proposals.

Related code:

- [`lib/core/security/master_password_policy.dart`](../../lib/core/security/master_password_policy.dart)
- [`lib/core/security/auto_lock_policy.dart`](../../lib/core/security/auto_lock_policy.dart)
- [`lib/feature/auth/repository/auth_repository_impl.dart`](../../lib/feature/auth/repository/auth_repository_impl.dart)
- [`lib/core/session/app_lock_controller.dart`](../../lib/core/session/app_lock_controller.dart)
- [`lib/feature/settings/viewmodel/settings_viewmodel.dart`](../../lib/feature/settings/viewmodel/settings_viewmodel.dart)
- [`lib/feature/settings/view/settings_view.dart`](../../lib/feature/settings/view/settings_view.dart)
- [`test/feature/auth/auth_change_master_password_test.dart`](../../test/feature/auth/auth_change_master_password_test.dart)
- [`test/core/session/app_lock_controller_test.dart`](../../test/core/session/app_lock_controller_test.dart)
- [`test/feature/settings/settings_security_view_test.dart`](../../test/feature/settings/settings_security_view_test.dart)

It extends Task 12 (PIN, biometric, lock/logout, Settings security rows). It does **not** add screenshot blocking, backup/restore, account deletion, or Master Password rate limiting.

---

## Overview

Task 13 completes the remaining security-management features:

1. Change Master Password by **re-wrapping the same Vault Key**.
2. Persist and apply **auto-lock timeout**.
3. Keep PIN, biometric, and encrypted Vault data unchanged.

Keyva still uses **MVVM + GetX + GetIt**. Views and ViewModels do not derive keys, wrap keys, or talk to Hive.

```text
Security Settings
 ↓
SettingsViewModel
 ↓
AuthRepository.changeMasterPassword / setAutoLockTimeout
 ↓
CryptoService + KeyManagementService + UserDataSource
 ↓
Session remains Unlocked
```

---

## Master Password policy

[`MasterPasswordPolicy`](../../lib/core/security/master_password_policy.dart) is the single rule used by registration and Change Master Password:

- non-empty
- at least `SecurityConstants.masterPasswordMinLength` (8)

Confirmation matching stays in the ViewModel, same pattern as PIN.

---

## Change Master Password

The Master Password is never stored. Proof of the current password is a successful unwrap of `UserRecord.wrappedVaultKey`.

`AuthRepository.authenticate()` **cannot** be reused here: a wrong password would call `SessionService.clear()` and lock the user out of Settings. Change uses a dedicated path that does not touch the session on failure.

```text
Unlocked session (required)
 ↓
Derive from current MP + stored salt/KDF
 ↓
Unwrap UserRecord.wrappedVaultKey
 ↓
Compare to SessionService.vaultKey
 ↓
New salt + default KDF parameters
 ↓
Derive new key and wrap the SAME session Vault Key
 ↓
Unwrap that wrap and compare again
 ↓
UserDataSource.update (one Hive put)
 ↓
Session stays Unlocked; VaultRecord untouched
```

If any step fails before persist, the old salt/wrap remain valid. If persist fails, Hive still holds the previous `UserRecord`. Derived-key buffers are overwritten after use. The in-memory Vault Key is not replaced.

Encrypted Vault data is not decrypted or re-encrypted. Only the wrapping around the Vault Key changes.

PIN and biometric wrapping live in Secure Storage as a second copy of the same Vault Key. They do not need to be re-wrapped after a Master Password change.

---

## Auto-lock

`SecuritySettings.autoLockTimeout` was already on `UserRecord` (default 1 minute). Task 13 wires it.

Options in [`AutoLockPolicy`](../../lib/core/security/auto_lock_policy.dart):

```text
Immediate   → Duration.zero
30 seconds
1 minute    → default
5 minutes
```

[`AppLockController`](../../lib/core/session/app_lock_controller.dart) is the single lifecycle observer. Screens do not implement their own timers.

```text
App paused / hidden
 ↓
If timeout is Immediate → VaultUnlockService.lock → Unlock route
Otherwise start a timer
 ↓
Timer fires, or resume after timeout
 ↓
Lock
```

If the user returns before the timeout, the session stays Unlocked. A cold start is already Locked because `SessionService` is in-memory only.

Navigation stays in the controller (same as Settings lock), not in `AuthRepository`.

---

## Settings UI

The Security group now has:

- Lock now (Task 11)
- Change Master Password
- Biometric enable/disable (Task 12)
- PIN enable/disable/change (Task 12)
- Screenshot toggle (still a visual prototype; not persisted)
- Auto-lock timeout picker

The prototype "lock on app exit" toggle was replaced by the Immediate auto-lock option.

---

## Testing

| File | Scenarios |
|---|---|
| `master_password_policy_test.dart` | min length, empty, shared field errors |
| `auth_change_master_password_test.dart` | wrong current password; re-wrap; vault ciphertext unchanged; PIN still unwraps; persist/wrap failure keeps old wrap |
| `app_lock_controller_test.dart` | immediate lock, resume early, resume late, timer expiry, already locked |
| `settings_security_view_test.dart` | password validation, successful submit, timeout picker; existing PIN/biometric rows |

Change-password crypto tests use `FastKeyManagementService` so they can run beside Task 02–12 tests without a 2-minute Argon2id cost. Production still uses `KeyManagementService.defaultKdfParameters()`.

### Real-device notes

- Change Master Password while unlocked, lock, unlock with the new password, then confirm old password fails.
- Existing vault items must still open after the change.
- If PIN or biometric was enabled, those unlock methods must still work.
- Set auto-lock to Immediate, switch apps, return: Unlock screen.
- Set auto-lock to 1 minute, background for a few seconds, return: still unlocked.

---

## Files changed

New: `MasterPasswordPolicy`, `AutoLockPolicy`, `AppLockController`, auto-lock bottom sheet, Task 13 tests and this note.

Extended: `AuthRepository` (`changeMasterPassword`, `currentSecuritySettings`, `setAutoLockTimeout`), Settings ViewModel/View, register validators, `main.dart` registers `AppLockController`.

Hive adapters, Vault encryption format, PIN/biometric wrap format, and `SessionService` public API were not redesigned.

---

## Security limitations

- Hive `put` of one `UserRecord` is the atomic boundary. There is no multi-box transaction.
- Dart does not guarantee memory zeroization of Derived Keys.
- Auto-lock tracks app lifecycle, not every pointer event while the app is in the foreground.
- Screenshot / app-switcher preview protection is still unimplemented.
