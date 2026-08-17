
# `04_authentication_and_session.md`

````md
# Keyva Authentication & Session Architecture

## Purpose

This document defines authentication, vault unlocking, session management, locking, logout, PIN, biometric authentication, and application lifecycle behavior in Keyva.

This document works together with:

- `01_security_architecture.md`
- `02_database_architecture.md`
- `03_cryptography.md`

Authentication MUST NOT bypass the cryptographic architecture defined in those documents.

---

# 1. Authentication Model

Keyva is a local-only application.

There is no:

- Server authentication
- Email authentication
- Cloud authentication
- Online account recovery

Authentication happens entirely on the local device.

---

# 2. Authentication Methods

Keyva supports:

1. Master Password
2. PIN
3. Biometric Authentication

The Master Password is the primary account credential.

PIN and Biometric are local convenience unlock mechanisms.

They MUST NOT replace the Master Password permanently.

---

# 3. Authentication vs Authorization

Authentication answers:

> "Is the user allowed to unlock this account?"

Authorization answers:

> "Does the current session have access to this vault?"

After successful authentication:

```text
Authentication
      ↓
Vault Unlock
      ↓
Active Session
      ↓
Vault Access
````

The application MUST NOT consider the user authenticated merely because an account exists in the database.

---

# 4. Application Startup

When Keyva starts:

```text
App Start
   ↓
Initialize Database
   ↓
Load Local Accounts
   ↓
Determine Application State
   ↓
Show Authentication UI
```

Keyva MUST NOT automatically decrypt vault data during application startup.

---

# 5. Initial Application State

If no account exists:

```text
App Start
   ↓
No Users
   ↓
Onboarding / Registration
```

If one or more accounts exist:

```text
App Start
   ↓
Users Exist
   ↓
Authentication / Account Selection
```

---

# 6. Multiple Accounts

Keyva supports multiple local accounts.

Example:

```text
Account A
Account B
Account C
```

The user MUST explicitly select which account they want to unlock when multiple accounts exist.

The selected User ID determines:

- Salt
    
- KDF parameters
    
- Wrapped Vault Key
    
- VaultRecord
    
- Security settings
    

---

# 7. Registration Flow

Registration flow:

```text
Onboarding
   ↓
Create Account
   ↓
Enter Username
   ↓
Enter Master Password
   ↓
Confirm Master Password
   ↓
Validate Input
   ↓
Generate User ID
   ↓
Generate Salt
   ↓
Generate Vault Key
   ↓
Derive Key with Argon2id
   ↓
Wrap Vault Key
   ↓
Create Initial Vault
   ↓
Persist Account
   ↓
Create Session
   ↓
Open Vault
```

---

# 8. Registration Validation

Before creating an account:

### Username

- MUST be non-empty.
    
- MUST contain Persian characters according to the application's validation rules.
    
- MUST satisfy the defined username length constraints.
    

### Master Password

- MUST satisfy the application's password strength requirements.
    
- MUST match the confirmation password.
    

The exact password policy MUST be centralized and MUST NOT be duplicated across screens.

---

# 9. Registration Persistence

Account creation MUST be treated as one logical operation.

The application MUST NOT leave:

```text
UserRecord
```

without its corresponding:

```text
VaultRecord
```

If account creation fails:

```text
Do not leave a partially created account.
```

---

# 10. Master Password Login

Master Password login flow:

```text
User selects account
        ↓
Enter Master Password
        ↓
Load UserRecord
        ↓
Read Salt + KDF Parameters
        ↓
Run Argon2id
        ↓
Derived Key
        ↓
Unwrap Vault Key
        ↓
Load VaultRecord
        ↓
Decrypt Vault
        ↓
Verify AES-GCM
        ↓
Validate VaultData
        ↓
Create Session
        ↓
Open Home
```

---

# 11. Wrong Master Password

The application MUST NOT compare plaintext passwords.

Instead:

```text
Entered Password
      ↓
Argon2id
      ↓
Derived Key
      ↓
Attempt to unwrap Vault Key
```

If authentication fails:

```text
Unlock Failed
```

The UI MUST NOT reveal whether the failure happened because of:

- Wrong password
    
- Invalid wrapped key
    
- Invalid encrypted vault
    

The user should receive a generic message.

---

# 12. Master Password Is Never Stored

At no point may Keyva persist:

```text
Master Password
```

This includes:

- Hive
    
- Shared Preferences
    
- Secure Storage
    
- Logs
    
- Backup
    
- Analytics
    
- Crash reports
    

The Master Password is only used during authentication/key derivation.

---

# 13. Session

A Session represents the period during which a vault is unlocked.

Conceptual:

```text
Locked
   ↓
