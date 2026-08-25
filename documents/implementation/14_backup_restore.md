# Task 14 — Secure Backup & Restore

This note describes the **local encrypted Backup & Restore flow that is actually wired in the codebase**.

It is a learning reference and an implementation record. The source of truth is the Dart code and tests, not the architecture proposals.

Related code:

- [`lib/feature/backup/`](../../lib/feature/backup/)
- [`lib/core/security/backup_password_policy.dart`](../../lib/core/security/backup_password_policy.dart)
- [`lib/feature/vault/service/vault_data_service.dart`](../../lib/feature/vault/service/vault_data_service.dart)
- [`lib/feature/settings/view/settings_view.dart`](../../lib/feature/settings/view/settings_view.dart)
- [`test/feature/backup/`](../../test/feature/backup/)
- [`test/core/security/backup_password_policy_test.dart`](../../test/core/security/backup_password_policy_test.dart)

It extends Tasks 01–13. It does **not** add cloud backup, CSV/plaintext export, or merge restore.

---

## Overview

Task 14 adds a portable `.keyva` backup that is encrypted with a **Backup Password**, independent of the Master Password and Vault Key.

Two restore entry points share the same decrypt core:

```text
Logged-out Restore UI (/auth/restore)
  → decryptBackup
  → restoreIntoNewAccount (createAccount + unlock + replaceVault)

Logged-in Restore UI (/settings/backup)
  → decryptBackup
  → restoreVault → replaceVault
```

---

## Why Pattern A was selected

The backup stores **serialized `VaultData` encrypted by a Backup Key**. It does **not** store `wrappedVaultKey`, `UserRecord`, or the Vault Key.

Reasons:

- Restore must not overwrite Master Password wrapping, PIN, biometric Secure Storage, or `SessionService.vaultKey`.
- The user is already unlocked; `VaultSession` already holds plaintext `VaultData`.
- [`VaultRepository.saveVaultData`](../../lib/feature/vault/repository/vault_repository_impl.dart) already encrypts with the current session Vault Key.
- The file remains restorable into another compatible Keyva account because it is not bound to the original Vault Key.

Cross-device **format** portability is a property of the envelope. Restore into an existing account stays unlocked-only. Restore without an account uses `/auth/restore` (no `SessionGuard`) and creates a **new** local account with a new Master Password and Vault Key.

This deliberately differs from [`documents/architecture/06_backup_and_restore.md`](../architecture/06_backup_and_restore.md), which shipped wrapped-key + Master Password restore and no Backup Password.

---

## Why the Vault Key is excluded

If the Vault Key were in the file, restore would have to either replace the local wrapping (breaking Master Password / PIN / biometric) or unwrap it into UI-adjacent code. Pattern A avoids both:

```text
Backup Password  --Argon2id-->  Backup Key  --AES-256-GCM-->  Encrypted VaultData
Vault Key         never written to the file
Master Password   never used for backup crypto
```

---

## Backup Password model

[`BackupPasswordPolicy`](../../lib/core/security/backup_password_policy.dart) reuses [`MasterPasswordPolicy`](../../lib/core/security/master_password_policy.dart): non-empty, minimum 8 characters. Confirmation matching stays in `BackupViewModel`.

The Backup Password:

- is a separate credential with no relationship to the Master Password
- is never persisted (not Hive, not `SecuritySettings`, not logs)
- cannot be “changed” later because it is not stored
- does not become invalid when the Master Password changes

Backup Key derivation uses a **fresh salt** and `KeyManagementService.defaultKdfParameters()` (Argon2id). The derived key is overwritten with `fillRange` after encrypt/decrypt.

---

## Exact envelope format

UTF-8 JSON. Exact keys only. Binary fields are Base64. `formatVersion` **must be `1` or `2`**. Current writes use `SecurityConstants.backupFormatVersion` (`2`). Version `1` files remain readable. Any other version is rejected.

```text
{
  formatVersion,
  kdfSalt,
  kdfParameters: { algorithm, memoryCost, timeCost, parallelism, outputLength },
  nonce,
  ciphertext,
  authenticationTag
}
```

`BackupEnvelope` is a transport container only. It must not contain Vault Key, Master Password, PIN, biometric material, `UserRecord`, `SecuritySettings`, or session state.

