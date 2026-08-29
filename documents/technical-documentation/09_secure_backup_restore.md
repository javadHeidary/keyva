# Secure Backup & Restore (`.keyva`)

## 1. Overview

Backup exports the unlocked `VaultData` plus decrypted image sidecar bytes into a UTF-8 JSON envelope with extension `.keyva`. The inner payload is encrypted with AES-256-GCM under a **Backup Key** derived via Argon2id from a **Backup Password**. That password is independent of the Master Password and is never persisted.

Restore decrypts fully in memory, then either:

- **Replace existing** — overwrite the current unlocked vault (`/settings/backup`).
- **Create account** — create a new local user, unlock it, then write the restored vault (`/auth/restore`).

This document describes the code under `lib/feature/backup/`. It is the source of truth for the shipped format. The older proposal in `documents/architecture/06_backup_and_restore.md` (wrapped Vault Key + Master Password restore, no backup password) was **not** implemented.

## 2. Purpose

Move vault contents between devices or keep an offline copy without putting the Master Password or Vault Key in the file. A leaked `.keyva` still requires the backup password. Restore into an existing account does not change wrapping, PIN, or biometric material. Restore without an account creates a **new** `userId` and a **new** Vault Key wrapped by a **new** Master Password chosen on that device.

There is no cloud upload, CSV/plaintext export, merge restore, or automatic sync.

## 3. Architecture

| Layer | Role |
| --- | --- |
| Presentation | `BackupRestoreView`, `RestoreAccountSetupView`, create/restore dialogs, progress overlay |
| ViewModel | `BackupViewModel` (create + OS save); `RestoreViewModel` (pick, decrypt, commit) |
| Service | `BackupServiceImpl` (crypto + persist); `BackupFileServiceImpl` (`file_picker` only) |
| Serialization | `BackupEnvelopeCodec` (outer JSON); `BackupPayloadCodec` (inner `{ vault, imageBlobs }`); `VaultSerializer` |
| Crypto | `CryptoService.deriveKey` + `encrypt`/`decrypt`; `KeyManagementService` salt and default KDF params |
| Persistence | `VaultDataService.replaceVault`; `EncryptedBlobStore.installReplace` / `rollbackReplace` / `finalizeReplace` |
| Auth (new account only) | `AuthRepository.createAccount`; `VaultUnlockService.unlock`; rollback via `UserDataSource` / `VaultDataSource` |
| Domain | Not present |

```text
View (GetX)
  → BackupViewModel / RestoreViewModel
    → BackupService / BackupFileService
      → VaultOperationService / VaultDataService / EncryptedBlobStore / AuthRepository
        → Hive / flutter_secure_storage / blob files
```

ViewModels do not call `file_picker` or Hive. `BackupService` does not open pickers. GetIt owns `BackupService` (lazy singleton) and factory ViewModels; `BackupBindings` puts ViewModels on the route. Logged-out restore uses `BackupBindings(createAccountMode: true)` so `RestoreViewModel.mode` is `RestoreMode.createAccount`.

## 4. Cryptographic Model

```text
Backup Password  --Argon2id (envelope salt + kdfParameters)-->  Backup Key
Backup Key       --AES-256-GCM-->  ciphertext of inner payload
Vault Key        never written to the file
Master Password  never used for backup crypto
```

**Why this pattern**

- Restore must not overwrite Master Password wrapping, PIN wraps, biometric Secure Storage, or `SessionService.vaultKey`.
- The user is already unlocked when creating a backup; `VaultSession` already holds plaintext `VaultData`.
- `replaceVault` re-encrypts restored plaintext with the **current** session Vault Key.
- The file is restorable into another compatible Keyva account because it is not bound to the original Vault Key.

**Backup password**

- `BackupPasswordPolicy` delegates to `MasterPasswordPolicy` (non-empty, minimum 8 characters). Confirm-match is only in `BackupViewModel`.
- Never stored (not Hive, not `SecuritySettings`, not logs).
- Cannot be “changed” later; it is not an account credential.
- Does not become invalid when the Master Password changes (different salt from `UserRecord`).
- After encrypt/decrypt, the derived key is overwritten with `fillRange(0, length, 0)`. Dart does not guarantee memory zeroization.

