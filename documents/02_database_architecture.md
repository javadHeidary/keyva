حتماً. می‌ریم سراغ **Document شماره ۲: Database Architecture**. این فایل باید دقیقاً مشخص کند Cursor دیتابیس Keyva را چطور بسازد، اما هنوز وارد جزئیات کدنویسی Cryptography نمی‌شویم.

# `02_database_architecture.md`

````md
# Keyva Database Architecture

## Purpose

This document defines the local database architecture of Keyva.

It specifies:

- Database technology
- Storage boundaries
- Hive boxes
- Records
- User/Vault relationship
- Persistence rules
- Database versioning
- Migration
- Atomic writes
- Data deletion
- Backup boundaries

Cryptographic implementation details are defined in:

`03_cryptography.md`

Authentication and session behavior are defined in:

`04_authentication_and_session.md`

---

# 1. Database Technology

Keyva uses:

- Hive CE

The database is fully local.

Keyva MUST NOT require an online database or remote server for normal operation.

---

# 2. Database Responsibilities

The database is responsible for persistent local storage.

It MUST store:

- User metadata
- Vault metadata
- Encrypted vault data
- Security configuration
- Database version information

The database MUST NOT store plaintext sensitive vault data.

---

# 3. Storage Architecture

The application MUST use a repository-based storage architecture.

Dependency direction:

UI
→ ViewModel
→ Repository
→ Data Source
→ Hive

UI and ViewModels MUST NOT directly access Hive.

Example:

```text
Presentation
    ↓
ViewModel
    ↓
Repository
    ↓
LocalDataSource
    ↓
Hive
````

---

# 4. Hive Boxes

Keyva SHOULD use separate logical boxes for different responsibilities.

Initial structure:

```text
users
vaults
app_settings
```

The exact box names MUST be centralized as constants and MUST NOT be scattered throughout the codebase.

---

# 5. Users Box

The `users` box stores account-level metadata.

It MUST NOT store the user's plaintext Master Password.

It MUST NOT store the plaintext Vault Key.

Conceptual structure:

```text
users
 ├── UserRecord A
 ├── UserRecord B
 └── UserRecord C
```

Each record represents one local Keyva account.

---

# 6. UserRecord

Conceptual model:

```text
UserRecord
├── id
├── username
├── createdAt
├── updatedAt
├── kdfSalt
├── kdfParameters
├── wrappedVaultKey
└── securitySettings
```

### Fields

#### id

Unique account identifier.

Type:

```text
String
```

Value:

UUID v4.

The ID MUST be generated during account creation.

The ID MUST remain stable for the lifetime of the account.

---

#### username

Display name of the account.

Requirements:

* Persian text
* Used for UX/display
* MUST NOT be used as an encryption key
* MUST NOT be used as the account's cryptographic identity

Changing the username MUST NOT affect the Vault Key or encrypted vault.

---

#### createdAt

Timestamp indicating when the account was created.

---

#### updatedAt

Timestamp indicating the last metadata update.

---

#### kdfSalt

Random salt used by the password-based key derivation function.

The salt is not secret.

It MAY be included in a backup.

---

#### kdfParameters

Parameters required to reproduce the password-derived key.

Conceptual structure:

```text
KdfParameters
├── algorithm
├── memoryCost
├── timeCost
└── parallelism
```

The exact values MUST be defined in the cryptography document.

The parameters MUST be stored so future versions can reproduce the same derivation process.

---

#### wrappedVaultKey

The Vault Key protected by the Master Password-derived key.

This field MUST contain only the wrapped/encrypted Vault Key.

The plaintext Vault Key MUST NOT be persisted.

---

#### securitySettings

Contains non-secret account security preferences.

Examples:

```text
SecuritySettings
├── biometricEnabled
├── pinEnabled
├── autoLockTimeout
└── preventScreenshots
```

Sensitive authentication material MUST NOT be stored directly inside this structure.

---

# 7. Vault Box

The `vaults` box stores the user's encrypted vault.

Conceptual structure:

```text
vaults
 ├── VaultRecord A
 ├── VaultRecord B
 └── VaultRecord C
```

Each VaultRecord belongs to exactly one User ID.

---

# 8. VaultRecord

Conceptual model:

```text
VaultRecord
├── userId
├── formatVersion
├── nonce
├── ciphertext
└── updatedAt
```

---

## userId

References the owning UserRecord.

Example:

```text
UserRecord.id
        ↓
