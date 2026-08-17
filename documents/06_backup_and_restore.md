# `06_backup_and_restore.md`

````md
# Keyva Backup & Restore Specification

## Purpose

This document defines the backup and restore architecture of Keyva.

Keyva is an offline-first local password manager.

Backup and Restore MUST preserve:

- User account identity
- Encrypted vault data
- Cryptographic metadata required for vault recovery
- Vault format version
- KDF configuration
- Wrapped Vault Key
- User vault data

Backup MUST NOT expose plaintext sensitive data.

---

# 1. Core Principle

A Keyva backup MUST be considered sensitive data.

The backup file MUST NOT contain:

- Master Password
- Plaintext Vault Key
- Derived Key
- Plaintext Login passwords
- Plaintext Bank Card data
- Plaintext Secure Notes
- Plaintext PIN

The backup MUST contain only the encrypted representation of the vault and the metadata required to restore it.

---

# 2. Backup Is Not a Database Dump

Keyva MUST NOT simply export the internal Hive database files as the public backup format.

Internal Hive storage and external backup format are separate concerns.

Conceptually:

```text
Hive Database
      ↓
Backup Service
      ↓
Backup Model
      ↓
Serialized Backup
      ↓
Backup File
````

This allows future Hive schema changes without breaking backup compatibility.

---

# 3. Backup Scope

A backup represents one Keyva account.

Conceptual structure:

```text
Backup
├── metadata
├── user
├── cryptography
└── encryptedVault
```

---

# 4. Backup Metadata

Backup metadata MAY contain:

```text
backupVersion
createdAt
appVersion
vaultFormatVersion
```

These fields are not considered secrets.

---

# 5. User Metadata

The backup MUST contain the information required to identify and restore the account.

Conceptual:

```text
UserBackup
├── userId
├── username
├── createdAt
└── updatedAt
```

The User ID MUST remain unchanged after restore.

---

# 6. Cryptographic Metadata

The backup MUST contain the cryptographic metadata required to derive the correct key and unwrap the Vault Key.

Conceptual:

```text
CryptoBackup
├── kdfAlgorithm
├── kdfSalt
├── kdfParameters
└── wrappedVaultKey
```

The backup MUST NOT contain the Master Password.

---

# 7. Encrypted Vault

The actual vault data is stored in encrypted form.

Conceptual:

```text
EncryptedVault
├── formatVersion
├── nonce
├── ciphertext
└── authenticationTag
```

The plaintext VaultData MUST NEVER be written to the backup file.

---

# 8. Complete Backup Structure

Conceptual:

```text
KeyvaBackup
│
├── backupVersion
├── createdAt
├── appVersion
│
├── user
│   ├── userId
│   ├── username
│   ├── createdAt
│   └── updatedAt
│
├── cryptography
│   ├── kdfAlgorithm
│   ├── kdfSalt
│   ├── kdfParameters
│   └── wrappedVaultKey
│
└── vault
    ├── formatVersion
    ├── nonce
    ├── ciphertext
    └── authenticationTag
```

---

# 9. Is the Backup Encrypted?

Yes.

The vault contained inside the backup is already encrypted using the Vault Key.

Therefore:

```text
Master Password
      ↓
Argon2id
      ↓
Derived Key
      ↓
Unwrap Vault Key
      ↓
Decrypt Vault
```

The backup stores:

```text
Wrapped Vault Key
+
Encrypted Vault
```

not plaintext vault data.

---

# 10. Backup Encryption Layer

The existing vault encryption MUST remain the primary confidentiality mechanism.

Keyva SHOULD NOT unnecessarily decrypt the entire vault and then create another custom encryption layer for the basic backup format.

The backup MUST preserve the existing encrypted vault representation.

---

# 11. Optional Backup Container Encryption

If an additional backup-password layer is introduced in the future, it MUST be documented as a separate cryptographic layer.

It MUST NOT replace the existing Vault Key architecture.

Current Keyva scope:

```text
Backup
    ↓
Contains encrypted vault
```

No additional backup password is required for the initial implementation.

---

# 12. Backup Creation Flow

Backup creation requires an authenticated/unlocked session.

Flow:

```text
Unlocked Session
      ↓
Load current Vault state
      ↓
Validate VaultData
      ↓
Read encrypted VaultRecord
      ↓
Read UserRecord cryptographic metadata
      ↓
Build BackupModel
      ↓
Serialize
      ↓
