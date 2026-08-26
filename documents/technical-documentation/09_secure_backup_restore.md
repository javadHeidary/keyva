# Secure Backup & Restore (`.keyva`)

## 1. Overview

Backup exports the unlocked `VaultData` plus decrypted image blobs into a JSON envelope file with extension `.keyva`. The payload is encrypted with AES-256-GCM under a key derived via Argon2id from a **Backup Password** that is independent of the Master Password. Restore can replace the current vault or create a new account.

## 2. Purpose

Move vault contents between devices or keep an offline copy without using the Master Password as the file secret. A leaked `.keyva` file still requires the backup password.

## 3. Architecture

| Layer | Role |
| --- | --- |
| Presentation | Create-backup dialog; restore views and password dialog; progress overlay |
| ViewModel | `BackupViewModel`, `RestoreViewModel` |
| Service | `BackupServiceImpl`, `BackupFileServiceImpl` |
| Serialization | `BackupEnvelopeCodec`, `BackupPayloadCodec`, `VaultSerializer` |
| Crypto | `CryptoService.deriveKey` + `encrypt`/`decrypt`; `KeyManagementService` salt |
| Persistence | `VaultDataService.replaceVault`; `EncryptedBlobStore.installReplace` |
| Domain | Not present |

Backup requires an authenticated session to **create**. Restore-into-new-account creates a session as part of the flow.

## 4. Implementation Flow

**Create**

```text
BackupViewModel.createBackup
    ↓
BackupPasswordPolicy (same min length 8 as Master Password)
    ↓
BackupService.createBackup
    ↓
VaultOperationService.getVault
    ↓
read image blobs (plaintext from EncryptedBlobStore cache/files)
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
BackupEnvelopeCodec.encode JSON:
    formatVersion, kdfSalt, kdfParameters, nonce, ciphertext, authenticationTag
    ↓
BackupFileService.export(fileName: keyva_backup_YYYY-MM-DD.keyva)
```

**Validate / decrypt**

```text
pick file (FileType.any)
    ↓
validateEnvelope → decode JSON, version in [1, 2]
    ↓
decryptBackup:
    deriveKey(backupPassword, envelope salt/params)
    AES-GCM decrypt
    if VaultDecryptionFailure → WrongBackupPasswordFailure
    BackupPayloadCodec.decode → VaultData + blobs
```

**Restore into current vault**

```text
installReplace image blobs (staged)
    ↓
VaultDataService.replaceVault
    ↓
on failure: rollbackReplace
    ↓
on success: finalizeReplace
```

**Restore into new account**

```text
validate username length ≥ 3 and MasterPasswordPolicy
    ↓
createAccount
    ↓
unlock with that master password
    ↓
install blobs + replaceVault
    ↓
on any failure: _rollbackNewAccount (lock, delete user/vault/blobs)
```

## 5. Important Classes & Files

| Class / File | Responsibility | Relationship |
| --- | --- | --- |
| `BackupService` / `BackupServiceImpl` | Create, validate, decrypt, restore | `lib/feature/backup/service/` |
| `BackupFileService` / `BackupFileServiceImpl` | OS save/pick via `file_picker` | |
| `BackupEnvelope` | Unencrypted header + ciphertext fields | |
| `BackupEnvelopeCodec` | Strict JSON key set; version check | |
| `BackupPayload` / `BackupPayloadCodec` | Inner `{ vault, imageBlobs }` | Images as base64 **before** outer encrypt |
| `BackupFileNames` | extension `keyva`; suggested name | |
| `BackupPasswordPolicy` | Delegates to `MasterPasswordPolicy` | Independent secret, same rules |
| `SecurityConstants.backupFormatVersion` | `2` | `minSupportedBackupFormatVersion` = `1` |
| `RestoreViewModel` | `RestoreMode.replaceExisting` / `createAccount` | `BackupBindings(createAccountMode:)` |
| `BackupRestorePlan` | vault, preview, imageBlobs | After decrypt |
| `RestoreProgress` | Callback stages | Overlay |

Save dialog restricts extension to `keyva`. Pick does not filter by extension (`FileType.any`).

Logs use `developer.log` name `KeyvaBackup` (`backup created`, `decrypt failed`, …) without secrets.

## 6. Data Flow

```text
VaultData + image plaintext
    ↓
JSON payload (vault fields + base64 blobs)  — still sensitive
    ↓
AES-GCM under backupKey
    ↓
UTF-8 JSON envelope on disk (.keyva)
```

