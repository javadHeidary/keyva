
# `07_account_lifecycle.md`

````md
# Keyva Account Lifecycle Specification

## Purpose

This document defines the complete lifecycle of a Keyva account.

It covers:

- Account creation
- Account activation
- Account unlock
- Account locking
- Logout
- Account switching
- Username change
- Master Password change
- PIN lifecycle
- Biometric lifecycle
- Account deletion
- Restore lifecycle

This document works together with:

- 01_security_architecture.md
- 02_database_architecture.md
- 03_cryptography.md
- 04_authentication_and_session.md
- 05_data_models.md
- 06_backup_and_restore.md

---

# 1. Account Identity

Every Keyva account has a unique User ID.

```text
User ID
   ↓
Account Identity
````

The User ID is the real identity of the account.

The username is only a user-facing display value.

```text
User ID       = Identity
Username      = Display / UX
Master Password = Authentication Secret
```

---

# 2. Account Lifecycle

The complete lifecycle is:

```text
No Account
    ↓
Create Account
    ↓
Active / Unlocked
    ↓
Locked
    ↓
Unlocked
    ↓
Locked / Logout
    ↓
Delete Account
```

Backup/Restore is an additional lifecycle path:

```text
Backup
  ↓
Restore
  ↓
Account Created Locally
```

---

# 3. Account Creation

Account creation MUST follow this sequence:

```text
User enters username
        ↓
User enters Master Password
        ↓
Confirm Master Password
        ↓
Validate input
        ↓
Generate User ID
        ↓
Generate KDF Salt
        ↓
Generate Vault Key
        ↓
Derive Key using Argon2id
        ↓
Wrap Vault Key
        ↓
Create empty VaultData
        ↓
Encrypt VaultData
        ↓
Persist UserRecord
        ↓
Persist VaultRecord
        ↓
Create Session
        ↓
Open Vault
```

---

# 4. Account Creation Atomicity

Account creation is one logical transaction.

The application MUST NOT create only part of the account.

Invalid state:

```text
UserRecord exists
VaultRecord does not exist
```

Valid state:

```text
UserRecord
     +
VaultRecord
```

If any step fails, the application MUST clean up the incomplete account creation.

---

# 5. Initial Vault

Every newly created account MUST start with a valid empty vault.

Conceptual:

```text
VaultData
├── logins = []
├── bankCards = []
├── secureNotes = []
└── categories = []
```

The empty vault MUST still be encrypted using the Vault Key.

---

# 6. Account Activation

After successful account creation:

```text
Account Created
      ↓
Session Created
      ↓
Account = Unlocked
```

The user SHOULD NOT be forced to log in again immediately after registration.

---

# 7. First Session

The first session is created only after:

- UserRecord persisted successfully.
    
- VaultRecord persisted successfully.
    
- Vault encryption succeeded.
    
- Vault integrity verified.
    

Then:

```text
Session
├── userId
├── vaultKey
└── decryptedVault
```

Sensitive session information exists only while required.

---

# 8. Account Unlock

Unlocking an existing account:

```text
Locked
  ↓
Select Account
  ↓
Authentication
  ↓
Recover Vault Key
  ↓
Decrypt Vault
  ↓
Validate Vault
  ↓
Create Session
  ↓
Unlocked
```

---

# 9. Account Lock

Locking does not modify the persistent account.

```text
Lock
 ↓
Clear Session
 ↓
Account remains in database
 ↓
State = Locked
```

The following remain persisted:

```text
UserRecord
VaultRecord
```

---

# 10. Logout

Logout ends the active session.

```text
Unlocked
   ↓
Logout
   ↓
Clear Session
   ↓
Return to Account Authentication
```

Logout MUST NOT:

- Delete account.
    
- Delete vault.
    
- Change Master Password.
    
- Change Vault Key.
    
- Disable security settings.
    

---

# 11. Account Switching

When multiple accounts exist:

```text
Account A
    ↓
Logout / Switch
    ↓
Clear Session A
    ↓
Select Account B
    ↓
Authenticate B
    ↓
Create Session B
```

Account A's Vault Key MUST NOT remain active after switching.

---

# 12. Account Isolation

Each account has its own:

```text
User ID
Salt
Vault Key
Wrapped Vault Key
VaultRecord
VaultData
Security settings
```

No account may access another account's vault.

---

# 13. Username Change

Username is a UX/display property.

Changing it:

```text
Old Username
     ↓
New Username
```

MUST NOT change:

```text
User ID
Vault Key
Wrapped Vault Key
Master Password
Encrypted Vault
```

Only the UserRecord metadata changes.

---

# 14. Username Validation

Username MUST:

- Be non-empty.
    
- Follow the Persian username requirements.
    
- Follow the application's length limits.
    

Username validation MUST be centralized.

---

# 15. Master Password Change

Master Password change requires an authenticated session.

Flow:

```text
Unlocked
   ↓