Write backup file
```

The backup SHOULD use the existing encrypted vault representation rather than decrypting and re-encrypting the entire vault.

---

# 13. Backup Does Not Require Master Password

If the user is already authenticated and the vault is unlocked:

```text
Unlocked Session
      ↓
Create Backup
```

The application does not need to ask the Master Password again for the basic backup operation.

The backup process MUST NOT expose the Master Password.

---

# 14. Backup File

The backup MUST be a portable application-level format.

Recommended:

```text
.keyva
```

The exact serialization format MAY be JSON, binary, or another deterministic format.

For the initial implementation, the format MUST prioritize:

* Portability
* Versioning
* Integrity
* Easy migration
* Cross-platform compatibility

---

# 15. Backup Integrity

The backup MUST be validated before being accepted.

Validation MUST include:

* Backup version
* Required fields
* User ID
* KDF parameters
* Salt
* Wrapped Vault Key
* Vault encryption metadata
* Vault format version

The encrypted vault authentication tag MUST be verified during restore.

---

# 16. Restore Flow

Restore on another device:

```text
Select Backup
      ↓
Read Backup
      ↓
Validate Backup Structure
      ↓
Read User Metadata
      ↓
Read KDF Salt
      ↓
Read KDF Parameters
      ↓
Read Wrapped Vault Key
      ↓
Ask User for Master Password
      ↓
Run Argon2id
      ↓
Derived Key
      ↓
Attempt Vault Key Unwrap
      ↓
Decrypt Vault
      ↓
Verify Authentication Tag
      ↓
Validate VaultData
      ↓
Create Local Account
      ↓
Persist Restored Data
      ↓
Create Session
      ↓
Open Vault
```

---

# 17. Master Password During Restore

The backup does NOT contain the Master Password.

The user MUST provide the Master Password manually during restore.

The process is:

```text
Backup
  ↓
Read Salt
  ↓
User enters Master Password
  ↓
Argon2id
  ↓
Derived Key
  ↓
Unwrap Vault Key
```

If the password is correct, the Vault Key can be recovered.

---

# 18. Why the Master Password Is Not in the Backup

The Master Password is intentionally absent from the backup.

If the backup contained the Master Password:

```text
Backup stolen
      ↓
Master Password exposed
      ↓
Vault compromised
```

Instead:

```text
Backup
  ↓
Wrapped Vault Key
```

The attacker still needs the correct Master Password to derive the Derived Key and unwrap the Vault Key.

---

# 19. Restore on a New Device

The restored account receives the same:

```text
User ID
Vault data
Vault Key
KDF Salt
KDF Parameters
```

The local device may generate new device-specific security credentials.

Therefore:

```text
Account Identity
       ≠
Device Identity
```

---

# 20. Device-Specific Security

PIN and biometric credentials MUST NOT be copied directly from one device to another.

The backup MUST NOT contain:

```text
PIN
Biometric configuration
Device secure-storage keys
Device-specific authentication tokens
```

After restore:

```text
Restore Account
      ↓
Vault available after Master Password authentication
      ↓
User may configure PIN / Biometric on new device
```

---

# 21. Restore Security Settings

General account-level settings MAY be restored.

Device-specific authentication settings MUST NOT be restored blindly.

For example:

```text
May restore:
- Auto-lock preference
- Screenshot protection preference

Must NOT restore:
- Device biometric credential
- Device secure-storage secret
- Device PIN secret
```

The exact list MUST remain explicit in the backup schema.

---

# 22. Existing Account Conflict

If the target device already contains an account with the same User ID:

```text
Existing User ID
        +
Imported User ID
```

Keyva MUST NOT silently overwrite the existing account.

The user MUST be shown an explicit conflict flow.

Possible options:

```text
Cancel
Replace Existing Account
Restore as New Local Account
```

The exact UX should be finalized during implementation.

---

# 23. Restore Atomicity

Restore MUST be atomic from the user's perspective.

The application MUST NOT create a partially restored account.

Safe flow:

```text
Read Backup
   ↓
Validate
   ↓
Authenticate
   ↓
Decrypt
   ↓
Validate VaultData
   ↓
Prepare Local Records
   ↓
Commit
```

Only after successful validation should the restored account be persisted.

---

# 24. Failed Restore

If restore fails:

```text
Existing local data
        ↓
MUST remain unchanged
```

Do NOT delete the existing account before successful restore.

---

# 25. Wrong Master Password During Restore

If the Master Password is incorrect:

```text
Entered Password
      ↓
Argon2id
      ↓
Wrong Derived Key
      ↓
