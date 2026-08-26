# Biometric Authentication

## 1. Overview

Biometric unlock is optional. After a successful device biometric prompt, the app reads a wrap key and `WrappedVaultKey` from flutter_secure_storage (`bio.material.$userId`), unwraps the Vault Key, and opens the vault session. Biometrics do not derive the Vault Key. A random 32-byte wrap key is generated at enable time and stored next to the wrapped Vault Key. Failed prompts are limited to 3 attempts then 15 minutes of lockout.

## 2. Purpose

Fast unlock using the platform biometric UI (`local_auth`) without placing the Master Password in memory on every unlock.

## 3. Architecture

| Layer | Role |
| --- | --- |
| Presentation | Unlock method tile; settings biometric switch |
| ViewModel | `LoginController.chooseBiometric` / `unlockWithBiometric`; `SettingsViewModel.enableBiometric` |
| Service | `BiometricServiceImpl`, `VaultUnlockServiceImpl.unlockWithBiometric` |
| Gateway | `LocalAuthBiometricGateway` (`package:local_auth`) |
| Core | `KeyManagementService` wrap; `SecureStorageService`; `UnlockAttemptLimiter` |
| Local Storage | secure storage JSON; `UserRecord.securitySettings.biometricEnabled` |
| Domain | Not present |

## 4. Implementation Flow

**Availability:** `LocalAuthentication.isDeviceSupported()` and `getAvailableBiometrics()` non-empty.

**Enable (session unlocked)**

```text
SettingsViewModel.enableBiometric
    ↓
BiometricService.enable(localizedReason)
    ↓
isAvailable? else BiometricUnavailableFailure
    ↓
gateway.authenticate (biometricOnly, stickyAuth)
    ↓
generateVaultKey() as wrapKey
    ↓
wrapVaultKey(session.vaultKey, wrapKey)
    ↓
JSON { wrapKey: base64, wrapped: WrappedKeyCodec }
    ↓
zero wrapKey in memory
    ↓
secureStorage.write bio.material.$userId
    ↓
biometricEnabled = true; reset attempts
```

If the user-flag update fails, the storage key is deleted.

**Unlock**

```text
LoginController.unlockWithBiometric
    ↓
VaultUnlockService.unlockWithBiometric
    ↓
BiometricService.unwrapVaultKey(reason: 'برای باز کردن گاوصندوق')
    ↓
if lockout → BiometricLockedOutFailure  (not generic AuthenticationFailure)
    ↓
if !available → BiometricUnavailableFailure
    ↓
prompt; map to cancelled / unavailable / failed
    ↓
on failed prompt → recordFailure
    ↓
read material; empty/invalid → BiometricNotConfiguredFailure
    ↓
unwrap with wrapKey; crypto fail → AuthenticationFailure
    ↓
reset attempts; openSession + _openVault
```

`VaultUnlockServiceImpl` does **not** `_failClosed` for biometric prompt failures (`_isBiometricPromptFailure`). Crypto/session errors still fail closed.

`LoginController` ignores `BiometricCancelledFailure` (no error toast). Other failures update remaining attempts or show lockout and fall back to Master Password.

## 5. Important Classes & Files

| Class / File | Responsibility | Relationship |
| --- | --- | --- |
| `BiometricService` / `BiometricServiceImpl` | enable, disable, unwrap, availability | `lib/core/security/biometric_service_impl.dart` |
| `BiometricGateway` / `LocalAuthBiometricGateway` | Platform prompt | `lib/core/security/local_auth_biometric_gateway.dart` |
| `BiometricPromptResult` | success, cancelled, failed, unavailable | |
| `FastUnlockStorageKeys.biometricMaterial` | `bio.material.$userId` | |
| `AppFailure` biometric subclasses | Typed UI/errors | `app_failure.dart` |
| Debug logs | `developer.log` name `KeyvaBiometric` in **kDebugMode** only | Messages are operational, not secrets |

Gateway `authenticate` options: `biometricOnly: true`, `stickyAuth: true`, `useErrorDialogs: true`.

`false` from `authenticate` is mapped to `cancelled`, not `failed`. PlatformException codes map to cancelled / unavailable / failed via `mapPlatformCode`.

