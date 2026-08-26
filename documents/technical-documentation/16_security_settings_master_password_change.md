# Security Settings & Master Password Change

## 1. Overview

Per-account security flags live on `UserRecord.securitySettings`: biometric, PIN, auto-lock timeout, and prevent-screenshots. The settings UI (`SettingsViewModel`) reads them through `AuthRepository`, `PinService`, and `BiometricService`. Changing the Master Password re-wraps the **existing** session Vault Key with a newly derived key from a **new salt** and default KDF parameters. `SettingsRepositoryImpl` security methods are unimplemented stubs; they are not on the runtime path.

## 2. Purpose

Give the user control over fast unlock, auto lock, screenshot protection, and password rotation without a server. Password change must keep the Vault Key stable so vault ciphertext does not need re-encryption.

## 3. Architecture

| Layer | Role |
| --- | --- |
| Presentation | Settings security group, PIN dialogs, change-password form, auto-lock sheet, screenshot toggle |
| ViewModel | `SettingsViewModel` |
| Service | `PinService`, `BiometricService`, `ScreenProtectionService`, `VaultUnlockService` |
| Repository | `AuthRepository` for password, auto-lock, screenshots, profile |
| Local Storage | `UserRecord.securitySettings`; secure storage for PIN/bio; platform FLAG_SECURE via gateway |
| Domain | Not present |

`SettingsRepository` is used for theme, onboarding, and item-type guides only in `SettingsRepositoryImpl`.

## 4. Implementation Flow

**Load security UI**

```text
SettingsViewModel.loadSecuritySettings
    ↓
AuthRepository.currentSecuritySettings → autoLock + preventScreenshots
    ↓
PinService.isEnabled(userId)
    ↓
BiometricService.isAvailable + isEnabled
```

**Change Master Password**

```text
onChangeMasterPasswordSubmitted
    ↓
UI validation (current non-empty, new min 8, confirm match, new ≠ current)
    ↓
AuthRepository.changeMasterPassword
    ↓
require session Vault Key
    ↓
MasterPasswordPolicy.isValid(newPassword) else ValidationFailure
    ↓
derive(current) + unwrap; compare to session key (_sameKey)
    ↓
newSalt = generateSalt(); newParameters = defaultKdfParameters()
    ↓
derive(new) + wrap(session Vault Key) + unwrap verify
    ↓
UserDataSource.update salt, parameters, wrappedVaultKey
```

PIN and biometric wraps are **not** rewritten. They still wrap the same Vault Key.

**PIN / biometric / auto-lock / screenshots / lock / delete** are documented in their feature docs; settings is the UI entry: `onPinSubmitted`, `onPinChanged`, `disablePin`, `enableBiometric`, `disableBiometric`, `setAutoLockTimeout`, `setPreventScreenshot` (persist then `ScreenProtectionService.setEnabled`, rollback persist on apply failure), `lock`, `onDeleteAccountConfirmed`.

## 5. Important Classes & Files

| Class / File | Responsibility | Relationship |
| --- | --- | --- |
| `SecuritySettings` — `lib/core/database/models/security_settings.dart` | Four fields + `initial()` | Hive nested type |
| `SettingsViewModel` — `lib/feature/settings/viewmodel/settings_viewmodel.dart` | All settings security actions | `SettingsBindings` |
| `AuthRepository.changeMasterPassword` | Re-wrap Vault Key | `auth_repository_impl.dart` |
| `ScreenProtectionService` | Apply FLAG_SECURE from persisted flag | Also `applyPersisted` on app start and after unlock |
| `SecuritySettingsUiState` | UI copy of flags | Settings model |
| `SettingsRepositoryImpl` | Throws `UnimplementedError` for `changeMasterPassword`, `savePin`, `loadSecuritySettings`, `logout`, profile | Not used for those operations |

`setPreventScreenshots` only writes Hive; `setPreventScreenshot` on the ViewModel also calls the platform gateway.

## 6. Data Flow

Password change:

| Item | Action |
| --- | --- |
| Current password | Memory only; used to derive and verify |
| New password | Memory only |
| Salt / KDF params | Replaced on `UserRecord` |
| Wrapped Vault Key | Replaced |
| Session Vault Key | Unchanged |
| VaultRecord ciphertext | Unchanged |
| PIN/bio material | Unchanged |

Screenshot flag: Hive then native secure flag. On app start, `applyPersisted` may enable secure mode if **any** user has `preventScreenshots` when no session exists (see `ScreenProtectionServiceImpl._resolvePreventScreenshots`).

## 7. Security Considerations

- Password change verifies the current password by unwrapping and comparing to the session key, so a wrong current password cannot rotate the wrap.
- New wrap is verified by unwrap before persist.
- Derived keys are zeroed after use.
- `changeMasterPassword` does not accept a locked vault.
- Screen-protection apply failure rolls back the Hive flag.
- Delete-account uses auto-lock critical section.

Salt **is rotated** on password change (implementation), contrary to some earlier architecture notes.

## 8. Error Handling

ViewModel maps `AuthenticationFailure` to “رمز اصلی فعلی صحیح نیست.” Other failures: generic retry message.

Repository: no session → `AuthenticationFailure`; invalid new password → `ValidationFailure`; derive/wrap/verify fail → `AuthenticationFailure` or `CryptoFailure`.

Screenshot persist/apply failures: toast via `vaultUserMessage`.

PIN/biometric errors: toasts; biometric cancel suppressed.

## 9. Edge Cases

- New password equal to current is rejected in the ViewModel, not in the repository.
- `AuthRepository.setAutoLockTimeout` allows any non-negative `Duration`, not only `AutoLockPolicy` values.
- `onBiometricToggle(false)` does not disable; user must use disable action.
- After password change, PIN still works if it was enabled (same Vault Key).
- `SettingsRepository.saveSecuritySettings` is unimplemented; flags are written via `AuthRepository` / PIN / biometric services.

## 10. Testing

- `test/feature/auth/auth_change_master_password_test.dart`
- `test/feature/settings/settings_change_master_password_test.dart`
- `test/feature/settings/settings_security_view_test.dart`
- `test/feature/settings/settings_viewmodel_screen_protection_test.dart`
- `test/core/security/screen_protection_service_test.dart`
- `test/core/security/method_channel_screen_protection_gateway_test.dart`

## 11. Technical Decisions

- Re-wrap Vault Key instead of rotating it, so items and blobs stay decryptable.
- New salt on change (as implemented).
- Settings ViewModel talks to security services directly rather than a completed `SettingsRepository`.
- Screenshot: persist first, then platform; rollback persist if platform fails.

## 12. Limitations / Notes

- No re-wrap of PIN/biometric on password change (unnecessary while Vault Key is stable).
- `SettingsRepository` interface still lists security methods that throw if called.
- Master Password change does not update KDF algorithm string unless `defaultKdfParameters()` changes in code.

## 13. Summary

Security settings are stored on `UserRecord.securitySettings` and toggled through `SettingsViewModel` plus `AuthRepository` / `PinService` / `BiometricService` / `ScreenProtectionService`. Master Password change generates a new salt, derives a new wrapping key, and re-wraps the in-session Vault Key after verifying the old password. Vault ciphertext is not rewritten.

Related: [Master Password](01_master_password_account_lifecycle.md), [PIN](06_pin_authentication_lockout.md), [Biometric](07_biometric_authentication.md), [Auto Lock](08_auto_lock.md), [Argon2id](02_argon2id_key_derivation.md).