**KDF on create:** fresh `_keys.generateSalt()` and `_keys.defaultKdfParameters()` (Argon2id, same costs as vault wrapping). Envelope stores that salt and those parameters so restore uses the file’s KDF, not today’s defaults.

## 5. Envelope and Payload Format

Current writes use `SecurityConstants.backupFormatVersion` (`2`). Readers accept `formatVersion` in `[minSupportedBackupFormatVersion, backupFormatVersion]` (`1`..`2`). Any other version is `UnsupportedBackupVersionFailure`.

### Outer envelope (unencrypted JSON)

Exact keys only. Extra or missing keys fail. Binary fields are Base64.

```text
{
  formatVersion,          // int, 1 or 2
  kdfSalt,                // Base64, 16 bytes
  kdfParameters: {
    algorithm,            // must be "Argon2id"
    memoryCost,           // > 0
    timeCost,             // > 0
    parallelism,          // > 0
    outputLength          // must equal kdfOutputLength (32)
  },
  nonce,                  // Base64, 12 bytes
  ciphertext,             // Base64, non-empty
  authenticationTag       // Base64, 16 bytes
}
```

`BackupEnvelope` is a transport container only. It must not contain Vault Key, Master Password, PIN, biometric material, `UserRecord`, `SecuritySettings`, or session state.

GCM tag is a separate JSON field (not concatenated onto ciphertext). Decrypt uses `EncryptedPayload` with `SecurityConstants.vaultEncryptionVersion` plus envelope nonce/ciphertext/tag.

Suggested filename: `keyva_backup_YYYY-MM-DD.keyva` (`BackupFileNames`). Date only; no username or item names. Same-day collisions are left to the OS save dialog.

### Inner payload (plaintext after GCM decrypt)

**v2 (current encode):** JSON `{ "vault": <VaultData object>, "imageBlobs": { blobId: base64 } }`.

- `vault` is the JSON object produced by `VaultSerializer` (logins, bank cards, notes, categories, image folders, image metadata).
- `imageBlobs` holds **plaintext** photo bytes that were read from `EncryptedBlobStore` at create time (already decrypted with the session Vault Key). Missing referenced blobs fail closed (`BackupExportFailure`); no file is written.
- Empty lists and an empty `imageBlobs` map are valid.

**v1 (legacy decode only):** raw `VaultSerializer` bytes of `VaultData`. `BackupPayloadCodec.decode` falls back to this when the JSON object does not have both `vault` and `imageBlobs`. Missing `imageFolders` / `images` deserialize as empty lists. No sidecar bytes.

Image bytes inside v2 are **not** separately encrypted beyond the outer GCM. After restore they are re-encrypted into sidecars with the **destination** session Vault Key via `installReplace`.

**Not in the file:** `UserRecord`, Master Password, PIN, biometric configuration, original `userId`, original Vault Key, `SecuritySettings`, Hive `activeUserId`, session state.

## 6. Implementation Flow

### Create (`BackupViewModel.createBackup`)

Entry: Settings → Backup & Restore → ایجاد پشتیبان. Requires `SessionService.isAuthenticated` before encrypt and again before export.

```text
Backup password + confirm (policy + match)
    ↓
BackupService.createBackup
    ↓
BackupPasswordPolicy
    ↓
VaultOperationService.getVault
    ↓
read each vault.imageBlobIds via EncryptedBlobStore.read
    ↓
BackupPayloadCodec.encode { vault JSON, imageBlobs base64 }
    ↓
generateSalt + defaultKdfParameters
    ↓
deriveKey(backupPassword) → backupKey
    ↓
AES-GCM encrypt payload
    ↓
zero backupKey
    ↓
BackupEnvelopeCodec.encode (formatVersion 2)
    ↓
BackupFileService.export(fileName: keyva_backup_YYYY-MM-DD.keyva)
```

Save dialog: `FileType.custom`, allowed extension `keyva`. User chooses location; Keyva does not write silently to app-private storage. Cancel is `BackupFileExportCancelled`, not an `AppFailure`.

