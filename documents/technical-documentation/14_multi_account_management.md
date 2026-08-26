# Multi-Account Management

## 1. Overview

Keyva stores multiple `UserRecord`s in the same Hive `users` box. Each account has its own wrapped Vault Key, vault row, image blob directory, and PIN/biometric material. The UI lists accounts as `AccountSummary(id, username)`. Only one `SessionService` identity is active at a time.

## 2. Purpose

Allow more than one vault on one device without cloud users. Switching accounts means lock the current session and unlock another user id.

## 3. Architecture

| Layer | Role |
| --- | --- |
| Presentation | `AccountSelectionView`; login “switch account”; restore new account |
| ViewModel | `AccountSelectionViewModel`, `LoginController.canSwitchAccount` |
| Repository | `AuthRepository.getAccounts`, `getAccount`, `resolveUnlockUserId`, `createAccount`, `deleteAccount` |
| Data Source | `HiveUserDataSource.list` / `listIds` |
| Local Storage | `users` box; `app_settings.activeUserId` |
| Domain | Not present |

There is no account-switch service beyond logout + unlock another id.

## 4. Implementation Flow

**List / select**

```text
AccountSelectionViewModel.loadAccounts
    ↓
AuthRepository.getAccounts → List<AccountSummary>
    ↓
0 accounts → empty status (register/restore)
    ↓
1 account → selectAccount immediately (delayed zero)
    ↓
N accounts → show list
    ↓
Get.offAllNamed(/auth/unlock, arguments: userId)
```

**Resolve unlock target without arguments**

```text
LoginController.prepareSelectedAccount
    ↓
AuthRepository.resolveUnlockUserId
    ↓
activeUserId if that user still exists
    else unique remaining id if count == 1
    else AuthenticationFailure → navigate accounts
```

**Create additional account:** `RegisterController` from `openRegister` on the selection screen; `createAccount` adds another Hive user.

**Restore into new account:** `BackupServiceImpl.restoreIntoNewAccount` calls `createAccount` + `unlock` + `replaceVault` without deleting other users.

**Delete:** removes that user’s vault, blobs, and credentials; `AccountDeletionOutcome.hasRemainingAccounts` reflects whether others remain. Navigation always goes to account selection after delete.

**Switch:** `LoginController.changeAccount` → `Get.offAllNamed(authAccounts)`. Current session is not locked by that method alone; the user is on the unlock flow and typically not authenticated yet. If already in-shell, settings lock/logout clears the session first.

## 5. Important Classes & Files

| Class / File | Responsibility | Relationship |
| --- | --- | --- |
| `AccountSummary` — `lib/feature/auth/model/account_summary.dart` | id + username | Safe to list without vault data |
| `AccountSelectionViewModel` | Load/select/register/restore | |
| `AuthRepositoryImpl.getAccounts` | Maps `UserRecord` → summary | Omits secrets |
| `resolveUnlockUserId` | activeUserId or single account | |
| `_rememberActiveUserId` | Written on `openSession` | Best-effort put |
| `_clearActiveUserIdIfMatch` | On delete | |
| `LoginController.canSwitchAccount` | `getAccounts().length > 1` | |

Vault rows are keyed by `userId`, so two accounts cannot share a `VaultRecord`.

## 6. Data Flow

Each account independently:

- `UserRecord` (salt, wrap, settings)
- Optional `VaultRecord`
- Optional `pin.material.$userId` / `bio.material.$userId`
- Blob files under that user id directory (`EncryptedBlobStoreImpl`)
- Attempt counters keyed by user id

Session holds a single `userId`. Unlocking account B after A requires lock/clear first in the unlock service paths that fail-closed or explicit lock.

`getAccounts` returns all usernames; it does not decrypt vaults.

## 7. Security Considerations

- Account list does not expose wrapped keys.
- Unlock always specifies `userId`; the password/PIN is verified against that user’s wrap only.
- `activeUserId` is a convenience, not an authenticator.
- Deleting one account does not wipe others’ boxes or blobs.
- Restore-new-account rollback deletes only the id just created.

## 8. Error Handling

`getAccounts` failure → selection status `error` + `vaultUserMessage`.

`resolveUnlockUserId` failure → `AuthenticationFailure` (used when multiple accounts and no valid active id).

`getAccount` missing user → `AuthenticationFailure`.

## 9. Edge Cases

- Single account skips the picker and opens unlock.
- Stale `activeUserId` after delete is ignored if `exists` is false; falls through to single-id or failure.
- Usernames are not unique-checked; two accounts can share a display name.
- `openSession` overwrites `activeUserId` every successful unlock.

## 10. Testing

- `test/feature/auth/auth_multi_account_unlock_test.dart`
- `test/feature/auth/account_selection_viewmodel_test.dart`
- `test/feature/auth/account_selection_view_test.dart`
- `test/feature/backup/backup_restore_multi_account_test.dart`
- `test/feature/backup/backup_restore_new_account_test.dart`

## 11. Technical Decisions

- One Hive box for all users, keyed by UUID, rather than one database per account.
- `AccountSummary` as a non-secret DTO for lists.
- Last unlocked user remembered in `app_settings` to skip the picker when possible.

## 12. Limitations / Notes

- No simultaneous unlocked accounts.
- No per-account database encryption password beyond each wrap.
- Account selection auto-navigates when `length == 1`, which can make the list screen brief.

## 13. Summary

Multiple local accounts are multiple `UserRecord`s. The app lists id+username, remembers `activeUserId`, and unlocks one user at a time into `SessionService`. Restore can create an additional account. Delete removes only that user’s vault, blobs, and fast-unlock material.

Related: [Master Password](01_master_password_account_lifecycle.md), [Session](05_authentication_session_lifecycle.md), [Backup](09_secure_backup_restore.md).
