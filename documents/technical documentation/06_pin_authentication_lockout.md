# PIN Authentication & Lockout

## 1. Overview

PIN is an optional 6-digit fast-unlock secret. It never stores the PIN. Enabling PIN wraps the **current session Vault Key** with a key derived via Argon2id from the PIN and a dedicated salt, then writes JSON to flutter_secure_storage. Unlock unwraps that key and opens the same vault session as Master Password unlock. After 3 failed unwraps, PIN is locked for 15 minutes.

## 2. Purpose

PIN avoids typing the Master Password on every unlock while keeping the Master Password as the wrap stored in Hive. Lockout limits online guessing of the PIN on a stolen unlocked-capable device.

## 3. Architecture

| Layer | Role |
| --- | --- |
| Presentation | Unlock method picker; `PinCodeDialog`; settings security |
| ViewModel | `LoginController`, `SettingsViewModel` |
| Service | `PinServiceImpl`, `VaultUnlockServiceImpl.unlockWithPin` |
| Repository | `UserDataSource.update` for `securitySettings.pinEnabled` |
| Core / Security | `PinPolicy`, `UnlockAttemptLimiter`, `SecureStorageService` |
| Local Storage | flutter_secure_storage key `pin.material.$userId`; Hive `app_settings` attempt counters; `UserRecord.securitySettings.pinEnabled` |
| Domain | Not present |

## 4. Implementation Flow

**Enable (vault already unlocked)**

```text
SettingsViewModel.onPinSubmitted
    ↓
PinPolicy.isValid (exactly 6 digits)
    ↓
PinService.enable(pin)
    ↓
Argon2id(pin, new salt, default params)
    ↓
wrapVaultKey(session.vaultKey, derivedKey)
    ↓
zero derivedKey
    ↓
secureStorage.write pin.material.$userId  JSON { salt, kdf, wrapped }
    ↓
UserRecord.securitySettings.pinEnabled = true
    ↓
reset failed attempts
```

If the user-flag update fails, the secure-storage entry is deleted.

**Unlock**

```text
LoginController.unlockWithPin
    ↓
VaultUnlockService.unlockWithPin
    ↓
PinService.unwrapVaultKey
    ↓
if lockout → AuthenticationFailure
    ↓
load PIN material; missing → AuthenticationFailure
    ↓
deriveKey(pin) ; fail → recordFailure + AuthenticationFailure
    ↓
unwrapVaultKey ; fail → recordFailure + AuthenticationFailure
    ↓
reset attempts
    ↓
openSession + _openVault
```

**Lockout**

`UnlockAttemptLimiter` for `UnlockAttemptMethod.pin`: max 3 failures (`pinMaxFailedAttempts`). On the 3rd failure, stores `pinLockoutStartedAt:$userId`. `isLockedOut` is true until 15 minutes (`unlockAttemptLockout`) elapse, then `reset` clears counters.

Successful **master password** unlock calls `PinService.resetFailedAttempts`.

**Change PIN:** `unwrapVaultKey` with current PIN, zero the unwrapped copy, `_wrapAndStore` with new PIN and session Vault Key.

**Disable:** delete secure-storage key, set `pinEnabled` false, reset attempts.

## 5. Important Classes & Files

| Class / File | Responsibility | Relationship |
| --- | --- | --- |
| `PinService` / `PinServiceImpl` | enable, change, disable, unwrap, lockout queries | `lib/core/security/pin_service_impl.dart` |
| `PinPolicy` | 6-digit validation | `lib/core/security/pin_policy.dart` |
| `UnlockAttemptLimiter` | Per-user PIN/biometric counters | Hive `app_settings` |
| `FastUnlockStorageKeys.pinMaterial` | Storage key helper | |
| `SecureStorageServiceImpl` | flutter_secure_storage | Android encrypted SharedPreferences |
| `LoginController` | PIN UI, remaining attempts, lockout dialog | |
| `SettingsViewModel.onPinSubmitted` / `onPinChanged` / `disablePin` | Settings | |

