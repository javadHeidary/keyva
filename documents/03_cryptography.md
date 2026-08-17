
# `03_cryptography.md`

````md
# Keyva Cryptography Specification

## Purpose

This document defines the cryptographic architecture and key-management rules of Keyva.

It specifies:

- Password-based key derivation
- Argon2id
- Salt generation
- Vault Key generation
- Vault encryption
- AES-256-GCM
- Nonce management
- Key wrapping
- Key lifecycle
- Master Password changes
- Cryptographic validation

Cursor MUST NOT introduce alternative cryptographic designs without explicit approval.

---

# 1. Cryptography Goals

Keyva cryptography MUST provide:

- Confidentiality
- Integrity
- Authentication of encrypted data
- Protection against offline password guessing
- Separation between authentication credentials and encryption keys
- Safe key lifecycle management

---

# 2. Cryptographic Components

Keyva uses the following conceptual components:

```text
Master Password
       ↓
     Argon2id
       ↓
   Derived Key
       ↓
  Key Wrapping
       ↓
   Vault Key
       ↓
   AES-256-GCM
       ↓
Encrypted Vault
````

The components have different responsibilities.

---

# 3. Master Password

The Master Password is a human-provided secret.

It MUST:

* Never be persisted.
* Never be logged.
* Never be included in backups.
* Never be used directly as an AES key.
* Never be used directly as a Vault Key.

The Master Password is only an input to the password-based key derivation process.

---

# 4. Password-Based Key Derivation

Keyva MUST use:

Argon2id

The purpose of Argon2id is to transform the human Master Password into a cryptographically strong derived key.

Conceptual flow:

```text
Master Password
      +
Random Salt
      ↓
    Argon2id
      ↓
 Derived Key
```

The Derived Key MUST NOT be stored as plaintext persistent data.

---

# 5. Argon2id Parameters

Argon2id MUST use explicitly defined parameters.

The implementation MUST define:

* Memory cost
* Time cost
* Parallelism
* Output key length
* Salt length

These parameters MUST be centralized in the cryptography configuration.

They MUST NOT be hard-coded throughout the application.

Example conceptual configuration:

```text
KdfParameters
├── algorithm = Argon2id
├── memoryCost
├── timeCost
├── parallelism
└── outputLength
```

The exact production values MUST be selected based on supported target devices and verified through benchmarking before release.

Do NOT optimize Argon2id only for fast execution.

The implementation SHOULD target a deliberate password-verification/derivation cost appropriate for a mobile password manager.

---

# 6. Salt

Each account MUST have a unique cryptographically secure random salt.

Requirements:

* Generated during account creation.
* Never reused across accounts.
* Never derived from User ID.
* Never derived from Username.
* Never derived from Master Password.
* Stored with account metadata.
* Included in backups.

The salt is public metadata and does not need encryption.

---

# 7. Salt Length

The implementation MUST use a cryptographically appropriate salt length.

Recommended:

```text
16 bytes minimum
```

A longer salt MAY be used if required by the selected Argon2id implementation.

The salt MUST be generated using a cryptographically secure random source.

---

# 8. Derived Key

Argon2id produces the Derived Key.

Conceptual:

```text
DerivedKey =
    Argon2id(
        password = MasterPassword,
        salt = UserSalt,
        parameters = KdfParameters
    )
```

The Derived Key is used to protect the Vault Key.

It MUST NOT directly encrypt the entire Vault.

---

# 9. Vault Key

The Vault Key is the actual encryption key for the user's vault.

It MUST be:

* Randomly generated.
* Cryptographically secure.
* Unique per account.
* Independent of the Master Password.
* Independent of the Username.
* Independent of the User ID.

The Vault Key MUST have sufficient length for AES-256.

Recommended:

```text
32 bytes
```

---

# 10. Vault Key Generation

During account creation:

```text
Secure Random Generator
        ↓
32 random bytes
        ↓
Vault Key
```

The implementation MUST use a cryptographically secure random number generator.

The Vault Key MUST NOT be generated using:

* `Random()`
* Username
* User ID
* Timestamp
* Device ID
* Master Password
* Predictable application data

---

# 11. Vault Encryption

The entire vault is encrypted using:

```text
AES-256-GCM
```

The Vault Key is the AES-256 encryption key.

Conceptual flow:

```text
VaultData
    +