## 6. Data Flow

| Data | Location |
| --- | --- |
| Wrap key | Generated in memory; persisted base64 in secure-storage JSON; zeroed after write and after unwrap |
| Wrapped Vault Key | Same JSON |
| Vault Key | Memory after unwrap → session |
| `biometricEnabled` | Hive `UserRecord` |
| Attempt/lockout | Hive `app_settings` |

The biometric template/secret never enters Dart code; the OS only returns success/failure.

## 7. Security Considerations

- Wrap key in secure storage is protected by OS storage (`encryptedSharedPreferences` on Android) and by an in-app prompt before read. It is **not** encrypted under a biometric-derived key in application code.
- Diagnostic logs in debug do not include user ids in full (`userIdLength`) or key material.
- Lockout after 3 `BiometricAuthFailedFailure` recordings; lockout check returns `BiometricLockedOutFailure`.
- Disable deletes storage and sets `biometricEnabled` false.
- Account delete purges `bio.material.$userId`.
- Successful master-password unlock resets biometric attempts.

## 8. Error Handling

Typed failures:

| Type | Typical cause |
| --- | --- |
| `BiometricCancelledFailure` | User/system cancel; `authenticate` returned false |
| `BiometricUnavailableFailure` | Device/types, or platform unavailable codes |
| `BiometricAuthFailedFailure` | Other platform failures; increments limiter |
| `BiometricNotConfiguredFailure` | Missing or unparsable wrap material |
| `BiometricLockedOutFailure` | 3 failures / 15 min |
| `AuthenticationFailure` | Session missing, wrap crypto fail, storage read fail |

`vaultUserMessage` maps the English biometric messages to Persian.

## 9. Edge Cases

- Settings toggle `onBiometricToggle(false)` returns without disabling; disable is a separate `disableBiometric` path.
- `showBiometricSetting` is hidden when `isAvailable()` is false.
- Unlock with biometric when enabled flag is true but material missing → `BiometricNotConfiguredFailure` without fail-closed.
- `UnlockAttemptLimiter` for biometric uses `biometricMaxFailedAttempts` (3) and the same 15-minute duration as PIN.

## 10. Testing

- `test/core/security/biometric_service_test.dart` — enable/unwrap, lockout after 3 failures, cancel/unavailable do not increment attempts, 15-minute reset, missing/corrupt wrap material, per-account wrap isolation, diagnostic logs omit secrets, disable deletes material
- `test/core/security/local_auth_biometric_gateway_test.dart` — platform code mapping
- `test/feature/vault/vault_unlock_pin_biometric_test.dart`
- `test/feature/auth/auth_multi_account_unlock_test.dart` — per-account biometric isolation
- `test/feature/settings/settings_security_view_test.dart`

Fakes used by other suites: `test/feature/auth/support/fake_biometric_service.dart`, `test/core/security/support/fake_biometric_gateway.dart`.

## 11. Technical Decisions

- Random wrap key stored in OS secure storage rather than deriving a key from biometric data (the platform API used does not expose a biometric-bound secret in this codebase).
- Distinct `AppFailure` types so the UI can ignore cancel and explain lockout.
- Prompt failures do not always destroy session state (`_failClosed` skipped).

## 12. Limitations / Notes

- Application-layer wrap key is recoverable from secure storage if OS storage is compromised, without the Master Password.
- `biometricOnly: true` excludes device PIN/pattern as a substitute in the `local_auth` options used here.
- iOS Keychain options are not customized in `SecureStorageServiceImpl` (only Android `aOptions`).

## 13. Summary

Biometric unlock authenticates with `local_auth`, then unwraps a Vault Key using a random wrap key stored in flutter_secure_storage. Enable requires an existing session. Three failed prompts lock biometric unlock for 15 minutes. Cancel does not fail-close the vault service. The Master Password wrap in Hive is unchanged.

Related: [PIN](06_pin_authentication_lockout.md), [Vault Key](04_vault_key_management.md), [Session](05_authentication_session_lifecycle.md), [Security Settings](16_security_settings_master_password_change.md).