### Pick and validate

```text
BackupFileService.pick  (FileType.any, withData: true)
    ↓
in-memory bytes, or path fallback if bytes empty
    ↓
BackupService.validateEnvelope → decode JSON, version 1..2
    ↓
RestoreViewModel holds _selectedBytes
```

Empty pick or unreadable path → `InvalidBackupFormatFailure`. Logs use `developer.log` name `KeyvaBackup` (`backup created`, `decrypt failed`, …) without secrets. `validateEnvelope` currently logs the constant `backupFormatVersion` (2), not the file’s version.

### Decrypt (`decryptBackup`)

Progress stages: starting → validating → deriving key → decrypting → deserializing → completed.

```text
BackupEnvelopeCodec.decode
    ↓
deriveKey(backupPassword, envelope salt/params)
    ↓  derive fail → BackupIntegrityFailure
AES-GCM decrypt
    ↓  VaultDecryptionFailure → WrongBackupPasswordFailure
    ↓  other decrypt fail → BackupIntegrityFailure
BackupPayloadCodec.decode → VaultData + blobs
    ↓  invalid inner JSON → BackupPayloadValidationFailure
BackupRestorePlan { vault, preview, imageBlobs }
```

Preview counts (`BackupPreview.fromVault`) are item lengths only (logins, cards, notes, image folders, images, categories). No titles or secrets.

### Restore into current vault (`restoreVault`)

Entry: same Settings screen. Confirm dialog uses replacement copy and a 3-second countdown (`startWarningDialogCountdown`) before جایگزینی. Overlay wraps `confirmRestore`.

```text
EncryptedBlobStore.installReplace (stage sidecars)
    ↓
VaultDataService.replaceVault  (encrypt with current Vault Key)
    ↓ on failure: rollbackReplace; AuthenticationFailure is passed through
    ↓ on success: finalizeReplace
VaultHomeViewModel.refreshVault + search reset
```

`replaceVault` requires an unlocked session. Restore does not generate a new Vault Key. PIN and biometric wraps still unwrap the same key.

Hive has no multi-box transaction. The persist atomic unit is one `vaults.put`. Decrypt and validate complete in memory first. A lock that wins **after** a successful save cannot roll Hive back; `replaceVault` does not rehydrate plaintext into a locked `VaultSession`. Next unlock loads whatever Hive already stored.

### Restore into new account (`restoreIntoNewAccount`)

Entries: register, account selection → `/auth/restore` (`BackupRestoreView(createAccountMode: true)`). After decrypt + preview confirm → `/auth/restore/setup` (`RestoreAccountSetupView`). Routes use `_unlockedRedirect`, not `SessionGuard`. `AppLockController` treats those routes as restore (do not treat as a locked vault session).

```text
username trim length ≥ 3 + MasterPasswordPolicy
    ↓
serialize vault (payload validation)
    ↓
AuthRepository.createAccount
    ↓
VaultUnlockService.unlock (new Vault Key)
    ↓
installReplace + replaceVault
    ↓
finalizeReplace
    ↓
success dialog → Get.offAllNamed(shell)
```

Backup password decrypts the file only; it does not become the Master Password. The new account gets a new `userId` and a new Vault Key wrapped by the new Master Password. Other local accounts are not deleted.

On any failure after `createAccount`: `_rollbackNewAccount` — `rollbackReplace`, `deleteAllForUser`, `lock`, `VaultDataSource.delete`, `UserDataSource.delete`. Failures there are swallowed so rollback is best-effort.

`RestoreViewModel` drops `_pendingVault` / blobs / selected bytes on cancel, lock (logged-in path), and `onClose`. New-account restore clears password fields in `finally`.

## 7. Important Classes & Files