VaultRecord.userId
```

There MUST be exactly one active VaultRecord for each User account.

---

## formatVersion

Identifies the encrypted vault data format.

Example:

```text
1
```

This allows future migrations.

---

## nonce

The AES-GCM nonce used for the current encrypted vault state.

The nonce is not secret.

A new nonce MUST be generated whenever the vault is re-encrypted.

A nonce MUST NOT be reused with the same encryption key.

---

## ciphertext

Contains the encrypted vault payload.

The plaintext vault MUST NOT be persisted.

The ciphertext MUST be produced using AES-256-GCM according to:

`03_cryptography.md`

---

## updatedAt

Timestamp indicating when the vault was last changed.

---

# 9. Vault Data Structure

The plaintext vault exists only after successful decryption.

Conceptual structure:

```text
VaultData
├── logins
├── bankCards
├── secureNotes
└── categories
```

Example:

```text
VaultData
│
├── Login[]
│   ├── title
│   ├── username
│   ├── password
│   └── website
│
├── BankCard[]
│   ├── title
│   ├── cardNumber
│   ├── cardHolder
│   └── expiryDate
│
├── SecureNote[]
│   ├── title
│   └── content
│
└── Category[]
    ├── id
    └── name
```

The exact domain fields MUST follow the feature-specific data models.

These values MUST exist only inside the encrypted vault when persisted.

---

# 10. Plaintext vs Persistent Data

The following data MAY exist in plaintext in the database because it is not secret:

```text
User ID
Username
CreatedAt
UpdatedAt
KDF Salt
KDF Parameters
Vault format version
Nonce
Security preferences
```

The following data MUST NOT exist in plaintext:

```text
Master Password
Vault Key
PIN
Login Passwords
Bank Card Numbers
Secure Note Content
Other sensitive vault data
```

---

# 11. Multi-User Storage

Keyva MUST support multiple local accounts.

Example:

```text
users
│
├── User A
├── User B
└── User C

vaults
│
├── Vault A → User A
├── Vault B → User B
└── Vault C → User C
```

Each VaultRecord MUST reference its owner through `userId`.

No vault may be shared between users.

---

# 12. Account Creation

When creating a new account:

1. Generate a unique User ID.
2. Validate the username.
3. Generate a cryptographically secure random KDF salt.
4. Generate a random Vault Key.
5. Derive a key from the Master Password.
6. Wrap the Vault Key.
7. Create the initial encrypted vault.
8. Persist UserRecord.
9. Persist VaultRecord.
10. Complete the transaction safely.

If any critical step fails, the account MUST NOT be left in a partially created state.

---

# 13. Account Loading

When the application starts:

1. Load local account metadata.
2. Do not decrypt vaults automatically.
3. Display the appropriate authentication flow.
4. Only unlock the selected account after successful authentication.

The application MUST NOT decrypt all user vaults at startup.

---

# 14. Vault Loading

After successful authentication:

```text
User Authentication
        ↓
Obtain Vault Key
        ↓
Load VaultRecord
        ↓
Verify AES-GCM
        ↓
Decrypt Vault
        ↓
Validate VaultData
        ↓
Create Active Session
```

The decrypted vault MUST remain in memory only while required by the active session.

---

# 15. Vault Update

When vault data changes:

```text
Load current vault
        ↓
Modify plaintext VaultData
        ↓
Validate VaultData
        ↓
Generate new nonce
        ↓
Encrypt entire Vault
        ↓
Persist new VaultRecord
```

The old plaintext vault MUST NOT be persisted.

The implementation SHOULD avoid unnecessary partial writes that could leave the database in an inconsistent state.

---

# 16. Atomic Persistence

Critical database operations SHOULD be atomic.

Important operations include:

* Account creation
* Vault update
* Master Password change
* Account deletion
* Restore

The implementation MUST prevent a failed operation from leaving partially updated security-critical records.

---

# 17. Database Version

The database MUST have an explicit schema version.

Example:

```text
databaseVersion: 1
```

The version MUST NOT be inferred from the existence of fields.

Future schema changes MUST increase the database version.

---

# 18. Database Migration

When a new application version changes the database schema:

```text
Existing Database
       ↓
Read Version
       ↓
Run Required Migration(s)
       ↓
Validate Result
       ↓