Restore reverses this. Image blobs in the payload are **plaintext bytes encoded as base64 inside the encrypted payload**, not separately encrypted with the backup key beyond the outer GCM.

The Master Password is not written into the backup. The new account’s Master Password only wraps a **new** Vault Key; `replaceVault` then encrypts restored plaintext with **that** session Vault Key.

## 7. Security Considerations

- Backup password ≠ Master Password (different KDF salt in the envelope).
- Wrong backup password is detected by GCM MAC (`WrongBackupPasswordFailure`).
- Derive failure is `BackupIntegrityFailure` (not distinguished as wrong password).
- Envelope decode uses exact key sets; extra/missing JSON keys fail.
- Restore replace uses blob staging (`installReplace` / `rollbackReplace` / `finalizeReplace`).
- Creating a backup requires `SessionService.isAuthenticated`; ViewModel re-checks after encrypt before export.
- Inner payload includes real passwords, card numbers, notes, and image bytes once decrypted.

## 8. Error Handling

| Failure | When |
| --- | --- |
| `ValidationFailure` | Backup password policy fail; new-account field fail |
| `InvalidBackupFormatFailure` | JSON/parse/empty pick |
| `UnsupportedBackupVersionFailure` | version outside 1..2 |
| `WrongBackupPasswordFailure` | GCM auth fail |
| `BackupIntegrityFailure` | Derive fail or other decrypt fail |
| `BackupPayloadValidationFailure` | Inner JSON invalid |
| `BackupExportFailure` | Missing blob store / blob read fail |
| `BackupRestorePersistenceFailure` | Create/unlock/replace/blob install fail (often generic) |
| `AuthenticationFailure` | Restore current vault while locked |

UI uses `vaultUserMessage`. Export cancelled is `BackupFileExportCancelled`, not an `AppFailure`.

## 9. Edge Cases

- Format v1 is still accepted if envelope fields match (`minSupportedBackupFormatVersion`).
- Empty image set still calls `installReplace({})` when a blob store exists.
- New-account restore rolls back the created user if unlock or persist fails.
- `validateEnvelope` logs `backupFormatVersion` constant (2), not the file’s version (implementation of `_log` after decode).
- File pick with empty bytes → `InvalidBackupFormatFailure`.

## 10. Testing

- `test/feature/backup/backup_service_test.dart`
- `test/feature/backup/backup_envelope_codec_test.dart`
- `test/feature/backup/backup_file_service_test.dart`
- `test/feature/backup/backup_file_names_test.dart`
- `test/feature/backup/backup_images_test.dart`
- `test/feature/backup/backup_restore_auth_test.dart`
- `test/feature/backup/backup_restore_lock_test.dart`
- `test/feature/backup/backup_restore_multi_account_test.dart`
- `test/feature/backup/backup_restore_new_account_test.dart`
- `test/feature/backup/backup_restore_view_test.dart`
- `test/feature/backup/backup_restore_home_test.dart`
- `test/feature/backup/restore_progress_test.dart`
- `test/core/security/backup_password_policy_test.dart`

## 11. Technical Decisions

- Independent backup password so sharing a backup file does not reveal the Master Password and so a password change does not invalidate backups.
- Same Argon2id + AES-GCM stack as vault wrapping.
- Envelope keeps GCM tag as a separate JSON field (not concatenated).
- Images included in the encrypted payload (format version 2 path) rather than sidecar files.

## 12. Limitations / Notes

- Pick filter is not limited to `.keyva`.
- Backup password policy equals Master Password policy (length only), not a stronger unique policy.
- Restore-new-account maps many failures to `BackupRestorePersistenceFailure`, hiding underlying `AppFailure` types.
- UserRecord (KDF salt for master wrap) is **not** inside the backup; a restored new account gets a new wrap.

## 13. Summary

A `.keyva` file is a JSON envelope: KDF salt/params plus AES-GCM ciphertext of vault JSON and image blobs, keyed by a backup password. Create runs only while unlocked. Restore decrypts, then either replaces the current `VaultData` or creates a new local account, re-encrypting under that account’s Vault Key.

Related: [Argon2id](02_argon2id_key_derivation.md), [AES-GCM](03_vault_encryption_aes_gcm.md), [Multi-Account](14_multi_account_management.md), [Vault Lifecycle](17_vault_process_lifecycle.md).