VaultKey
    +
New Random Nonce
    ↓
AES-256-GCM
    ↓
Ciphertext + Authentication Tag
```

---

# 12. Why AES-GCM

AES-GCM provides:

* Confidentiality
* Integrity
* Authentication

Therefore Keyva can detect whether encrypted vault data has been modified or corrupted.

The application MUST verify the authentication tag before accepting decrypted data.

---

# 13. Nonce

Every AES-GCM encryption operation MUST use a new random nonce.

The nonce MUST NOT be reused with the same Vault Key.

Recommended AES-GCM nonce size:

```text
12 bytes
```

The nonce is not secret.

It MUST be stored alongside the ciphertext.

Example:

```text
EncryptedVault
├── version
├── nonce
├── ciphertext
└── authenticationTag
```

---

# 14. Nonce Reuse

Nonce reuse with the same AES-GCM key is a critical security failure.

The implementation MUST ensure:

```text
Same Vault Key
+
Same Nonce
+
Multiple Encryptions
```

never occurs.

The safest implementation is to generate a fresh cryptographically secure random nonce for every encryption operation.

---

# 15. Authentication Tag

AES-GCM produces an authentication tag.

The authentication tag MUST be stored with the encrypted vault.

During decryption:

```text
Ciphertext
+
Nonce
+
Authentication Tag
+
Vault Key
        ↓
AES-256-GCM
        ↓
Authenticated Plaintext
```

If authentication fails:

```text
❌ Do not trust plaintext
❌ Do not restore data
❌ Do not overwrite existing valid data
```

---

# 16. Additional Authenticated Data (AAD)

If Keyva uses AAD, it MUST be deterministic and documented.

Recommended AAD may contain non-secret metadata such as:

```text
vault format version
user ID
```

The same AAD MUST be supplied during decryption.

If the implementation does not require AAD, it MUST remain disabled rather than introducing undocumented metadata authentication.

Cursor MUST NOT invent AAD values.

---

# 17. Key Wrapping

The Vault Key MUST be protected using the Derived Key.

Conceptual:

```text
Master Password
      ↓
Argon2id
      ↓
Derived Key
      ↓
Wrap Vault Key
      ↓
Wrapped Vault Key
```

The Wrapped Vault Key is persisted.

The plaintext Vault Key is not persisted.

---

# 18. Key Wrapping Algorithm

The implementation MUST use an authenticated encryption mechanism for wrapping the Vault Key.

Recommended approach:

```text
AES-256-GCM
```

using the Derived Key as the wrapping key.

The wrapped key record MUST have its own unique nonce.

Conceptual:

```text
Derived Key
    +
Vault Key
    +
Wrapping Nonce
    ↓
AES-256-GCM
    ↓
Wrapped Vault Key
```

The wrapping nonce MUST NOT be reused with the same Derived Key.

---

# 19. Wrapped Vault Key Structure

Conceptual:

```text
WrappedVaultKey
├── version
├── nonce
├── ciphertext
└── authenticationTag
```

The exact serialized representation MUST be defined in the data model.

---

# 20. Two Separate Encryption Operations

Keyva has two conceptually different encryption operations.

### Operation A — Vault Encryption

```text
Vault Key
    ↓
AES-256-GCM
    ↓
Encrypted Vault
```

### Operation B — Vault Key Wrapping

```text
Derived Key
    ↓
AES-256-GCM
    ↓