Open Database
```

Example:

```text
v1 → v2
v2 → v3
```

Migrations MUST be deterministic and testable.

Migration failures MUST NOT silently discard user data.

---

# 19. Vault Format Version

Database version and vault format version are separate concepts.

Example:

```text
Database Version = 3
Vault Format Version = 1
```

Database migrations handle storage schema.

Vault migrations handle the structure of decrypted/encrypted vault data.

They MUST NOT be treated as the same version.

---

# 20. Backup Format Version

Backup format has its own version.

Example:

```text
Backup Format Version = 1
```

Therefore Keyva maintains three independent version concepts:

```text
Database Version
Vault Format Version
Backup Format Version
```

---

# 21. Account Deletion

Deleting an account MUST remove all local records associated with that account.

Deletion includes:

```text
UserRecord
VaultRecord
Local unlock credentials
Active session state
```

Deletion MUST be performed carefully to avoid leaving orphaned records.

After deletion:

```text
users
    → User removed

vaults
    → Associated Vault removed
```

---

# 22. Orphan Vault Prevention

A VaultRecord MUST NOT exist without a valid UserRecord.

The repository layer MUST prevent orphaned vault records.

When deleting a user, the associated vault MUST also be deleted.

---

# 23. Backup Boundary

Backup MUST NOT directly serialize the raw Hive database.

The application MUST create a dedicated backup model.

Conceptual flow:

```text
Hive
 ↓
Read UserRecord + VaultRecord
 ↓
Create BackupModel
 ↓
Serialize
 ↓
.keyva
```

This prevents Hive's internal structure from becoming the public backup format.

---

# 24. Restore Boundary

Restore MUST NOT blindly import raw Hive records.

Flow:

```text
.keyva
 ↓
Parse BackupModel
 ↓
Validate format
 ↓
Validate versions
 ↓
Authenticate user
 ↓
Validate encrypted vault
 ↓
Create/replace local records
```

Invalid data MUST be rejected.

---

# 25. Backup Compatibility

Future versions MUST attempt to preserve backward compatibility with supported backup versions.

Example:

```text
Backup v1
 ↓
Keyva v3
 ↓
Migration
 ↓
Current format
```

Unsupported versions MUST produce a clear restore error.

---

# 26. Database Corruption

If Hive or the encrypted vault is corrupted:

* The application MUST NOT silently overwrite valid data.
* The encrypted vault MUST be treated as invalid if AES-GCM authentication fails.
* The user SHOULD be informed that the local vault cannot be opened.
* Backup/restore MUST be available as the recovery mechanism.

---

# 27. Data Integrity

Encryption provides cryptographic integrity for the encrypted vault.

The application MUST verify the authentication tag before trusting decrypted vault data.

Malformed decrypted data MUST also fail validation.

---

# 28. Repository Responsibilities

Repositories are responsible for:

* Loading users
* Creating users
* Updating user metadata
* Loading encrypted vaults
* Saving encrypted vaults
* Deleting accounts
* Coordinating local data sources
* Coordinating backup/restore operations

Repositories MUST NOT contain UI logic.

---

# 29. Data Source Responsibilities

The local data source is responsible for:

* Hive access
* Serialization/deserialization
* Box management
* Database initialization
* Low-level persistence operations

The data source MUST NOT contain UI or navigation logic.

---

# 30. Cryptography Boundary

Database code MUST NOT implement cryptographic algorithms directly.

Cryptographic operations MUST be delegated to dedicated security/crypto services.

Example:

```text
Repository
    ↓
CryptoService
    ↓
Encryption / Key Management
```

The database layer only persists the resulting data.

---

# 31. No Direct Hive Access From UI

Forbidden:

```dart
class LoginView extends StatelessWidget {
  final box = Hive.box(...);
}
```

Required architecture:

```text
View
 ↓
ViewModel
 ↓
Repository
 ↓
LocalDataSource
 ↓
Hive
```

---

# 32. Database Constants

Hive box names, keys, schema versions, and storage identifiers MUST be centralized.

Avoid:

```dart
Hive.box('users');
Hive.box('vaults');
```

throughout the application.

Use centralized constants instead.

---

# 33. Sensitive Data Rule

Any data that belongs to the encrypted vault MUST be considered sensitive by default.

If a new feature introduces sensitive data:

1. It MUST be added to `VaultData`.
2. It MUST NOT be stored directly in a plaintext Hive box.
3. It MUST be encrypted as part of the vault.
4. The security architecture MUST be reviewed if the new data requires different handling.

---

# 34. Implementation Rule

Cursor MUST follow this database architecture exactly.

Cursor MUST NOT:

* Store plaintext vault data in Hive.
* Store Master Password in Hive.
* Store plaintext Vault Key in Hive.
* Create one Hive box per vault item.
* Let UI access Hive directly.
* Serialize raw Hive boxes as the backup format.
* silently discard data during migration.
* invent a second database architecture.

If a requested implementation conflicts with this document, Cursor MUST stop and report the conflict before changing the architecture.

````