| Class / File | Responsibility |
| --- | --- |
| `BackupService` / `BackupServiceImpl` | Create, validate, decrypt, restore both modes |
| `BackupFileService` / `BackupFileServiceImpl` | OS save/pick via `file_picker`; injectable hooks for tests |
| `BackupEnvelope` / `BackupEnvelopeCodec` | Strict JSON envelope |
| `BackupPayload` / `BackupPayloadCodec` | Inner vault + imageBlobs; v1 fallback |
| `BackupFileNames` | extension `keyva`; suggested name |
| `BackupPasswordPolicy` | Same rules as Master Password |
| `BackupPreview` / `BackupRestorePlan` | Counts + decrypted plan held in ViewModel |
| `RestoreProgress` | Stage, percent, Persian copy for overlay |
| `BackupViewModel` | Create + export |
| `RestoreViewModel` | `RestoreMode.replaceExisting` / `createAccount` |
| `BackupBindings` | `createAccountMode` selects restore mode |
| `BackupRestoreView` | Hub UI; hides create section in create-account mode |
| `RestoreAccountSetupView` | New username + Master Password |
| Widgets | `create_backup_dialog`, `restore_backup_password_dialog`, `restore_confirm_dialog`, `restore_progress_overlay`, `restore_new_account_success_dialog` |
| `SecurityConstants.backupFormatVersion` | `2` |
| GetIt | `injection_container.dart` |

Routes: `AppRoutes.backupRestore` (`/settings/backup`), `authRestore` (`/auth/restore`), `authRestoreSetup` (`/auth/restore/setup`).

## 8. Data Flow

```text
Unlocked VaultData + image plaintext (from blob store)
    ↓
JSON payload (vault fields + base64 blobs)  — still sensitive
    ↓
AES-GCM under backupKey
    ↓
UTF-8 JSON envelope on disk (.keyva)
```

Restore reverses this, then `replaceVault` encrypts vault JSON with the destination Vault Key and `installReplace` encrypts image bytes into that user’s blob directory.

Multi-account: restoring into account B does not mutate account A’s Hive row or blob directory.

## 9. Security Considerations

- Backup password ≠ Master Password (different KDF salt in the envelope vs `UserRecord`).
- Wrong backup password is detected by GCM MAC (`WrongBackupPasswordFailure`). Tamper vs wrong password are not distinguished.
- Derive failure is `BackupIntegrityFailure` (not shown as wrong password).
- Envelope decode uses exact key sets; extra/missing JSON keys fail.
- Restore replace uses blob staging so metadata is not left pointing at missing files.
- Creating a backup requires an authenticated session; ViewModel re-checks after encrypt before export.
- Inner payload includes real passwords, card numbers, notes, and image bytes once decrypted.
- Logs never include secrets or raw backup bytes.
- PIN / biometric / screenshot / auto-lock settings are **not** restored.
- `file_picker` is referenced only in `BackupFileServiceImpl`.

## 10. Error Handling

English `AppFailure.message` values are mapped in `vault_user_message.dart` for toasts.

| Failure | When | Typical UI |
| --- | --- | --- |
| `ValidationFailure` | Backup password policy; new-account username/password | Field / toast |
| `InvalidBackupFormatFailure` | JSON/parse/empty pick/empty path/wrong lengths | ساختار فایل پشتیبان معتبر نیست |
| `UnsupportedBackupVersionFailure` | version outside 1..2 | نسخه فایل پشتیبان پشتیبانی نمی‌شود |
| `WrongBackupPasswordFailure` | GCM auth fail | رمز عبور فایل پشتیبان صحیح نیست |
| `BackupIntegrityFailure` | Derive fail or other decrypt fail | فایل پشتیبان معتبر نیست یا آسیب دیده است |
| `BackupPayloadValidationFailure` | Inner JSON / `VaultSerializer` invalid | same integrity copy |
| `BackupExportFailure` | Missing blob store, blob read fail, save exception | ذخیره فایل پشتیبان انجام نشد |
| `BackupRestorePersistenceFailure` | Create/unlock/replace/blob install fail (often generic) | بازیابی اطلاعات انجام نشد |
| `AuthenticationFailure` | Restore current vault while locked | session copy |

Picker/export cancel is `BackupFilePickCancelled` / `BackupFileExportCancelled`, not an `AppFailure`. Raw Hive/crypto exceptions are not shown.

New-account restore maps many underlying failures to `BackupRestorePersistenceFailure`, hiding the original `AppFailure` type.

## 11. Edge Cases