Wrapped Vault Key
```

These operations MUST use separate nonces.

A nonce used for Vault Key wrapping MUST NOT be reused for Vault encryption.

---

# 21. Account Creation Cryptographic Flow

During account creation:

```text
1. Generate User ID
2. Generate random Salt
3. Generate random Vault Key
4. Derive key from Master Password using Argon2id
5. Wrap Vault Key using Derived Key
6. Create initial VaultData
7. Generate Vault Encryption Nonce
8. Encrypt VaultData using Vault Key
9. Persist UserRecord
10. Persist VaultRecord
```

The Master Password MUST NOT be persisted at any stage.

---

# 22. Login Cryptographic Flow

During Master Password authentication:

```text
1. Load UserRecord
2. Load Salt
3. Load KDF Parameters
4. Read Wrapped Vault Key
5. Ask user for Master Password
6. Run Argon2id
7. Produce Derived Key
8. Unwrap Vault Key
9. Verify wrapped-key authentication
10. Load encrypted Vault
11. Decrypt Vault using Vault Key
12. Verify AES-GCM authentication
13. Validate VaultData
14. Create active session
```

If any cryptographic verification fails:

```text
Authentication/Unlock Failed
```

The application MUST NOT reveal which cryptographic step failed.

---

# 23. Wrong Master Password

A wrong Master Password produces a different Derived Key.

Therefore:

```text
Wrong Password
      ↓
Wrong Derived Key
      ↓
Cannot unwrap Vault Key
      ↓
Unlock fails
```

The application does NOT compare plaintext passwords.

It attempts to cryptographically unwrap the Vault Key.

---

# 24. Master Password Change

Changing the Master Password MUST NOT require re-encrypting the entire vault.

Flow:

```text
Old Master Password
        ↓
Argon2id
        ↓
Old Derived Key
        ↓
Unwrap Vault Key
        ↓
Vault Key
        ↓
New Master Password
        ↓
Argon2id
        ↓
New Derived Key
        ↓
Wrap Vault Key again
        ↓
New Wrapped Vault Key
```

The existing encrypted Vault remains unchanged.

---

# 25. Changing the Master Password Does Not Change

The following MUST remain unchanged:

```text
User ID
Vault Key
Encrypted Vault
Vault Data
Username
```

Only the following changes:

```text
KDF Salt / parameters (only if intentionally rotated)
Wrapped Vault Key
```

If the salt is rotated, the new salt MUST be stored and used for the new Derived Key.

---

# 26. KDF Parameter Upgrade

If a future version increases Argon2id parameters:

```text
Old Parameters
      ↓
Authenticate
      ↓
Unwrap Vault Key
      ↓
New Parameters
      ↓
Derive new key
      ↓
Re-wrap Vault Key
```

The entire vault does not need to be re-encrypted.

---

# 27. Vault Update

When vault data changes:

```text
Existing Vault Key
       ↓
Generate new nonce
       ↓
Encrypt updated VaultData
       ↓
Replace encrypted vault record
```

The Vault Key does not change.

The Master Password-derived key does not need to be recalculated for normal vault edits.

---

# 28. Vault Key Rotation

Vault Key rotation is NOT part of normal CRUD operations.

A Vault Key MAY be rotated in the future for:

* Security recovery
* Explicit security upgrade
* Cryptographic migration

If Vault Key rotation is introduced:

1. Decrypt current vault.
2. Generate new random Vault Key.
3. Encrypt vault with new Vault Key.
4. Wrap new Vault Key.
5. Validate new encrypted data.
6. Atomically replace old encrypted data.

Do not implement Vault Key rotation unless explicitly required.

---

# 29. PIN Cryptography

PIN MUST NOT be used directly as an AES encryption key.

The application MUST NOT perform:

```text
PIN → AES-256 Key
```

using simple hashing or string conversion.

PIN-based unlocking MUST use a secure device-protected mechanism.

The exact implementation must be platform-appropriate and documented before implementation.

---

# 30. Biometric Cryptography

Biometric authentication MUST NOT directly become a cryptographic key.

The OS should protect the device-side unlock secret.

Conceptual:

```text
Biometric
    ↓
OS Authentication
    ↓
Protected Key / Credential
    ↓
Local Unlock
```

Keyva MUST NOT store biometric templates.

---

# 31. Key Lifecycle

### Vault Key lifecycle

```text
Generate
   ↓
Wrap
   ↓
Persist Wrapped Version
   ↓
Unwrap on Unlock
   ↓
Use During Session
   ↓
Release on Lock/Logout
```

### Master Password lifecycle

```text
User Input
   ↓
Argon2id
   ↓
Derived Key
   ↓
Use
   ↓