Enter Current Master Password
   ↓
Verify Current Password
   ↓
Enter New Master Password
   ↓
Confirm New Password
   ↓
Generate New Salt
   ↓
Derive New Key
   ↓
Re-wrap Existing Vault Key
   ↓
Persist New Cryptographic Metadata
```

---

# 16. Master Password Change and Vault

Changing the Master Password MUST NOT require re-encrypting the vault.

Existing:

```text
Vault Key
   ↓
Encrypted Vault
```

remains unchanged.

Only the protection around the Vault Key changes:

```text
Old Derived Key
      ↓
Old Wrapped Vault Key

New Derived Key
      ↓
New Wrapped Vault Key
```

---

# 17. Master Password Change Failure

If the new cryptographic metadata cannot be successfully created:

```text
Old Master Password
Old Salt
Old Wrapped Vault Key
```

MUST remain valid.

The application MUST use an atomic update strategy.

---

# 18. Master Password Change Verification

Before replacing the old credentials:

```text
New Master Password
       ↓
New Derived Key
       ↓
Wrap Vault Key
       ↓
Immediately attempt unwrap
       ↓
Verify success
```

Only after successful verification should the old wrapped key be replaced.

---

# 19. PIN Lifecycle

PIN states:

```text
Disabled
   ↓
Enabled
   ↓
Changed
   ↓
Disabled
```

PIN is device-local convenience authentication.

It does not change the Vault Key.

---

# 20. PIN Enable

Requires:

```text
Authenticated Session
+
Device support
+
Valid PIN
```

Then:

```text
PIN Enabled
```

---

# 21. PIN Change

```text
Authenticated
   ↓
Change PIN
   ↓
Create New Secure PIN Credential
   ↓
Delete/Invalidate Old Credential
```

Vault data remains unchanged.

---

# 22. PIN Disable

```text
Authenticated
   ↓
Disable PIN
   ↓
Remove PIN Unlock Credential
```

Vault data remains unchanged.

---

# 23. Biometric Lifecycle

Biometric states:

```text
Disabled
   ↓
Enabled
   ↓
Disabled
```

Biometric credentials are device-specific.

---

# 24. Biometric Enable

Requires:

```text
Authenticated Session
+
Device biometric support
+
Successful OS biometric authentication
```

Then:

```text
Biometric Enabled
```

---

# 25. Biometric Disable

Requires an authenticated session.

Then:

```text
Remove Local Biometric Unlock Credential
```

The account and vault remain unchanged.

---

# 26. Security Settings Changes

Changes to security settings MUST be performed only from an authenticated session.

Examples:

```text
Change Master Password
Enable PIN
Disable PIN
Change PIN
Enable Biometric
Disable Biometric
Change Auto Lock
Change Screenshot Protection
```

---

# 27. Auto Lock

When auto-lock triggers:

```text
Unlocked
   ↓
Auto Lock
   ↓
Clear Session
   ↓
Locked
```

Persistent data remains unchanged.

---

# 28. Application Close

When the application is closed:

The behavior depends on the configured security policy.

The secure default is:

```text
App Closed
    ↓
Clear Session
    ↓
Next Launch = Locked
```

Keyva MUST NOT persist the active decrypted VaultData for automatic restoration.

---

# 29. Application Background

When the application enters the background:

```text
App Background
      ↓
Protect UI
      ↓
Start/Continue Auto-Lock Timer
```

If timeout expires:

```text
Clear Session
```

---

# 30. Account Deletion

Account deletion is irreversible unless a backup exists.

The application MUST show a clear warning before deletion.

Example:

```text
Delete Account

This permanently deletes this account and all
stored vault data from this device.

Make sure you have a backup before continuing.
```

---

# 31. Account Deletion Confirmation

Deletion SHOULD require explicit confirmation.

Recommended:

```text
Delete Account
      ↓
Warning
      ↓
Confirm
      ↓
Require Authentication
      ↓
Delete
```

Authentication before deletion prevents accidental or unauthorized deletion.

---

# 32. Account Deletion Order

Recommended order:

```text
1. Authenticate
2. Clear active session
3. Remove device-specific unlock credentials
4. Delete VaultRecord
5. Delete UserRecord
6. Verify deletion
7. Return to no-account state
```

---

# 33. Account Deletion Atomicity

If deletion fails:

```text
Do NOT report success.
```

The application MUST clearly report that deletion was incomplete.

The implementation SHOULD use a transaction or safe deletion strategy supported by the database layer.

---

# 34. Account Restore

Restoring a backup creates a local account.

Flow:

```text
Backup File
    ↓
Validate
    ↓
Read User ID
    ↓
Ask Master Password
    ↓
Derive Key
    ↓
Unwrap Vault Key
    ↓
Decrypt Vault
    ↓