Vault Key unwrap fails
```

Result:

```text
Restore Failed
```

The application MUST NOT modify local data.

---

# 26. Corrupted Backup

If the backup is corrupted:

```text
Backup
  ↓
Validation
  ↓
Failure
```

Keyva MUST:

* Reject the backup.
* Keep existing local data unchanged.
* Show a generic user-friendly error.
* Never import partially corrupted data.

---

# 27. Tampered Backup

If an attacker modifies encrypted vault data:

```text
Modified Ciphertext
       ↓
AES-GCM Verification
       ↓
Authentication Failure
```

The vault MUST NOT be restored.

---

# 28. Backup Versioning

Every backup MUST contain:

```text
backupVersion
```

Example:

```text
backupVersion = 1
```

Future versions may change the structure.

The application MUST explicitly support known versions.

Unknown versions MUST NOT be silently imported.

---

# 29. Vault Versioning

Backup MUST preserve the vault format version.

Example:

```text
backupVersion = 1
vaultFormatVersion = 1
```

These are separate concepts.

---

# 30. Backup Migration

If a future backup version is introduced:

```text
Old Backup
    ↓
Detect Version
    ↓
Migration
    ↓
Current Backup Model
    ↓
Restore
```

Migration MUST NOT silently reinterpret incompatible data.

---

# 31. Exported Backup File Safety

The application SHOULD warn the user that:

> The backup file contains encrypted sensitive information. Keep it in a secure location and do not share it publicly.

The warning MUST NOT reveal unnecessary technical details.

---

# 32. Backup File Naming

Recommended format:

```text
keyva_backup_YYYYMMDD_HHmmss.keyva
```

The filename MUST NOT contain:

* Master Password
* PIN
* Vault contents
* Sensitive credentials

---

# 33. Backup Location

The backup process MUST use platform-approved file access mechanisms.

The application SHOULD allow the user to choose where the backup is saved.

Keyva MUST NOT silently upload backups to an external server.

---

# 34. Cloud Storage

Keyva is local-first.

The initial backup system MUST NOT automatically upload backups to:

* Keyva servers
* Firebase
* Supabase
* Google Drive
* Dropbox
* Other cloud providers

Cloud integration MAY be added later as a separate feature.

---

# 35. Backup Does Not Mean Sync

Backup:

```text
Manual Snapshot
```

Sync:

```text
Continuous / Automated Data Replication
```

Keyva currently implements:

```text
Backup + Restore
```

not synchronization.

---

# 36. Multiple Accounts

Each backup represents one account.

If the user has:

```text
Account A
Account B
Account C
```

the application SHOULD generate:

```text
Backup A
Backup B
Backup C
```

rather than creating one ambiguous backup file.

---

# 37. Backup Repository

The backup functionality SHOULD follow MVVM architecture.

Conceptual:

```text
BackupView
     ↓
BackupViewModel
     ↓
BackupRepository
     ↓
BackupDataSource
     ↓
File System
```

The BackupViewModel MUST NOT directly manipulate files.

---

# 38. Restore Repository

Conceptual:

```text
RestoreView
     ↓
RestoreViewModel
     ↓
BackupRepository
     ↓
BackupDataSource
     ↓
File System
```

Cryptographic operations MUST be delegated to the existing CryptoService.

---

# 39. MVVM Rule

Backup/Restore MUST remain compatible with the existing Keyva architecture:

```text
View
 ↓
ViewModel
 ↓
Repository / Service
 ↓
DataSource
```

Do NOT introduce:

* UseCases
* Interactors
* Domain layer
* Clean Architecture layers

only for backup functionality.

---

# 40. Memory Safety

During backup and restore:

* Do not log decrypted VaultData.
* Do not log passwords.
* Do not log card numbers.
* Do not log Master Password.
* Do not persist plaintext temporary files.
* Remove temporary references when no longer required.

---

# 41. Temporary Files

If temporary files are required:

```text
Create
  ↓
Use
  ↓
Delete
```

Temporary plaintext vault files MUST NOT be created.

The preferred implementation is to operate on encrypted data in memory whenever practical.

---

# 42. Backup Validation Before Export

Before creating a backup:

```text
Check Session
     ↓
Check Vault
     ↓
Check UserRecord
     ↓
Check Cryptographic Metadata
     ↓
