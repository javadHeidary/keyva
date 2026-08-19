# Task 11 — Authentication UI and Session Lifecycle

This note describes the **Flutter authentication and session lifecycle that is actually wired in the codebase**.

It is a learning reference and an implementation record. The source of truth is the Dart code and tests, not the architecture proposals.

Related code:

- [`lib/feature/auth/view_model/auth_login_viewmodel.dart`](../../lib/feature/auth/view_model/auth_login_viewmodel.dart)
- [`lib/feature/auth/view_model/auth_register_viewmodel.dart`](../../lib/feature/auth/view_model/auth_register_viewmodel.dart)
- [`lib/feature/auth/view_model/auth_startup_viewmodel.dart`](../../lib/feature/auth/view_model/auth_startup_viewmodel.dart)
- [`lib/feature/auth/view/auth_login_view.dart`](../../lib/feature/auth/view/auth_login_view.dart)
- [`lib/core/routes/session_guard.dart`](../../lib/core/routes/session_guard.dart)
- [`lib/core/routes/app_routing.dart`](../../lib/core/routes/app_routing.dart)
- [`lib/feature/vault/service/vault_unlock_service.dart`](../../lib/feature/vault/service/vault_unlock_service.dart)
- [`lib/core/session/session_service.dart`](../../lib/core/session/session_service.dart)
- [`test/feature/auth/auth_login_view_test.dart`](../../test/feature/auth/auth_login_view_test.dart)
- [`test/feature/auth/auth_session_lifecycle_test.dart`](../../test/feature/auth/auth_session_lifecycle_test.dart)
- [`test/feature/auth/auth_startup_viewmodel_test.dart`](../../test/feature/auth/auth_startup_viewmodel_test.dart)

It reuses Task 03 (`AuthRepository`, `SessionService`), Task 06 (`VaultUnlockService`, `VaultSession`), and Task 10 Vault screens. It does **not** add PIN, biometrics, auto-lock, Master Password change, backup/restore, account deletion, or an account picker.

---

## Overview

Task 11 connects the existing authentication and Vault unlock services to Flutter UI.

In simple terms, this layer answers:

1. How does the Unlock screen turn a Master Password into an unlocked `SessionService` + `VaultSession`?
2. How does the app decide Unlock vs onboarding at startup without auto-decrypting the Vault?
3. How do Lock and Logout clear in-memory secrets and send the user back to Unlock?
4. How are protected Vault routes blocked while Locked?

Keyva still uses **MVVM + GetX + GetIt**. ViewModels do not hash passwords, derive keys, access Hive, or talk to `VaultRepository`.

```text
Unlock UI
 ↓
LoginController
 ↓
AuthRepository.resolveUnlockUserId + VaultUnlockService.unlock
 ↓
SessionService = Unlocked, VaultSession holds VaultData
 ↓
Shell / Vault UI
```

---

## Authentication Flow

```text
Locked
 ↓
Master Password (Unlock form)
 ↓
resolveUnlockUserId()          ← last activeUserId, else the only UserRecord
 ↓
VaultUnlockService.unlock(userId, password)
 ↓
AuthRepository.authenticate    ← Argon2id + unwrap VaultKey
 ↓
SessionService.setAuthenticated
 ↓
VaultRepository.loadVaultData + VaultSession.unlock
 ↓
Get.offAllNamed(shell)
```

Wrong password, missing user, or unresolved user id all become `AuthenticationFailure`. The UI maps that through [`vaultUserMessage`](../../lib/feature/vault/view/vault_user_message.dart) to `باز کردن گاوصندوق ممکن نشد.` It never shows `AuthenticationFailure`, Hive, crypto exceptions, or stack traces.

The password field is `obscureText` with show/hide. `TextEditingController` lives on `LoginController` and is cleared after the request, then disposed in `onClose`. Duplicate submits are ignored while `isLoading` is true; `AppButtonWidget` also disables itself during loading.

Unlock does **not** try every local account. `activeUserId` is stored in the non-secret `app_settings` box after a successful authenticate. If that id is missing and exactly one user exists, that id is used. Otherwise the UI gets a generic authentication failure.

---

## Lock Flow

```text
Vault (Home lock icon or Settings → قفل کردن)
 ↓
VaultUnlockService.lock()
 ↓
VaultSession.lock() + AuthRepository.logout()
 ↓
SessionService.clear() zeros the VaultKey
 ↓
Get.offAllNamed(authLogin)
```

Lock does not write Hive. Encrypted Vault data and `UserRecord` stay on disk.

---

## Logout Flow

Settings **خروج از حساب** confirms, then runs the same `VaultUnlockService.lock()` path and navigates to Unlock.

| Action | Session | Encrypted data | Account metadata |
|---|---|---|---|
| Lock | cleared | kept | kept |
| Logout | cleared | kept | kept |
| Account deletion | not implemented | — | — |

Logout is not account deletion. The confirm copy states that encrypted data remains on the device.

---

## Session State

[`SessionService`](../../lib/core/session/session_service.dart) is the source of truth for Locked / Unlocked:

