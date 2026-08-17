# Keyva Security Architecture

## Purpose

This document defines the security architecture of Keyva.

All authentication, encryption, storage, session, backup, and sensitive-data handling implementations MUST follow the rules defined in this document.

The goal is to keep Keyva:

- Local-only
- Offline-first
- Privacy-first
- Security-first

Keyva does not use a remote server for authentication, vault storage, synchronization, or account recovery.

---

# 1. Core Security Principles

Keyva MUST follow these principles:

1. Sensitive user data MUST remain local to the device unless the user explicitly exports a backup.
2. Master Password MUST never be stored.
3. Plain Vault Key MUST never be persisted to the database.
4. PIN MUST never be stored as plaintext.
5. Biometric data MUST never be stored or processed by Keyva.
6. Sensitive vault data MUST be encrypted at rest.
7. Encryption MUST use authenticated encryption.
8. Sensitive values MUST never be written to logs.
9. Authentication credentials MUST be separated from encryption keys.
10. UI layers MUST NOT directly access encrypted storage or cryptographic primitives.

---

# 2. User Identity

Each Keyva account MUST have a unique User ID.

The User ID MUST be generated independently from the username and Master Password.

Recommended format:

- UUID v4

Example:

User ID:
`550e8400-e29b-41d4-a716-446655440000`

The User ID is the actual identity of the account.

The username is only a display/UX value.

Therefore:

User ID ≠ Username

---

# 3. Username

Username exists only for user experience.

Requirements:

- Username MUST be Persian.
- Username MUST NOT be used as an encryption key.
- Username MUST NOT be used as the primary authentication credential.
- Changing the username MUST NOT require re-encrypting the vault.
- Changing the username MUST NOT change the Vault Key.

---

# 4. Master Password

The Master Password is the primary user authentication credential.

The Master Password:

- MUST never be stored in plaintext.
- MUST never be stored in encrypted form.
- MUST never be written to logs.
- MUST never be included in backups.
- MUST never be included in analytics or crash reports.

Keyva MUST derive a cryptographic key from the Master Password using Argon2id.

Conceptual flow:

Master Password
→ Argon2id + unique user salt
→ Derived Key

The Derived Key is NOT the Vault Key.

---

# 5. Salt

Each account MUST have a unique cryptographically random salt.

The salt:

- MUST be generated during account creation.
- MUST be stored with the user's metadata.
- MAY be included in a backup.
- MUST NOT be treated as a secret.

The same salt MUST be used when deriving the key from the user's Master Password for that account.

---

# 6. Vault Key

Each account MUST have its own randomly generated Vault Key.

Example:

User A → Vault Key A
User B → Vault Key B

The Vault Key:

- MUST be generated using a cryptographically secure random generator.
- MUST NOT be derived directly from the username.
- MUST NOT be derived directly from the User ID.
- MUST NOT be derived directly from the Master Password.
- MUST NOT be stored as plaintext in Hive.

The Vault Key is the encryption key used to encrypt/decrypt the user's vault.

---

# 7. Key Wrapping

The Vault Key MUST be protected using a key derived from the Master Password.

Flow:

Master Password
→ Argon2id
→ Derived Key

Then:

Derived Key
+
Vault Key
→ Key Wrapping
→ Wrapped Vault Key

Only the Wrapped Vault Key MAY be persisted.

The plain Vault Key MUST only be available while the vault is actively unlocked.

---

# 8. Vault Encryption

All sensitive vault data MUST be encrypted using:

AES-256-GCM

The encrypted vault contains sensitive information such as:

- Login credentials
- Passwords
- Usernames
- Website information
- Bank card information
- Secure notes
- Other sensitive vault data

Conceptual flow:

Vault Data
→ AES-256-GCM + Vault Key
→ Encrypted Vault

---

# 9. AES-GCM Nonce

Every encryption operation using AES-GCM MUST use a new cryptographically secure random nonce.

A nonce MUST NOT be reused with the same encryption key.

The encrypted vault record MUST contain enough information to decrypt and verify the data later.

Conceptual structure:

EncryptedVault:
- version
- nonce
- ciphertext
- authentication tag

The authentication tag MUST be verified before decrypted data is trusted.

---

# 10. Authentication Methods

Keyva supports three local authentication methods:

1. Master Password
2. PIN
3. Biometric authentication

All authentication methods ultimately provide access to the Vault Key through a secure local unlock mechanism.

Authentication methods MUST NOT replace the Vault Key architecture.

---

# 11. Master Password Unlock

Flow:

User enters Master Password
→ Load user's salt and KDF parameters
→ Argon2id
→ Derived Key
→ Unwrap Vault Key
→ Verify Vault
→ Unlock session

If unwrapping or vault authentication fails, the authentication attempt MUST fail.

The original Master Password MUST never be recovered from stored data.

---

# 12. PIN

PIN is a local unlock mechanism.

Requirements:

- Minimum length: 6 digits.
- Plain PIN MUST NOT be stored.
- PIN MUST have failed-attempt protection.
- Repeated failed attempts MUST introduce rate limiting.
- After excessive failed attempts, Master Password authentication MUST be required.

PIN MUST NOT be treated as the primary vault encryption key.

The exact platform-protected PIN/key mechanism MUST be implemented using secure platform storage rather than custom cryptography.