Successful Authentication
   ↓
Unlocked Session
   ↓
Vault Access
```

The session MUST contain only the minimum information required for application operation.

---

# 14. Session State

Recommended conceptual states:

```text
AppState
├── Initializing
├── NoAccount
├── Locked
├── Authenticating
├── Unlocking
├── Unlocked
├── Locking
└── Error
```

The application MUST use a centralized state model rather than allowing individual screens to independently determine authentication state.

---

# 15. Active Session

While unlocked, the session MAY hold:

```text
Active User ID
Active Vault Key
Decrypted Vault State
Authentication State
```

The session MUST NOT persist the Vault Key to disk.

The Master Password MUST NOT be retained unnecessarily.

---

# 16. Session Creation

A session is created only after:

1. Authentication succeeds.
    
2. Vault Key is successfully obtained.
    
3. Encrypted vault is successfully authenticated.
    
4. Vault data passes validation.
    

Only then:

```text
Session = Unlocked
```

---

# 17. Session Destruction

When the vault is locked or the user logs out:

```text
Session
   ↓
Clear active state
   ↓
Vault = Locked
```

The application MUST release references to:

- Vault Key
    
- Decrypted vault state
    
- Sensitive temporary values
    

The implementation MUST NOT claim guaranteed memory zeroization in Dart.

---

# 18. Manual Lock

The user can manually lock the application.

Flow:

```text
Unlocked
   ↓
Lock
   ↓
Clear Session
   ↓
Locked
   ↓
Authentication Required
```

The database remains unchanged.

The account is NOT deleted.

---

# 19. Logout

Logout is different from Lock.

### Lock

Keeps the account available for quick re-authentication.

```text
Vault
 ↓
Locked
 ↓
Same account can be unlocked again
```

### Logout

Ends the active account session.

```text
Vault
 ↓
Session cleared
 ↓
Account authentication screen
```

Logout MUST NOT delete the account.

---

# 20. Auto Lock

Keyva supports automatic locking.

Initial options:

```text
Immediately
30 seconds
1 minute
5 minutes
```

The configured timeout is stored as a non-secret setting.

---

# 21. Auto Lock Trigger

The application SHOULD monitor:

- App lifecycle
    
- User inactivity where required
    
- Background duration
    

When the configured timeout is reached:

```text
Unlocked
   ↓
Auto Lock
   ↓
Session cleared
   ↓
Locked
```

---

# 22. Background Behavior

When the application enters background:

```text
App → Background
```

Keyva MUST:

1. Protect sensitive UI from app previews.
    
2. Track background duration.
    
3. Trigger Auto Lock when required.
    

The exact lifecycle behavior MUST be centralized in an application/session controller.

Individual screens MUST NOT implement their own independent auto-lock logic.

---

# 23. App Resume

When the application returns to foreground:

```text
Background
   ↓
Resume
   ↓
Check Session State
```

If still unlocked:

```text
Continue Session
```

If auto-lock timeout expired:

```text
Show Authentication
```

---

# 24. PIN Authentication

PIN is a local unlock method.

Flow:

```text
Locked
   ↓
PIN Authentication
   ↓
Validate PIN using secure local mechanism
   ↓
Unlock Vault
   ↓
Create Session
```

The PIN MUST NOT directly encrypt or decrypt the vault.

---

# 25. PIN Requirements

PIN:

- MUST be numeric.
    
- MUST contain at least 6 digits.
    
- MUST NOT be stored in plaintext.
    
- MUST be protected against repeated guessing.
    

The application MUST NOT implement:

```text
PIN → SHA256 → AES Key
```

or any equivalent custom scheme.

---

# 26. PIN Failed Attempts

Keyva MUST protect against repeated PIN guessing.

Conceptual behavior:

```text
Failed Attempt
   ↓
Increment Counter
   ↓
Apply Rate Limit
```

After excessive failures:

```text
PIN Locked
   ↓
Require Master Password
```

The exact thresholds MUST be centralized in security configuration.

---

# 27. PIN Setup

PIN setup requires successful authentication first.

Flow:

```text
Unlocked
   ↓
Security Settings
   ↓
Enable PIN
   ↓
Confirm Current Authentication
   ↓
Enter PIN
   ↓
Confirm PIN
   ↓
Create Secure PIN Unlock Mechanism
   ↓