- Locked: `isAuthenticated == false`, `current == null`, `vaultKey == null`
- Unlocked: `isAuthenticated == true` after `VaultUnlockService.unlock` succeeds

`VaultSession` still holds decrypted `VaultData` while unlocked. Task 08 operations already fail closed if `VaultSession` is locked. The UI does not keep a second session flag.

Cold start always begins Locked. Nothing reconstructs the Master Password.

---

## Navigation Protection

One GetX middleware pair:

- [`SessionGuard`](../../lib/core/routes/session_guard.dart) on Shell, Home, search, item, category, and password-history routes. If `SessionService` is not authenticated, redirect to `authLogin`.
- [`UnlockedRedirectMiddleware`](../../lib/core/routes/session_guard.dart) on login/register. If already unlocked, redirect to `shell`.

Vault widgets do not check authentication themselves.

---

## Error Handling

ViewModels read `Result` / `AppFailure.message` only. Presentation uses `vaultUserMessage`. Database failure during splash account lookup fails closed to Unlock, not to the Vault and not to a second registration path that would assume “no accounts”.

Registration uses the existing warning dialog, then `AuthRepository.createAccount` followed immediately by `VaultUnlockService.unlock` so the user is not asked for the password twice.

---

## Security Considerations

- Master Password is a method argument only. It is not logged and is cleared from the text field after submit.
- VaultKey lives only in `SessionService` RAM and is zeroed on lock/logout.
- UI never persists the VaultKey or bypasses `VaultUnlockService`.
- Locked routes cannot open Home. After lock, `Get.offAllNamed` drops the Shell so Home ViewModels are not left on a reachable route.
- `activeUserId` is a non-secret UUID in `app_settings`. It is not a credential.

---

## Testing

Widget tests use fakes (`FakeVaultUnlockService`, `FakeAuthRepository`, in-memory `SessionServiceImpl`). They do not open Hive or run Argon2id.

| File | Scenarios |
|---|---|
| [`auth_login_view_test.dart`](../../test/feature/auth/auth_login_view_test.dart) | locked Unlock screen, empty/short validation, submitting + duplicate tap ignored, success → shell + session, failure → Persian error |
| [`auth_session_lifecycle_test.dart`](../../test/feature/auth/auth_session_lifecycle_test.dart) | Locked → Home redirects to Unlock; Unlocked Home is shown; Home lock clears session and returns to Unlock; logout does not delete records; Home after lock still redirects |
| [`auth_startup_viewmodel_test.dart`](../../test/feature/auth/auth_startup_viewmodel_test.dart) | unlocked → shell; accounts → login; no accounts → onboarding; lookup failure → login |
| [`hive_user_data_source_test.dart`](../../test/core/database/hive_user_data_source_test.dart) | `listIds` |
| [`auth_repository_test.dart`](../../test/feature/auth/auth_repository_test.dart) | `hasAnyAccount`, `resolveUnlockUserId`, `activeUserId` remembered on authenticate |

Task 10 Vault widget tests remain fakes-only and should still pass.

---

## Files Changed

| File | Change |
|---|---|
| `lib/core/database/user_data_source.dart` + `hive_user_data_source.dart` | `listIds()` |
| `lib/core/constants/database_constants.dart` | `HiveSettingsKeys.activeUserId` |
| `lib/feature/auth/repository/auth_repository.dart` + impl | `hasAnyAccount`, `resolveUnlockUserId`, remember active user on authenticate |
| `lib/core/di/injection_container.dart` | pass `HiveDatabase` into `AuthRepositoryImpl` |
| `lib/core/routes/session_guard.dart` | created — one session guard |
| `lib/core/routes/app_routing.dart` | guard protected routes; splash binding; unlocked redirect on auth routes |
| `lib/feature/auth/view_model/*` + views + bindings | real unlock/register/startup |
| `lib/feature/splash/*` | route from session + `hasAnyAccount` |
| `lib/feature/onboarding/viewmodel/onboarding_viewmodel.dart` | last slide → register |
| `lib/feature/home/viewmodel/home_viewmodel.dart` + view + bindings | Lock |
| `lib/feature/settings/viewmodel/settings_viewmodel.dart` + view + bindings | Lock + Logout via `VaultUnlockService.lock` |
| `test/feature/auth/**` | auth UI / session tests |
| `documents/implementation/11_authentication_ui_session_lifecycle.md` | this note |

Task 02–10 crypto, serializer, Hive adapters, and Vault operation APIs were not redesigned.

---

## Security limitations / explicit non-goals

### Security limitations

- `activeUserId` identifies which local account Unlock will try. It does not prove the Master Password.
- Multiple accounts without a stored active id cannot be chosen in the UI yet; Unlock fails closed with the generic message.
- VaultKey and `VaultData` still live in Dart heap memory while unlocked.

### Explicit non-goals

This task does **not** provide:

- PIN, biometrics, auto-lock, or change Master Password
- Account picker, account switching UI, or account deletion
- Backup / restore
- A UseCase / Domain layer or a second session type
- Changes to Argon2id, AES-GCM, or Hive schema