Integrity uses existing `CryptoService.encrypt` / `decrypt` (AES-256-GCM). GCM authentication failure after a well-formed envelope is mapped to a wrong Backup Password. Truncated/malformed JSON is an invalid format.

Suggested filename: `keyva_backup_YYYY-MM-DD.keyva`. Date-only; no username or item names. Same-day collisions are left to the OS save dialog.

---

## Exact payload

The encrypted ciphertext is versioned:

**v1 (legacy):** raw `VaultSerializer` bytes of `VaultData` (`version`, `logins`, `bankCards`, `secureNotes`, `categories`). Missing `imageFolders` / `images` deserialize as empty lists.

**v2 (current):** JSON `{ "vault": <VaultData JSON>, "imageBlobs": { blobId: base64 } }`. `vault` includes `imageFolders` and `images` metadata. `imageBlobs` holds plaintext photo bytes that were decrypted from sidecar files with the **session Vault Key** at create time. A missing referenced blob fails closed (`BackupExportFailure`); no file is written.

Empty lists and an empty `imageBlobs` map are valid.

**Restored:** Vault item collections (including image folders and photo metadata) and sidecar bytes rewritten with the **current** session Vault Key, then `replaceVault`.

**Not restored:** `UserRecord`, Master Password, PIN, biometric configuration, account identity, `SecuritySettings`, Hive `activeUserId`, session state, the original Vault Key.

Task 21 owns the image blob store. Task 14 owns the envelope and Backup Password crypto.

---

## Create backup flow

```text
Unlocked session
 ↓
Backup password + confirm
 ↓
VaultOperationService.getVault()
 ↓
Decrypt sidecar blobs with the session Vault Key (fail closed if missing)
 ↓
BackupPayloadCodec.encode ({ vault, imageBlobs })
 ↓
Argon2id(Backup Password) → Backup Key
 ↓
AES-256-GCM encrypt
 ↓
BackupEnvelope JSON (formatVersion 2)
 ↓
BackupFileService.export (system save dialog)
```

Cancellation of the save dialog is a normal result, not an `AppFailure`.

---

## Restore flow

Fail-closed. Decrypt and validate fully in memory before any persist. Logged-in restore does not mutate the current Vault until `replaceVault()`. Logged-out restore does not create an account until decrypt succeeds and the user sets a new Master Password.

Shared steps:

1. `BackupFileService.pick` (in-memory bytes, or path fallback)
2. Envelope validation (`formatVersion` 1 or 2)
3. Backup Password → Argon2id → AES-GCM decrypt
4. `BackupPayloadCodec.decode` (v2 `{ vault, imageBlobs }` or v1 raw `VaultData`) + validation
5. Preview (item counts, including `پوشه تصویر` and `تصویر`)

Both restore paths then **stage** restored sidecar files next to the live `vault_blobs/{userId}` directory, call `replaceVault`, and only then swap the staged files into place. If blob staging fails, the live vault and live blobs are unchanged. If `replaceVault` fails, staged/new blobs are rolled back so current metadata is never left pointing at missing files. A failed new-account persist also deletes that user’s blob directory.

### Scenario A — no account / new device

Entry: onboarding, register, or account selection → `/auth/restore`.

```text
decryptBackup
 ↓
preview (new account copy)
 ↓
RestoreAccountSetup (username + new Master Password)
 ↓
AuthRepository.createAccount
 ↓
VaultUnlockService.unlock (new Vault Key)
 ↓
EncryptedBlobStore.installReplace (sidecars re-encrypted with the new key)
 ↓
VaultDataService.replaceVault
 ↓
EncryptedBlobStore.finalizeReplace
 ↓
shell / Home
```

The Backup Password is used only to decrypt. It does not become the Master Password. The restored account gets a new `userId` and a new Vault Key wrapped by the new Master Password.

If persist fails after `createAccount`, restore locks the session, deletes the just-created blob directory, and deletes the just-created `UserRecord` and vault row.

### Scenario B — logged-in replace

Entry: Settings → Backup & Restore.