Create Backup
```

If any required component is invalid:

```text
Do not create backup
```

---

# 43. Restore Validation Before Commit

Restore MUST verify:

1. Backup structure.
2. Backup version.
3. User metadata.
4. KDF parameters.
5. Wrapped Vault Key.
6. Master Password.
7. Vault Key unwrap.
8. Vault AES-GCM authentication.
9. VaultData structure.
10. Required model fields.

Only then:

```text
Commit Restore
```

---

# 44. Restore and Master Password

The restored account keeps the same Master Password.

The backup does NOT generate a new password.

Conceptual:

```text
Original Device

Master Password
      ↓
Derived Key
      ↓
Vault Key
```

After restore:

```text
New Device

Same Master Password
      ↓
Same KDF Salt + Parameters
      ↓
Same Derived Key
      ↓
Unwrap Same Vault Key
      ↓
Decrypt Same Vault
```

---

# 45. Important Cryptographic Principle

The Vault Key is independent from the device.

Therefore the encrypted vault can be restored on another device as long as the user has:

```text
Backup
+
Correct Master Password
```

Device-specific PIN/Biometric credentials are NOT required for the initial restore.

---

# 46. Backup Deletion

Deleting a backup file from Keyva MUST NOT delete the local account.

Backup and local vault are independent.

---

# 47. Local Database vs Backup

The relationship is:

```text
Local Hive
    │
    │ export
    ▼
Backup File
```

and:

```text
Backup File
    │
    │ restore
    ▼
Local Hive
```

The backup is portable.

Hive remains an implementation detail of the local database.

---

# 48. Backup Compatibility

A valid backup SHOULD remain restorable across:

* Application updates
* Minor schema changes
* Device changes
* Platform changes

as long as the supported backup version remains compatible.

---

# 49. App Update Compatibility

An application update MUST NOT require deleting the existing database.

Normal update:

```text
Old App
   ↓
App Update
   ↓
Existing Hive Database
   ↓
Database Migration if required
   ↓
Existing Account
```

The user should NOT need to create a new account after a normal application update.

---

# 50. Reinstallation

Reinstallation behavior depends on the operating system and whether application data is preserved.

Keyva MUST NOT assume that reinstalling always preserves local data.

If local data is removed:

```text
Reinstall
   ↓
Fresh Local Database
   ↓
Restore from .keyva Backup
```

The backup becomes the recovery mechanism.

---

# 51. Backup Testing Requirements

Before release, backup/restore MUST be tested for:

### Same device

```text
Create Backup
Delete/Test Account
Restore
Verify Vault
```

### Different device

```text
Device A
Create Backup
       ↓
Transfer Backup
       ↓
Device B
Restore
       ↓
Verify Vault
```

### Wrong Password

```text
Backup
+
Wrong Master Password
=
Restore MUST Fail
```

### Corrupted Backup

```text
Modified Backup
=
Restore MUST Fail
```

### App Update

```text
Old Version
 ↓
Update
 ↓
Existing Vault MUST Remain Accessible
```

---

# 52. Data Verification After Restore

After successful restore, Keyva MUST verify:

* Number of Login items
* Number of Bank Cards
* Number of Secure Notes
* Number of Categories
* Item IDs
* Item contents
* Vault version

The restored data MUST match the backup source.

---

# 53. Backup Architecture Summary

```text
                Local Vault
                    │
                    ▼
              VaultRecord
                    │
                    ▼
             BackupRepository
                    │
                    ▼
               BackupModel
                    │
                    ▼
              .keyva File
```

Restore:

```text
               .keyva File
                    │
                    ▼
              BackupModel
                    │
                    ▼
             Validate Backup
                    │
                    ▼
            Master Password
                    │
                    ▼
               Argon2id
                    │
                    ▼
              Derived Key
                    │
                    ▼
            Unwrap Vault Key
                    │
                    ▼
            Decrypt Vault
                    │
                    ▼
              Validate Data
                    │
                    ▼
             Local Hive
                    │
                    ▼
                Session
```

---

# 54. Final Rules

Cursor MUST:

* Treat backup as sensitive.
* Never include Master Password in backup.
* Never include plaintext vault data.
* Never include plaintext Vault Key.
* Never include PIN or biometric secrets.
* Preserve KDF metadata.
* Preserve Wrapped Vault Key.
* Preserve encrypted VaultRecord.
* Validate before restore.
* Restore atomically.
* Never overwrite existing data silently.
* Never require app reinstallation for normal updates.
* Keep Backup/Restore compatible with MVVM.
* Use repositories/services rather than putting file logic in ViewModels.
* Never introduce unnecessary Clean Architecture layers.