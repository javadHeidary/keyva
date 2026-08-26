# Master Password & Account Lifecycle

## 1. Overview

A Keyva account is a `UserRecord` in the Hive `users` box. The Master Password is the user-chosen secret used to derive a wrapping key for the Vault Key. It is never stored. Account lifecycle covers register, authenticate, profile update, logout, and delete.

## 2. Purpose

The Master Password is the root secret for an account. Account records exist so the app can list users, persist KDF salt/parameters, and store the wrapped Vault Key without a cloud identity.

## 3. Architecture

| Layer | Role |
| --- | --- |
| Presentation | `AuthRegisterView`, `AuthLoginView`, `AccountSelectionView`, settings delete dialog |
| ViewModel | `RegisterController`, `LoginController`, `AccountSelectionViewModel`, `SettingsViewModel` |
| Service | `VaultUnlockService` after create; not a UseCase |
| Repository | `AuthRepository` / `AuthRepositoryImpl` |
| Data Source | `HiveUserDataSource`, `HiveVaultDataSource` |
| Core / Security | `MasterPasswordPolicy`, `CryptoService`, `KeyManagementService`, `SessionService` |
| Local Storage | Hive `users`, `vaults`, `app_settings.activeUserId`; secure storage PIN/bio material |
| Domain | Not present |

`SettingsRepository.changeMasterPassword` / `logout` are unimplemented; settings call `AuthRepository` and `VaultUnlockService` directly.

## 4. Implementation Flow

**Register**

```text
User fills username, password, confirm
    ↓
RegisterController.createAccount
    ↓
MasterPasswordPolicy via form validators
    ↓
AuthRepository.createAccount(username, masterPassword)
    ↓
UUID-like id, salt, default KDF params, random Vault Key, wrap, zero keys
    ↓
UserDataSource.create(UserRecord)
    ↓
VaultUnlockService.unlock(userId, masterPassword)
    ↓
Get.offAllNamed(shell)
    ↓
finally: clear password fields
```

**Login (master password)**

```text
LoginController.login
    ↓
VaultUnlockService.unlock(userId, masterPassword)
    ↓
AuthRepository.authenticate → derive → unwrap → openSession
    ↓
load/decrypt vault → VaultSession.unlock
    ↓
shell
    ↓
finally: clear password field
```

**Logout / lock**

```text
SettingsViewModel.lock / onLogoutConfirmed
    ↓
VaultUnlockService.lock
    ↓
EncryptedBlobStore.clearCache
    ↓
VaultSession.lock
    ↓
AuthRepository.logout → SessionService.clear (zeros Vault Key)
    ↓
Get.offAllNamed(authAccounts)
```

`AuthRepository.logout` only clears the session; it does not lock `VaultSession` by itself.

**Delete**

```text
SettingsViewModel.onDeleteAccountConfirmed (critical section vs auto-lock)
    ↓
AuthRepository.deleteAccount(masterPassword)
    ↓
verify password unwraps to session Vault Key
    ↓
purge PIN/biometric secure-storage keys + attempt counters
    ↓
delete image blobs for user
    ↓
VaultDataSource.delete
    ↓
UserDataSource.delete
    ↓
verify both gone
    ↓
clear activeUserId if it matched
    ↓
SessionService.clear
    ↓
VaultUnlockService.lock + navigate accounts
```

## 5. Important Classes & Files

| Class / File | Responsibility | Relationship |
| --- | --- | --- |
| `AuthRepository` — `lib/feature/auth/repository/auth_repository.dart` | Account and session API | Implemented by `AuthRepositoryImpl` |
| `AuthRepositoryImpl` — `lib/feature/auth/repository/auth_repository_impl.dart` | Create, authenticate, change password, delete, list accounts | Uses users/vaults/crypto/keys/session |
| `UserRecord` — `lib/core/database/models/user_record.dart` | id, username, timestamps, salt, KDF, wrapped key, `SecuritySettings`, avatarId | No password field |
| `MasterPasswordPolicy` — `lib/core/security/master_password_policy.dart` | Non-empty, min length 8 | Register, change password, backup password policy delegates to this |
| `RegisterController` — `lib/feature/auth/widget/view_model/auth_register_viewmodel.dart` | Create then unlock | `RegisterBindings` |
| `LoginController` — `lib/feature/auth/widget/view_model/auth_login_viewmodel.dart` | Unlock methods | `UnlockBindings` |
| `AccountDeletionOutcome` | `hasRemainingAccounts` | Returned from delete |
| `SecuritySettings.initial()` | PIN/bio off, auto-lock 1 minute, screenshots off | Set on create |