- Format v1 is still accepted if envelope fields match.
- Empty image set still calls `installReplace({})` when a blob store exists.
- New-account restore rolls back the created user if unlock or persist fails.
- File pick with empty bytes → `InvalidBackupFormatFailure`.
- Lock during logged-in create/restore: ViewModels abort when `SessionService.isAuthenticated` is false; pending decrypt state is cleared.
- `RestoreAccountSetupView` is a separate `GetPage` without its own binding; it reuses the `RestoreViewModel` from `/auth/restore`.
- GetIt also registers a default `RestoreViewModel` factory with `replaceExisting`; the route binding’s `lazyPut` is what the restore screen uses.
- Full vault is processed in memory (same as `VaultSerializer` / `VaultSession`). No streaming.

## 12. Testing

| File | Coverage |
| --- | --- |
| `test/core/security/backup_password_policy_test.dart` | Min length reuse |
| `backup_envelope_codec_test.dart` | Round-trip, extra keys, unsupported version, bad KDF, truncated JSON |
| `backup_file_names_test.dart` | `keyva_backup_YYYY-MM-DD.keyva` |
| `backup_service_test.dart` | Round-trip; no plaintext/wrapping in bytes; wrong password; corruption; version; empty vault; persist failure; decrypt without session |
| `backup_file_service_test.dart` | In-memory bytes; path fallback; unreadable path; cancelled picker |
| `backup_restore_lock_test.dart` | Persist A, fail save, Hive still A; lock before/after save vs `VaultSession` |
| `backup_restore_auth_test.dart` | Same Vault Key after logged-in restore; PIN/bio/master still unwrap |
| `backup_restore_new_account_test.dart` | New account; backup password ≠ master; rollback; blobs re-encrypted with new key |
| `backup_images_test.dart` | v2 folders + bytes; missing blob fails closed; v1 without images |
| `backup_restore_multi_account_test.dart` | Restore into B leaves A unchanged |
| `backup_restore_view_test.dart` | Hub UI, validation, preview, lock races, new-account commit |
| `backup_restore_home_test.dart` | Home/Search show restored vault |
| `restore_progress_test.dart` | Stage percents and copy |

Crypto tests use `FastKeyManagementService`. Production uses default KDF costs. Widget tests use `FakeBackupFileService` / `FakeBackupService`. Security tests inspect raw backup bytes for sentinels and do not print those bytes.

## 13. Technical Decisions

- Independent backup password so sharing a file does not reveal the Master Password and so a password change does not invalidate backups.
- Same Argon2id + AES-GCM stack as vault wrapping; no custom crypto.
- Payload is decrypted `VaultData` + images, not wrapped Vault Key + ciphertext vault (avoids replacing local wrapping on restore).
- Images included in the encrypted payload (v2) rather than sidecar files next to `.keyva`.
- Fail closed on missing blobs at export and on missing blob ids at restore install.
- OS save/pick only; no silent private-directory backup and no cloud.

## 14. Limitations / Notes

- Pick filter is not limited to `.keyva` (`FileType.any`).
- Backup password policy equals Master Password policy (length), not a stronger unique policy.
- GCM failure after a well-formed envelope is always shown as wrong backup password.
- New-account restore creates a new `userId`; original account identity is not in the envelope.
- Hive `put` of one `VaultRecord` is the atomic boundary; a crash during `put` is a Hive limitation.
- Prototype `LoginVaultStore` / `CategoryCatalogController` are not part of encrypted `VaultData` backup.

## 15. Summary

A `.keyva` file is a JSON envelope: KDF salt/params plus AES-GCM ciphertext of vault JSON and image blobs, keyed by a backup password. Create runs only while unlocked. Restore decrypts, then either replaces the current `VaultData` (same Vault Key) or creates a new local account and re-encrypts under that account’s Vault Key.

Related: [Argon2id](02_argon2id_key_derivation.md), [AES-GCM](03_vault_encryption_aes_gcm.md), [Vault Key Management](04_vault_key_management.md), [Multi-Account](14_multi_account_management.md), [Error Handling](15_error_handling_result_pattern.md), [Vault Lifecycle](17_vault_process_lifecycle.md).