Release
```

The original Master Password MUST NOT be retained longer than necessary.

---

# 32. Key Storage Rules

Persistent storage MAY contain:

```text
Salt
KDF Parameters
Wrapped Vault Key
Encrypted Vault
Nonce
Authentication Tags
```

Persistent storage MUST NOT contain:

```text
Plain Vault Key
Master Password
Derived Key
Plain PIN
Decrypted Vault
```

---

# 33. Cryptographic Randomness

All security-sensitive random values MUST use a cryptographically secure random generator.

Required for:

* User salt
* Vault Key
* AES-GCM nonce
* Vault Key wrapping nonce
* Other future security tokens

The standard non-cryptographic random generator MUST NOT be used.

---

# 34. Encoding

Binary cryptographic values SHOULD be stored using a consistent binary-safe representation.

The application MUST NOT repeatedly convert cryptographic bytes through human-readable encodings unnecessarily.

If Base64 is used for serialization:

* Use standard Base64.
* Define it consistently.
* Decode before cryptographic operations.

---

# 35. Versioning

Cryptographic structures MUST be versioned.

Examples:

```text
Vault Encryption Version = 1
Wrapped Key Version = 1
KDF Version = 1
```

Version numbers allow future cryptographic migrations.

The application MUST NOT silently interpret an unknown cryptographic version using a fallback algorithm.

---

# 36. Cryptographic Migration

If the application changes cryptographic algorithms or parameters:

```text
Old Format
    ↓
Authenticate with old scheme
    ↓
Decrypt
    ↓
Generate new cryptographic material
    ↓
Encrypt using new scheme
    ↓
Validate
    ↓
Persist new format
```

Migration MUST be atomic.

The old valid data MUST NOT be deleted before the new format is successfully validated.

---

# 37. Failure Rules

If cryptographic verification fails:

* Do not use the plaintext.
* Do not overwrite existing valid data.
* Do not silently ignore the error.
* Do not log secret material.
* Return a safe application-level error.

---

# 38. Security Boundaries

Cryptographic code MUST be isolated in dedicated services.

Recommended conceptual architecture:

```text
Repository
    ↓
KeyManagementService
    ↓
CryptoService
    ↓
Cryptographic Library
```

UI and ViewModels MUST NOT perform encryption directly.

---

# 39. Library Selection

Cursor MUST use a well-maintained, audited, production-appropriate Flutter/Dart cryptography library rather than implementing AES, GCM, or Argon2 manually.

The project MUST NOT implement cryptographic primitives from scratch.

Before adding a cryptography dependency, verify:

* Flutter compatibility
* Android compatibility
* iOS compatibility
* Web support requirements if applicable
* Maintenance status
* Algorithm support
* API stability

The chosen package and exact APIs MUST be documented in the implementation phase.

---

# 40. Forbidden Implementations

Cursor MUST NOT:

* Implement AES manually.
* Implement Argon2 manually.
* Use SHA-256 as a replacement for Argon2id.
* Use MD5.
* Use plain SHA-1.
* Use the Master Password directly as an AES key.
* Use the Username as a key.
* Use the User ID as a key.
* Use predictable random values.
* Reuse AES-GCM nonces.
* Store plaintext Vault Keys.
* Store plaintext Master Passwords.
* Store plaintext PINs.
* Log cryptographic secrets.
* Invent custom cryptographic protocols.

---

# 41. Final Cryptographic Architecture

The complete architecture is:

```text
                  Master Password
                         │
                         ▼
                ┌─────────────────┐
                │    Argon2id     │
                │  + Unique Salt  │
                └────────┬────────┘
                         │
                         ▼
                    Derived Key
                         │
                         ▼
                ┌─────────────────┐
                │  Key Wrapping   │
                │   AES-256-GCM   │
                └────────┬────────┘
                         │
                         ▼
                 Wrapped Vault Key
                         │
                         │
                  ┌──────┴──────┐
                  │             │
                  ▼             ▼
             Vault Key       Database
                  │
                  ▼
           ┌───────────────┐
           │ AES-256-GCM   │
           └───────┬───────┘
                   │
                   ▼
            Encrypted Vault
```

The core separation MUST remain:

```text
Master Password
    ≠
Derived Key
    ≠
Vault Key
    ≠
Encrypted Vault
```

Each has a different purpose and lifecycle.