---

# 13. Biometric Authentication

Keyva MUST delegate biometric authentication to the operating system.

Keyva MUST NOT:

- Store fingerprints.
- Store face data.
- Process biometric templates.
- Implement its own biometric recognition.

The application only receives the authentication result from the platform.

Biometric authentication is device-specific and MUST NOT be included in backups.

---

# 14. Session Security

When the vault is unlocked:

- The active Vault Key MAY exist in application memory for the current session.
- The Vault Key MUST NOT be persisted as plaintext.
- The Master Password MUST NOT be retained unnecessarily.

When the vault is locked or the user logs out:

- Active authentication/session state MUST be cleared.
- Active Vault Key references MUST be released.
- Sensitive navigation state MUST be cleared.

The implementation MUST NOT claim guaranteed memory zeroization in Dart.

---

# 15. Logout

Logout MUST:

1. Lock the vault.
2. Clear the active session.
3. Release active Vault Key references.
4. Remove sensitive navigation state.
5. Navigate to the authentication screen.

Logout MUST NOT delete the user's account or vault.

---

# 16. Auto Lock

Keyva MUST support automatic vault locking.

Initial timeout options:

- Immediately
- 30 seconds
- 1 minute
- 5 minutes

When the timeout expires:

Active session
→ Lock Vault
→ Require authentication again

---

# 17. Background Protection

When Keyva enters the background:

- Sensitive UI MUST NOT remain visible in the app preview.
- Sensitive content SHOULD be hidden or blurred.
- Auto-lock behavior MUST follow the configured timeout.

---

# 18. Screenshot Protection

Sensitive screens SHOULD prevent screenshots and screen recording where supported by the platform.

Sensitive screens include:

- Login details
- Bank card details
- Secure notes
- Other screens displaying secrets

---

# 19. Clipboard Security

When a sensitive value is copied:

Sensitive Value
→ System Clipboard
→ Automatic clearing after 30 seconds

The application MUST NOT intentionally keep sensitive values in the clipboard indefinitely.

---

# 20. Sensitive Data Display

Sensitive values MUST be masked by default.

Examples:

Password:
`••••••••`

Bank card:
`6037 **** **** 1234`

The user MAY explicitly reveal the value through a deliberate UI action.

---

# 21. Logging

Sensitive information MUST NEVER appear in logs.

Forbidden:

- Master Password
- Vault Key
- Derived Key
- PIN
- Passwords
- Card numbers
- Secure note contents
- Decrypted vault contents

Safe example:

`Vault decryption failed`

Unsafe example:

`Vault decryption failed with key: XXXXX`

---

# 22. Error Handling

Security-related errors MUST NOT expose cryptographic secrets.

User-facing errors SHOULD be generic.

Example:

`Unable to unlock vault.`

The application MUST NOT expose:

- Encryption keys
- Passwords
- Ciphertext
- Internal secret values
- Sensitive stack information to users

---

# 23. Backup Security

Backups MUST NOT contain:

- Master Password
- Plain Vault Key
- Plain PIN
- Biometric data
- Plain sensitive vault data

The backup MAY contain:

- User metadata
- User ID
- Username
- Salt
- KDF parameters
- Wrapped Vault Key
- Encrypted Vault
- Backup format version

Backup format:

`.keyva`

The encrypted vault MUST NOT be unnecessarily encrypted a second time solely because it is inside a backup.

---

# 24. Restore Security

A backup MUST be validated before it replaces existing data.

Flow:

Import Backup
→ Validate format
→ Read KDF metadata
→ Request Master Password
→ Derive Key
→ Unwrap Vault Key
→ Verify AES-GCM authentication
→ Validate vault
→ Restore

Invalid or corrupted backups MUST be rejected.

---

# 25. Account Deletion

Account deletion MUST require explicit confirmation and authentication.

Deletion MUST remove:

- User metadata
- Encrypted vault
- Wrapped Vault Key
- Local unlock credentials
- Active session state

External backup files are outside the application's control and are NOT automatically deleted.

---

# 26. Master Password Change

Changing the Master Password MUST NOT require re-encrypting the entire vault.

Flow:

Old Master Password
→ Derive old key
→ Unwrap Vault Key
→ New Master Password
→ Derive new key
→ Wrap Vault Key again

Only the Wrapped Vault Key changes.

The encrypted vault remains unchanged.

---

# 27. Database Security Boundary

UI and ViewModels MUST NOT directly access Hive.

The dependency direction MUST be:

UI
→ ViewModel
→ Repository
→ Data Source
→ Hive

Cryptographic operations MUST be isolated from UI code.

---

# 28. Security Scope

The following features are intentionally OUT OF SCOPE for the initial Keyva implementation:

- Cloud synchronization
- Server authentication
- Online account recovery
- Remote wipe
- Server-side vault storage
- Per-item encryption
- Advanced anti-tampering
- Mandatory root/jailbreak enforcement

These features MUST NOT be introduced unless the architecture is explicitly revised.

---

# 29. Implementation Rule

Cursor MUST NOT invent or replace cryptographic architecture.

Cursor MUST follow the algorithms, key hierarchy, authentication flow, and storage boundaries defined in the Keyva architecture documents.

If an implementation decision conflicts with this document, the conflict MUST be reported before implementation.