```text
preview + replacement confirmation (جایگزینی / انصراف)
 ↓
EncryptedBlobStore.installReplace (sidecars re-encrypted with the current Vault Key)
 ↓
VaultDataService.replaceVault
 ↓
EncryptedBlobStore.finalizeReplace
 ↓
VaultRepository.saveVaultData (current Vault Key)
 ↓
If VaultSession is still unlocked → VaultSession.unlock(restored)
 ↓
VaultHomeViewModel.refreshVault + search reset
```

---

## Restore replacement policy

`replaceVault(VaultData)` remains the persist API for an already unlocked account.

`restoreIntoNewAccount` is the additional commit API for Scenario A. It reuses `createAccount` + `unlock` + `replaceVault`. It does not write Hive from the backup layer except through those existing services, plus rollback `UserDataSource.delete` / `VaultDataSource.delete` if persist fails.

Sequence:

1. Require an unlocked `VaultSession`.
2. Serialize restored `VaultData`.
3. `saveVaultData()` with the **current** Vault Key (create-or-update, never delete first).
4. After Hive success, apply `VaultSession.unlock(restoredVault)` **only if** `VaultSession` is still unlocked.
5. Never clear or replace the Vault Key.
6. If persistence fails, keep the previous `VaultSession` state and the previous Hive `VaultRecord`, and roll image sidecars back to the previous directory.
7. If persistence succeeds, discard the previous sidecar directory.

`BackupService` does not write Hive, mutate `VaultSession`, or open file pickers. It coordinates restore by staging image sidecars, calling `replaceVault`, then committing or rolling back those sidecars.

---

## Session behavior

Create backup and Scenario B restore require an authenticated session. Scenario A restore (`RestoreMode.createAccount`) does not.

If the session becomes locked during logged-in create/restore:

- ViewModels abort when `SessionService.isAuthenticated` is false
- `RestoreViewModel` drops `_pendingVault` on lock, cancel, and `onClose`
- lock **before** `saveVaultData` → Hive still has the previous Vault; `VaultSession` stays locked; no success UI
- lock **after** a successful `saveVaultData` (race below) → Hive may already contain the restored `VaultRecord`; `replaceVault` does **not** rehydrate plaintext into `VaultSession`

After a successful logged-in restore the session stays Unlocked with the **same** in-memory Vault Key.

After a successful new-account restore the session is the newly created account, with a **new** Vault Key wrapped by the new Master Password.

### Race: `saveVaultData()` then `VaultSession.unlock()`

Hive cannot roll back a completed `put`. The implemented order is still save-then-session (not delete-then-write).

```text
saveVaultData succeeds
 ↓
AppLock may run: VaultSession.lock + SessionService.clear
 ↓
if VaultSession.isUnlocked → unlock(restored)
else → AuthenticationFailure, do not put restored plaintext back in memory
```

That keeps a locked UI from holding restored `VaultData` in `VaultSession`. The next Master Password / PIN / biometric unlock loads whatever Hive already stored, using the **same** Vault Key wrapping. Restore never generates a new Vault Key.

---

## PIN / Biometric behavior

PIN and biometric wraps live in Secure Storage as a second copy of the **same** Vault Key. Restore does not rewrite those wraps or `SecuritySettings` flags.

After restore, Master Password, PIN, and biometric unlock still unwrap the original Vault Key.

---

## Atomicity boundary

Hive has no multi-box transaction. The atomic unit is one `vaults.put(userId, VaultRecord)`, the same limitation as Task 13.

Safest staged write: validate and decrypt fully in memory, then overwrite the existing `VaultRecord`. A crash *during* a Hive `put` is a Hive limitation, not a delete-then-restore hole.

`BackupService.restoreVault` maps non-auth persist failures to `BackupRestorePersistenceFailure`.

---

## File picker behavior

`file_picker` is referenced **only** by [`BackupFileServiceImpl`](../../lib/feature/backup/service/backup_file_service_impl.dart).

- Export: `FilePicker.platform.saveFile` with backup bytes (user-chosen location; not a silent private-directory write).
- Import: `pickFiles(withData: true, type: FileType.any)`. If `bytes` is null/empty, read the picked `path`.
- Cancel → `BackupFilePickCancelled` / `BackupFileExportCancelled` (not an `AppFailure`).

Widget tests use `FakeBackupFileService`. They do not depend on `file_picker`.

---

## Failure mapping

English `AppFailure.message` keys are mapped in [`vault_user_message.dart`](../../lib/feature/vault/view/vault_user_message.dart):