User ids are generated as RFC-like UUIDs from 16 secure bytes (`_generateUserId`).

## 6. Data Flow

**Never persisted:** Master Password, derived key, plaintext Vault Key after create (until a later unlock).

**Persisted on create:** `UserRecord` only. No `VaultRecord` until the first vault save after unlock (`VaultData.initial()` is in-memory until mutated).

**In memory while registering:** password controllers; cleared in `finally`.

**In memory while unlocked:** `SessionService` userId/username + Vault Key; `VaultSession.vaultData`.

Username updates go through `AuthRepository.updateProfile` (trim, non-empty) and `SessionService.updateUsername`.

## 7. Security Considerations

- Master Password never stored plaintext or hashed as a login verifier; verification is successful unwrap of the Vault Key.
- Create zeros derived key and Vault Key immediately after wrap.
- Authenticate fail-closed: `_authenticationFailed()` clears session and returns a generic `AuthenticationFailure`.
- Delete requires the current session and a password that unwraps to the same key (`_verifyMasterPassword`).
- Delete removes PIN/biometric material even if those flags were on.
- Register shows a countdown warning dialog before create (`startWarningDialogCountdown`); that is UI gating, not a cryptographic control.
- Visual strength on the register screen is a local heuristic (see [Password Strength](13_password_strength_analyzer.md)); policy is only min length 8.

There is no lockout counter for Master Password attempts.

## 8. Error Handling

- Invalid new password on change: `ValidationFailure`.
- Empty password on delete: `ValidationFailure`.
- Wrong password: `AuthenticationFailure`.
- Hive errors: `DatabaseFailure` (create collision, delete verify fail).
- UI: `vaultUserMessage` or dedicated strings (`wrongPasswordMessage` on login).

`RegisterController` maps failures through `vaultUserMessage`.

## 9. Edge Cases

- Create does not open a session; register ViewModel calls `unlock` immediately after.
- If unlock after create fails, the `UserRecord` remains in Hive (no automatic rollback in `createAccount`).
- Restore-into-new-account uses `createAccount` then unlock then `replaceVault`; rollback deletes user/vault/blobs if a later step fails (`BackupServiceImpl._rollbackNewAccount`).
- `hasAnyAccount` / empty account list drives onboarding vs account selection via splash + settings onboarding flag.
- `deleteAccount` counts remaining accounts excluding the current id.
- Account deletion is sequential (purge credentials, blobs, vault row, user row, verify). It is not a single Hive transaction. If a later step fails, earlier deletes may already have completed; a `DatabaseFailure` after a failed verify does not restore wiped data.

## 10. Testing

- `test/feature/auth/auth_repository_test.dart`
- `test/feature/auth/auth_delete_account_test.dart`
- `test/feature/auth/auth_register_view_test.dart`
- `test/feature/auth/auth_login_view_test.dart`
- `test/core/security/master_password_policy_test.dart`
- `test/feature/settings/settings_delete_account_test.dart`

## 11. Technical Decisions

- Password-wraps-Vault-Key rather than storing a password hash.
- Account id is a generated UUID, not the username (usernames need not be unique in code; uniqueness of id is enforced).
- `UserRecord` carries `SecuritySettings` so PIN/bio/auto-lock flags travel with the account.
- Logout is session clear; “lock vault” is `VaultUnlockService.lock` which also drops decrypted `VaultData`.

## 12. Limitations / Notes

- No online recovery; forgetting the Master Password loses access unless a `.keyva` backup with a known backup password exists.
- Username uniqueness is not enforced in `createAccount`.
- `SettingsRepositoryImpl.logout` throws `UnimplementedError`.

## 13. Summary

Accounts are Hive `UserRecord`s. The Master Password derives an Argon2id key that wraps a random Vault Key. The password is never stored. Register creates the record then unlocks. Logout/lock clears session and vault memory. Delete verifies the password, wipes vault, blobs, and fast-unlock material.

Related: [Argon2id](02_argon2id_key_derivation.md), [Vault Key](04_vault_key_management.md), [Session](05_authentication_session_lifecycle.md), [Multi-Account](14_multi_account_management.md), [Master Password Change](16_security_settings_master_password_change.md).