PIN is not stored in `UserRecord`. Only `pinEnabled` is.

## 6. Data Flow

| Data | Location |
| --- | --- |
| PIN digits | Memory in controllers during entry; not persisted |
| PIN salt + KDF + wrapped Vault Key | Secure storage JSON |
| Session Vault Key | Memory; used as wrap plaintext when enabling |
| Failed attempt count / lockout start | Hive `app_settings` |
| `pinEnabled` | Hive `UserRecord.securitySettings` |

Derived PIN key is zeroed after wrap/unwrap.

## 7. Security Considerations

- PIN length is exactly 6 digits (`pinMinLength` = `pinMaxLength` = 6).
- PIN wrap uses full Argon2id defaults (same memory/time as Master Password).
- Failed derive or unwrap increments the limiter; lockout returns the same `AuthenticationFailure` as a wrong PIN (no distinct lockout failure type for PIN unwrap).
- UI still detects lockout via `isLockedOut` and forces Master Password (`LoginController._handlePinFailure`).
- `VaultUnlockService.unlockWithPin` uses `_failClosed` on unwrap failure (locks vault session and logs out). If the user was locked already, there was no session.
- Master Password has no PIN-style limiter.

## 8. Error Handling

- Invalid PIN format on enable/change: `ValidationFailure(message: 'PIN is invalid')`.
- No session when enabling: `AuthenticationFailure`.
- Unwrap failures: `AuthenticationFailure`.
- UI remaining attempts: `کد PIN اشتباه است. N تلاش باقی مانده است.`
- Lockout dialog then `chooseMasterPassword()`.

`vaultUserMessage` does not have a dedicated PIN-invalid mapping; settings uses `vaultUserMessage` for service failures.

## 9. Edge Cases

- Enable requires an authenticated session with a Vault Key (cannot set PIN from the lock screen).
- Missing PIN material with `pinEnabled` true still fails unwrap as `AuthenticationFailure`.
- `change` does not update `pinEnabled` (already true).
- Limiter `reset` swallows Hive delete errors.
- If `PinService` is null in `VaultUnlockServiceImpl`, PIN unlock fail-closes with `AuthenticationFailure`. Production GetIt always registers `PinService`.

## 10. Testing

- `test/core/security/pin_service_test.dart`
- `test/core/security/pin_policy_test.dart`
- `test/core/security/unlock_attempt_limiter_test.dart`
- `test/feature/vault/vault_unlock_pin_biometric_test.dart`
- `test/feature/auth/auth_multi_account_unlock_test.dart` — per-account PIN lockout isolation
- `test/feature/settings/settings_security_view_test.dart` (settings PIN UI)

## 11. Technical Decisions

- Independent KDF salt for PIN so PIN wrap is not tied to Master Password salt.
- Attempt state in Hive (survives process death) rather than memory-only.
- Reuse `CryptoService.deriveKey` with the PIN string as `masterPassword`.
- After lockout, only Master Password (or waiting 15 minutes) is offered in the login UI.

## 12. Limitations / Notes

- 6-digit PIN space is small; mitigation is Argon2id plus 3-attempt / 15-minute lockout, not PIN complexity.
- Lockout timestamps are not in secure storage.
- `PinServiceImpl.change` zeros the key unwrapped from the old PIN but wraps using `session.vaultKey` (the live session key), which must match.

## 13. Summary

PIN wraps the session Vault Key with Argon2id(PIN) and stores the wrap in flutter_secure_storage. Unlock unwraps that key and opens the vault. Three failures lock PIN for 15 minutes. The PIN itself is never saved. Master Password unlock resets the PIN attempt counter.

Related: [Vault Key](04_vault_key_management.md), [Session](05_authentication_session_lifecycle.md), [Biometric](07_biometric_authentication.md), [Security Settings](16_security_settings_master_password_change.md).
