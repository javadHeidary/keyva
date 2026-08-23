# Task 12 — PIN and Biometric Authentication

This note describes the **PIN and biometric fast-unlock layer that is actually wired in the codebase**.

It is a learning reference and an implementation record. The source of truth is the Dart code and tests, not the architecture proposals.

Related code:

- [`lib/core/security/pin_policy.dart`](../../lib/core/security/pin_policy.dart)
- [`lib/core/security/pin_service.dart`](../../lib/core/security/pin_service.dart)
- [`lib/core/security/biometric_service.dart`](../../lib/core/security/biometric_service.dart)
- [`lib/core/security/secure_storage_service.dart`](../../lib/core/security/secure_storage_service.dart)
- [`lib/feature/vault/service/vault_unlock_service_impl.dart`](../../lib/feature/vault/service/vault_unlock_service_impl.dart)
- [`lib/feature/auth/view_model/auth_login_viewmodel.dart`](../../lib/feature/auth/view_model/auth_login_viewmodel.dart)
- [`lib/feature/settings/viewmodel/settings_viewmodel.dart`](../../lib/feature/settings/viewmodel/settings_viewmodel.dart)
- [`test/core/security/pin_service_test.dart`](../../test/core/security/pin_service_test.dart)
- [`test/feature/auth/auth_login_view_test.dart`](../../test/feature/auth/auth_login_view_test.dart)

It extends Task 11 (Master Password unlock, lock/logout, `SessionGuard`). It does **not** add auto-lock timers, screenshot blocking, Master Password change, backup/restore, or account deletion.

---

## Overview

PIN and biometric are optional convenience unlock methods. They do not encrypt the vault and they do not replace the Master Password.

While the vault is already unlocked, Keyva wraps a **second copy** of the same random Vault Key and stores that wrapping material in platform Secure Storage. Unlocking with PIN or biometric unwraps that copy, then reuses Task 11:

```text
PIN / Biometric
 ↓
unwrap VaultKey from Secure Storage
 ↓
AuthRepository.openSession
 ↓
VaultUnlockService loads VaultData
 ↓
SessionService = Unlocked
```

The Master Password wrap on `UserRecord.wrappedVaultKey` is unchanged. Hive schema / adapters are unchanged.

---

## PIN

Policy lives in [`SecurityConstants`](../../lib/core/constants/security_constants.dart) and [`PinPolicy`](../../lib/core/security/pin_policy.dart):

- 4–6 digits (digits only)
- Architecture docs asked for a 6-digit minimum; Task 12 and the existing Settings dialog use 4–6

Credential derivation reuses `CryptoService.deriveKey` (Argon2id) with a **dedicated PIN salt**, then `KeyManagementService.wrapVaultKey`. The vault KDF parameters on `UserRecord` are not modified.

Failed attempts are a non-secret counter in `app_settings` (`HiveSettingsKeys.pinFailedAttempts` and `pinLockoutStartedAt`). After 3 failures the PIN path is locked for 15 minutes, or until a successful Master Password unlock calls `PinService.resetFailedAttempts`.

The plaintext PIN is never written to Hive or Secure Storage.

---

## Biometric

[`BiometricGateway`](../../lib/core/security/biometric_gateway.dart) wraps `local_auth`. Keyva never stores biometric templates.

Enable (unlocked session): OS prompt → random wrap key → wrap Vault Key → store wrap key + wrapped key in Secure Storage → `biometricEnabled = true`.

Unlock: OS prompt → read wrap key → unwrap Vault Key → same session/vault path.

Failed authentications (`BiometricAuthFailedFailure`) use the same 3-attempt / 15-minute limiter as PIN, persisted as `biometricFailedAttempts:$userId` and `biometricLockoutStartedAt:$userId`. Cancel, unavailable, and not-configured results do not increment the counter. A successful Master Password unlock resets biometric attempts.

Cancel is `BiometricCancelledFailure` and stays locked without a crypto-style error. Unavailable devices hide the Settings toggle.

---

## Unlock UI

[`LoginController.loadUnlockOptions`](../../lib/feature/auth/view_model/auth_login_viewmodel.dart) prefers:

```text
Biometric (enabled + available)
 ↓
PIN (enabled + not locked out)
 ↓
Master Password (always)
```

Master Password remains reachable from PIN/biometric via `ورود با رمز اصلی`. After 3 PIN or biometric failures the Unlock screen shows a lockout dialog and switches to Master Password.

---

## Settings

PIN toggle opens the existing PIN dialog (setup or change). Disable asks for confirmation, then deletes Secure Storage material and clears `UserRecord.securitySettings.pinEnabled`. Biometric follows the same pattern with an OS prompt on enable.

Setup requires an unlocked session (`SessionGuard` + in-memory Vault Key). There is no extra Master Password prompt.

---

## Lock and logout

`VaultUnlockService.lock()` still clears `SessionService` and `VaultSession`. It does **not** delete PIN/biometric wrapping material.

---

## Testing

| File | Scenarios |
|---|---|
| `pin_policy_test.dart` | 4–6 digits, reject non-digits |
| `unlock_attempt_limiter_test.dart` | 3 failures, 15-minute reset, persistence, per-user PIN/biometric isolation |
| `pin_service_test.dart` | enable/unwrap/lockout after 3/reset/change/disable; no plaintext PIN in storage |
| `biometric_service_test.dart` | unavailable, enable, unwrap, cancel, lockout, 15-minute reset |
| `vault_unlock_pin_biometric_test.dart` | PIN/biometric unlock session; Master Password resets both attempt counters |
| `auth_login_view_test.dart` | PIN field, remaining attempts, MP fallback, lockout dialog |
| `settings_security_view_test.dart` | PIN dialog validation, enable, disable confirm, hide biometric |

Widget tests use fakes. PIN/biometric service tests use real AES-GCM wrap with a faster Argon2id configuration (`FastKeyManagementService`) so they can run beside Task 02–11 tests without timing out. Production still uses `KeyManagementService.defaultKdfParameters()`.

### Real-device notes

- Android: enroll a fingerprint, enable PIN + biometric in Settings, lock, unlock with each method, then confirm Master Password still works.
- After 3 wrong PINs or biometric failures, the Unlock screen should require Master Password; a correct Master Password should restore both methods.
- After 15 minutes without Master Password, PIN and biometric attempts reset.
- Lock and Logout must return to Unlock without deleting the account.
- Face ID on iOS should show the `NSFaceIDUsageDescription` prompt once.

---

## Files changed

New services under `lib/core/security/`. Extended `AuthRepository.openSession`, `VaultUnlockService.unlockWithPin` / `unlockWithBiometric`, Unlock UI, Settings security rows, GetIt registrations, Android `USE_BIOMETRIC`, iOS Face ID usage string.

Task 02–11 crypto, serializer, Hive adapters, and `SessionService` public API were not redesigned.

---

## Security limitations

- PIN entropy is low. Rate limiting and platform Secure Storage reduce online guessing; they do not make a 4-digit PIN equivalent to the Master Password.
- Biometric wrap keys live in Secure Storage gated by `local_auth`. This is device-bound convenience unlock, not a new root credential.
- VaultKey still lives in Dart heap memory while unlocked.