Validate VaultData
    ↓
Create Local Records
    ↓
Restore Account
    ↓
Create Session
```

---

# 35. Restore Is Not Account Creation From Scratch

During restore, Keyva MUST preserve:

```text
Original User ID
Original Vault Key
Original Vault Data
Original KDF metadata
```

It MUST NOT generate a new Vault Key.

---

# 36. Restore and Device Credentials

After restore:

```text
PIN
Biometric
```

MUST be configured for the new device.

Device-specific credentials MUST NOT be blindly imported from the backup.

---

# 37. Account States

Recommended account-level state:

```text
AccountState
├── active
├── locked
└── deleted
```

`deleted` is primarily a lifecycle event rather than a persisted normal state.

---

# 38. Session vs Account State

These concepts MUST remain separate.

Example:

```text
Account = Exists
Session = Locked
```

This is valid.

Example:

```text
Account = Exists
Session = Unlocked
```

This is valid.

Deleted account:

```text
Account = Deleted
Session = None
```

---

# 39. Account Lifecycle and MVVM

Keyva uses MVVM.

Recommended flow:

```text
View
 ↓
ViewModel
 ↓
Repository
 ↓
Service / DataSource
 ↓
Hive
```

Example:

```text
CreateAccountView
        ↓
CreateAccountViewModel
        ↓
AuthRepository
        ↓
CryptoService + LocalDataSource
        ↓
Hive
```

---

# 40. ViewModel Responsibilities

ViewModels coordinate lifecycle operations.

Examples:

```text
CreateAccountViewModel
LoginViewModel
SecurityViewModel
SettingsViewModel
AccountSelectionViewModel
BackupViewModel
RestoreViewModel
```

ViewModels MUST NOT implement cryptography or direct Hive operations.

---

# 41. Repository Responsibilities

Repositories coordinate application operations.

Examples:

```text
AuthRepository
AccountRepository
VaultRepository
BackupRepository
```

Repositories MAY coordinate services and data sources.

---

# 42. Service Responsibilities

Examples:

```text
CryptoService
SessionService
BiometricService
PinService
```

Services provide technical functionality.

They MUST remain focused.

---

# 43. Lifecycle Events

Important lifecycle events:

```text
AccountCreated
AccountUnlocked
AccountLocked
AccountLoggedOut
AccountSwitched
UsernameChanged
MasterPasswordChanged
PinEnabled
PinDisabled
BiometricEnabled
BiometricDisabled
AccountRestored
AccountDeleted
```

These events MAY be represented internally if useful.

Do not introduce an event architecture solely for theoretical purity.

---

# 44. Data Consistency

The following relationship MUST always remain valid:

```text
UserRecord.id
      =
VaultRecord.userId
```

If this relationship is broken, the account MUST be considered invalid.

---

# 45. No Orphan Records

Keyva MUST prevent:

```text
VaultRecord without UserRecord
```

and:

```text
UserRecord without valid VaultRecord
```

unless the application is explicitly performing a controlled migration or recovery operation.

---

# 46. Security Principle

At every lifecycle transition:

```text
If uncertain → Lock
```

Security failures MUST fail closed.

The application MUST prefer requiring authentication again over exposing vault data.

---

# 47. Final Lifecycle

```text
                 ┌──────────────┐
                 │ No Account   │
                 └──────┬───────┘
                        │
                     Register
                        │
                        ▼
                 ┌──────────────┐
                 │   Unlocked   │
                 └──────┬───────┘
                        │
              ┌─────────┼─────────┐
              │         │         │
             Lock     Logout   Auto-Lock
              │         │         │
              └─────────┴─────────┘
                        │
                        ▼
                 ┌──────────────┐
                 │    Locked    │
                 └──────┬───────┘
                        │
                  Authenticate
                        │
                        ▼
                 ┌──────────────┐
                 │   Unlocked   │
                 └──────┬───────┘
                        │
                     Delete
                        │
                        ▼
                 ┌──────────────┐
                 │   Deleted    │
                 └──────────────┘
```

---

# 48. Final Implementation Rules

Cursor MUST:

- Treat User ID as account identity.
    
- Treat Username as UX/display data.
    
- Never use Username as a cryptographic identifier.
    
- Never regenerate User ID during normal account operations.
    
- Never regenerate Vault Key during normal account operations.
    
- Never re-encrypt the vault for a simple Master Password change.
    
- Keep PIN and Biometric device-specific.
    
- Keep account lifecycle separate from session lifecycle.
    
- Keep authentication separate from UI.
    
- Keep implementation compatible with MVVM + GetX.
    
- Use Repository/Service/DataSource boundaries.
    
- Never introduce unnecessary Clean Architecture layers.
    
- Use atomic operations for security-critical lifecycle changes.
    
- Fail closed when lifecycle state becomes uncertain.
    
