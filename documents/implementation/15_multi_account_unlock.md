# Task 15 — Multi-Account Selection & Unified Unlock

This document describes the implemented login flow. It does not change Vault encryption, Vault Key wrapping, Hive `VaultRecord`, or Backup Pattern A.

## Why a Master Password cannot identify an account

Keyva allows more than one local `UserRecord`. Two accounts may intentionally use the same Master Password (and even the same PIN). Password verification only unwraps **that account’s** `wrappedVaultKey` using **that account’s** KDF salt and parameters.

If login searched every account until a password matched, two vaults with the same password would be ambiguous. The user therefore selects an account first. Authentication always takes an explicit account id.

## Account Selection flow

```
Splash
  → no accounts → Onboarding
  → has accounts → /auth/accounts
       → 0 accounts (empty) → empty state + register
       → 1 account → /auth/unlock with that id (no extra tap)
       → N accounts → list → user picks → /auth/unlock with that id
  → Unlock method picker (Master Password always; PIN / biometric when available)
  → VaultUnlockService
  → Session + Shell
```

Lock, logout, auto-lock, and `SessionGuard` return to `/auth/accounts` while the session is locked. An authenticated session is redirected away from account selection and unlock (`UnlockedRedirectMiddleware`).

## AccountSummary

`AuthRepository.getAccounts()` / `getAccount(userId)` map Hive `UserRecord`s to:

- `id`
- `username`

They do not copy `kdfSalt`, `kdfParameters`, `wrappedVaultKey`, PIN material, biometric material, or vault ciphertext. Listing uses `UserDataSource.list()` on the `users` box only. The `vaults` box is not opened for the picker.

The UI may show a username initial. That is derived in the view from `username`.

## Selected account id

Route arguments are a `String` user id only (`Get.toNamed('/auth/unlock', arguments: userId)`).

`LoginController` prefers `Get.arguments`. If arguments are missing, it falls back to `resolveUnlockUserId()` (remembered `activeUserId` or the sole account). It does not search by password or PIN. If no id can be resolved, it returns to account selection.

`authenticate(userId, masterPassword)` was already explicit and is unchanged.

## Unlock methods

All three methods unwrap the **selected** account’s Vault Key and then `AuthRepository.openSession` + vault load:

| Method | API |
|--------|-----|
| Master Password | `VaultUnlockService.unlock(userId, masterPassword)` → `AuthRepository.authenticate` |
| PIN | `unlockWithPin(userId, pin)` → `PinService.unwrapVaultKey` |
| Biometric | `unlockWithBiometric(userId)` → `BiometricService.unwrapVaultKey` |

PIN is shown only when enabled for that user and not locked out. Biometric is shown only when enabled for that user **and** the device reports availability. Master Password is always available.

The unlock screen starts with a method picker when PIN or biometric can be used. If only Master Password is available, the password form is shown directly. Biometric is **not** auto-prompted.

## 6-digit PIN policy

`SecurityConstants.pinMinLength` and `pinMaxLength` are both `6`. `PinPolicy` is the only validation source (`PinPolicy.userMessage` = `پین کد باید ۶ رقم باشد.`). Login, settings setup/change, and `PinService.enable` / `change` share it.

Lockout is per `userId` for both PIN and biometric: 3 failed attempts, then a 15-minute window (`pinFailedAttempts:$userId` / `biometricFailedAttempts:$userId`). Successful Master Password unlock resets both counters immediately.

## Account-scoped Vault Key

Each `UserRecord` has its own salt, KDF parameters, wrapped Vault Key, vault ciphertext, PIN wrap (`pin.material.$userId`), and biometric wrap (`bio.material.$userId`). Unlocking account A never unwraps account B.

After success, `SessionService.current.userId` is the selected id. `activeUserId` in `app_settings` is still remembered on `openSession` (non-secret UUID).

## Switch account

Unlock shows **تغییر حساب** when more than one local account exists. It navigates to `/auth/accounts`. The unlock screen is only used while locked, so there is never a second live vault session.

## Routing

| Route | Screen |
|-------|--------|
| `/auth/accounts` | Account selection |
| `/auth/unlock` | Selected-account unlock |
| `/authLogin` | Alias of account selection (legacy path) |
| `/authRegister` | Create account |

## Security guarantees

- Master Password, PIN, Vault Key, wrapped keys, and biometric secrets are not passed as route arguments and are not logged.
- Account selection does not decrypt `VaultData`.
- Failures fail closed through existing `VaultUnlockService` / `AuthRepository` behavior.
- PIN input uses a numeric keyboard, obscured text, digit formatters, length 6, and `enableInteractiveSelection: false`.

## Tests

- `hive_user_data_source_test` — `list()`
- `auth_repository_test` — `getAccounts` / `getAccount`
- `account_selection_viewmodel_test` / `account_selection_view_test`
- `auth_login_view_test` — methods, PIN length, biometric fakes
- `auth_multi_account_unlock_test` — same password / same PIN / biometric scoped to `userId`
- `pin_policy_test` / `pin_service_test` — exactly 6 digits
- Existing Tasks 01–14 suites remain in place

## Known limitations

- Existing 4- or 5-digit PINs created before this policy cannot be entered in the UI or passed through `PinService.enable` / `change`. Unlock those accounts with Master Password, then set a new 6-digit PIN. There is no automatic PIN migration.
- `/authLogin` remains as an alias of account selection so older links still fail closed to the picker (then one-account skip).
- Username collisions are allowed; identity is always the account id.