| Failure | Persian |
|---|---|
| Wrong backup password | رمز عبور فایل پشتیبان صحیح نیست. |
| Integrity / corrupted / payload | فایل پشتیبان معتبر نیست یا آسیب دیده است. |
| Unsupported version | نسخه فایل پشتیبان پشتیبانی نمی‌شود. |
| Invalid format | ساختار فایل پشتیبان معتبر نیست. |
| Restore persistence | بازیابی اطلاعات انجام نشد. |
| Export save | ذخیره فایل پشتیبان انجام نشد. |

Raw Hive/crypto exceptions are never shown.

---

## Testing

| File | Scenarios |
|---|---|
| [`test/core/security/backup_password_policy_test.dart`](../../test/core/security/backup_password_policy_test.dart) | Reuses Master Password min length |
| `backup_envelope_codec_test.dart` | Round-trip, extra keys, unsupported version, bad KDF, truncated JSON |
| `backup_file_names_test.dart` | `keyva_backup_YYYY-MM-DD.keyva` |
| `backup_service_test.dart` | Round-trip; no plaintext / wrapping metadata in bytes; wrong password; corruption; unsupported version; empty vault; persist failure; decrypt without session |
| `backup_file_service_test.dart` | In-memory bytes; path fallback; unreadable path; cancelled picker |
| `backup_restore_lock_test.dart` | Hive: persist Vault A, fail save, Hive still A; lock before save keeps Hive A; lock after save does not rehydrate `VaultSession` |
| `backup_restore_auth_test.dart` | After logged-in restore: same Vault Key; PIN unwrap; biometric unwrap; Master Password unlock |
| `backup_restore_new_account_test.dart` | No-account restore; backup password ≠ master password; old master not required; persist failure rolls back the new account; image blobs re-encrypted with the new Vault Key |
| `backup_images_test.dart` | v2 folders + photo bytes; missing blob fails closed; v1 without images still restores |
| `backup_restore_multi_account_test.dart` | Restore into B leaves A unchanged |
| `backup_restore_view_test.dart` | Settings row; hub copy; password validation; confirm mismatch; cancel export; preview counts without secrets; replacement cancel; lock races; persist failure; logged-out hub; new-account commit uses new master password |
| `backup_restore_home_test.dart` | Home shows Vault A, restore Vault B, Home and Search show Vault B |

Crypto tests use `FastKeyManagementService` so Argon2id stays cheap. Production still uses default KDF costs.

Security tests inspect raw backup bytes for sentinels (`TEST_USERNAME`, `TEST_SECRET_123`, `VERY_SECRET_NOTE`, `TEST_CARD_NUMBER`, `TEST_CVV`) and do not print those bytes.

---

## Known limitations

- The full vault is processed in memory (same as `VaultSerializer` / `VaultSession`). There is no streaming.
- Hive `put` of one `VaultRecord` is the atomic boundary. A lock that wins after a successful `saveVaultData` cannot roll Hive back; the in-memory session stays locked instead of applying restored plaintext.
- GCM authentication failure after a well-formed envelope is shown as a wrong Backup Password. Tamper vs wrong password are not distinguished.
- Platform save/pick UI varies; cancellation is handled, destination path is chosen by the OS.
- Prototype `LoginVaultStore` / `CategoryCatalogController` remain separate from encrypted `VaultData`. Live Home UI is `VaultHomeViewModel`.
- Dart does not guarantee memory zeroization of the Backup Key.
- New-account restore creates a new `userId`; it does not preserve the original account identity from the backup (the envelope does not contain `UserRecord`).
- The prototype Settings backup dialog (`backup_restore_dialog.dart`) is removed. `SettingsRepository` has no `exportBackup` / `importBackup` stubs.

---

## Files changed

Backup feature now includes logged-out restore (`/auth/restore`, `restoreIntoNewAccount`, `RestoreAccountSetupView`) and path-fallback file picking.

Extended: `UserDataSource.delete` (rollback only), GetIt backup wiring, onboarding/register/account-selection restore entry points, replacement confirm with Cancel.

Hive adapters, Vault encryption format, PIN/biometric wrap format, Argon2id parameters, and `SessionService` public API were not redesigned.