Enable PIN
```

The PIN MUST NOT be created without first proving access to the account.

---

# 28. PIN Change

Changing the PIN requires:

1. Current authenticated session.
    
2. User confirmation.
    
3. New PIN.
    
4. New secure PIN unlock mechanism.
    

Changing the PIN MUST NOT require re-encrypting the vault.

---

# 29. Disable PIN

Disabling PIN requires successful current authentication.

Flow:

```text
Authenticated Session
   ↓
Disable PIN
   ↓
Remove PIN Unlock Mechanism
   ↓
PIN Disabled
```

Vault data remains unchanged.

---

# 30. Biometric Authentication

Biometric authentication is delegated to the operating system.

Keyva MUST use the platform's biometric authentication APIs.

Keyva MUST NOT:

- Store biometric templates.
    
- Process fingerprints.
    
- Process face recognition data.
    
- Implement custom biometric matching.
    

---

# 31. Biometric Setup

Biometric setup requires:

1. Existing authenticated session.
    
2. Device biometric availability.
    
3. Successful biometric enrollment/authentication.
    
4. Creation/activation of a secure local unlock mechanism.
    

Flow:

```text
Unlocked
   ↓
Enable Biometric
   ↓
OS Biometric Authentication
   ↓
Secure Local Credential
   ↓
Biometric Enabled
```

---

# 32. Biometric Authentication

When the user chooses biometric unlock:

```text
Locked
   ↓
Request OS Biometric Authentication
   ↓
Authentication Success
   ↓
Secure Local Unlock
   ↓
Obtain Vault Key
   ↓
Create Session
   ↓
Open Home
```

If biometric authentication fails:

```text
Biometric Failed
```

The user MAY fall back to another enabled authentication method.

---

# 33. Authentication Priority

When multiple authentication methods are enabled:

```text
Biometric
   ↓
PIN
   ↓
Master Password
```

The UI SHOULD present the preferred available method first.

The Master Password MUST always remain available as the fundamental recovery/unlock method unless the account is being deleted.

---

# 34. Fallback Authentication

If biometric authentication fails:

```text
Biometric Failed
       ↓
Offer PIN
```

If PIN is unavailable or fails:

```text
Offer Master Password
```

If all authentication attempts fail:

```text
Remain Locked
```

---

# 35. Master Password as Ultimate Local Credential

Keyva's authentication hierarchy is:

```text
                Master Password
                       │
             ┌─────────┴─────────┐
             │                   │
            PIN             Biometric
             │                   │
             └─────────┬─────────┘
                       ↓
                  Vault Unlock
```

PIN and Biometric are convenience mechanisms.

The Master Password remains the primary cryptographic credential.

---

# 36. Security Settings Changes

Changes to security settings MUST require an authenticated session.

Examples:

- Enable PIN
    
- Disable PIN
    
- Change PIN
    
- Enable biometric
    
- Disable biometric
    
- Change auto-lock timeout
    
- Change Master Password
    

---

# 37. Master Password Change

Master Password change flow:

```text
Authenticated Session
       ↓
Enter Current Master Password
       ↓
Verify Current Password
       ↓
Enter New Master Password
       ↓
Confirm New Password
       ↓
Generate New KDF Material
       ↓
Re-derive Key
       ↓
Re-wrap Vault Key
       ↓
Persist New UserRecord
       ↓
Keep Vault Data Unchanged
```

The encrypted vault MUST NOT be re-encrypted unnecessarily.

---

# 38. Account Switching

When switching between accounts:

```text
Current Session
   ↓
Lock / Clear Session
   ↓
Select Another User
   ↓
Authenticate
   ↓
Unlock Selected Vault
   ↓
Create New Session
```

A User's Vault Key MUST NOT be reused for another account.

---

# 39. Multiple Account Isolation

If User A is active:

```text
User A Session
    ↓
Vault A only
```

User B's vault MUST NOT be accessible through User A's session.

When switching to User B:

```text
Clear User A Session
    ↓
Authenticate User B
    ↓
Create User B Session
```

---

# 40. Account Deletion

Account deletion requires authentication.

Flow:

```text
Authenticated
   ↓
Delete Account
   ↓
Show Warning
   ↓
Require Confirmation
   ↓
Delete UserRecord
   ↓
Delete VaultRecord
   ↓
Delete Local Unlock Credentials
   ↓
Clear Session
   ↓
Return to Initial State
```

---

# 41. Lock vs Delete

These operations MUST NEVER be confused.

### Lock

```text
Session → Cleared
Data → Preserved
Account → Preserved
```

### Logout

```text
Session → Cleared
Data → Preserved
Account → Preserved
```

### Delete

```text
Session → Cleared
Data → Deleted
Account → Deleted
```

---

# 42. Error Handling

Authentication failures MUST NOT expose internal cryptographic details.

Use generic messages such as:

```text
Unable to unlock your vault.
```

Avoid:

```text
Argon2id failed.
AES-GCM authentication tag mismatch.
Vault Key unwrap failed.
```

Those details MAY exist only in internal non-sensitive diagnostics where appropriate.

---

# 43. Authentication Rate Limiting

Master Password and PIN authentication MUST have protection against rapid repeated attempts.

The exact implementation SHOULD be designed separately for:

- PIN
    
- Master Password
    

The application MUST NOT create a mechanism that permanently locks the user out without a recovery path through the valid Master Password.

---

# 44. No Authentication Bypass

Cursor MUST NOT implement:

- Debug bypasses in release builds.
    
- Hard-coded passwords.
    
- Test accounts in production.
    
- Automatic unlock using stored Master Password.
    
- Automatic vault decryption at startup.
    

Any test-only bypass MUST be isolated to test environments and MUST NOT be included in release builds.

---

# 45. Session Architecture

Recommended conceptual architecture:

```text
App
 │
 ▼
SessionController
 │
 ├── Authentication
 │
 ├── Lock / Unlock
 │
 ├── Auto Lock
 │
 ├── Account Switching
 │
 └── Session State
        │
        ▼
   Active Vault
```

The SessionController MUST be the single source of truth for whether a vault is currently unlocked.

---

# 46. Navigation Rule

Navigation MUST react to authentication/session state.

Example:

```text
Locked
   ↓
Authentication Screen

Unlocked
   ↓
Main Application
```

UI pages MUST NOT independently decide whether the user is authenticated.

---

# 47. GetX Integration

Keyva currently uses GetX.

Authentication/session state SHOULD be managed through dedicated controllers/services.

Recommended conceptual structure:

```text
AuthController
SessionController
SecurityController
```

Responsibilities MUST remain separated.

Do not place all authentication, database, encryption, and UI logic into a single controller.

---

# 48. Controller Rules

Controllers:

- MUST NOT directly implement cryptographic primitives.
    
- MUST NOT directly manipulate Hive boxes.
    
- MUST NOT contain large serialization logic.
    
- MUST delegate persistence to repositories.
    
- MUST delegate cryptography to security services.
    

Example:

```text
AuthController
      ↓
AuthRepository
      ↓
CryptoService
      ↓
LocalDataSource
```

---

# 49. Session Initialization

At application startup:

```text
Initialize
   ↓
Load Local Accounts
   ↓
Initialize SessionController
   ↓
Determine Locked/Unlocked state
```

The default secure state MUST be:

```text
Locked
```

unless a deliberate local unlock mechanism has already authenticated the user.

---

# 50. Secure Default

Whenever Keyva cannot confidently determine that a valid authenticated session exists:

```text
LOCK
```

Security failures MUST fail closed rather than fail open.

---

# 51. Final Authentication State Machine

Conceptual state machine:

```text
             ┌──────────────┐
             │ Initializing │
             └──────┬───────┘
                    │
          ┌─────────┴─────────┐
          │                   │
          ▼                   ▼
     No Account            Locked
          │                   │
          ▼                   │
      Register                │
          │                   │
          └─────────┐         │
                    ▼         │
                 Authenticating
                    │
          ┌─────────┼─────────┐
          │         │         │
          ▼         ▼         ▼
       Biometric   PIN   Master Password
          │         │         │
          └─────────┼─────────┘
                    │
                    ▼
                 Unlocking
                    │
                    ▼
                 Unlocked
                    │
        ┌───────────┼───────────┐
        │           │           │
        ▼           ▼           ▼
      Lock       Logout      Auto Lock
        │           │           │
        └───────────┴───────────┘
                    │
                    ▼
                  Locked
```

---

# 52. Implementation Rules

Cursor MUST:

- Keep authentication separate from cryptography.
    
- Keep session management separate from persistence.
    
- Keep UI separate from authentication logic.
    
- Use repositories for database access.
    
- Use dedicated security services for cryptography.
    
- Keep the application locked by default.
    
- Never persist Master Password.
    
- Never persist plaintext Vault Key.
    
- Never automatically decrypt all vaults.
    
- Never bypass authentication.
    
- Never expose cryptographic errors to users.
    
- Fail closed when security state is uncertain.
    
