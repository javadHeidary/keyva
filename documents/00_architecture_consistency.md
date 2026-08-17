# Keyva Architecture Consistency Notes

This document identifies minor contradictions and ambiguities across the architecture documents and records the **final decision** for each case.

Goal: Prevent Cursor from becoming confused during implementation.

---

## 1. Authentication Tag in VaultRecord

### Issue
- In `02_database_architecture.md` and `05_data_models.md`, `VaultRecord` only contains:
  ```text
  nonce + ciphertext + formatVersion
  ```
  There is no separate `authenticationTag` field.

- In `03_cryptography.md` and the security documents, the Authentication Tag is mentioned as a separate value.

### Final Decision
**The Authentication Tag must be part of the encrypted structure.**

Two acceptable approaches exist:

**Option A (Recommended – simpler):**
```text
ciphertext = AES-GCM output (includes Authentication Tag)
```
Most cryptography libraries append the tag to the ciphertext or return a combined output. In this case, a separate field is not required.

**Option B:**
```text
VaultRecord
├── nonce
├── ciphertext
└── authenticationTag   ← separate field
```

### Rule for Cursor
- If the chosen package returns the tag separately → use Option B.
- If the package combines the tag into the ciphertext → use Option A.
- In both cases, authentication **must** be verified during decryption.
- The `VaultRecord` model must stay consistent across the entire project.

**Recommended starting choice:** Option A, unless the selected package returns the tag separately.

---

## 2. Salt on Master Password Change

### Issue
- `07_account_lifecycle.md` says:
  ```text
  Generate New Salt
  ```
- `03_cryptography.md` says:
  ```text
  KDF Salt / parameters (only if intentionally rotated)
  ```

### Final Decision
**Do not change the Salt when changing the Master Password**, unless an intentional rotation is explicitly required.

Reasons:
- Changing the Salt provides no meaningful extra security for a new password.
- It increases implementation complexity and risk of errors.
- Common practice in password managers is to keep the Salt stable unless performing a parameter upgrade or migration.

### Rule for Cursor
```text
Master Password Change:
  - Keep the existing Salt
  - Keep the existing KDF Parameters (unless an intentional upgrade is performed)
  - Only derive a new key and re-wrap the Vault Key
```

If Salt rotation is needed in the future, it must be designed as an explicit, separate operation.

---

## 3. Exact Argon2id Parameters

### Issue
No document specifies the final numeric values for Memory Cost, Time Cost, and Parallelism.

### Final Decision (Temporary for MVP)
Recommended starting values (to be tuned after real-device benchmarking):

```text
algorithm     = Argon2id
memoryCost    = 65536   (64 MB)
timeCost      = 3
parallelism   = 4
outputLength  = 32 bytes
saltLength    = 16 bytes
```

These values must be defined in a single central location (e.g. `SecurityConstants` or `KdfConfig`) and must **not** be hard-coded in multiple places.

**Note:** Before release, these parameters must be tested on weaker devices. If the user experience becomes too slow, they may be reduced slightly (but not drastically).

---

## 4. PIN Rate Limit and Lockout

### Issue
The documents require rate limiting and lockout after failed attempts, but no exact numbers are defined.

### Final Decision for MVP

```text
Attempts 1–3  → no delay
Attempt 4     → 2 second delay
Attempt 5     → 5 second delay
Attempt 6     → 15 second delay
Attempt 7+    → require Master Password
```

Or the simpler rule:

```text
5 consecutive failed attempts → temporarily lock PIN and require Master Password
```

These values must be centralized in `SecurityConstants`.

---

## 5. User ID Conflict on Restore

### Issue
`06_backup_and_restore.md` states that silent overwrite is forbidden, but the final UX decision is not specified.

### Final Decision for MVP

```text
If the User ID already exists:
  → Reject the restore
  → Show a clear message to the user:
     "This account already exists on this device."
```

Reasons:
- Keeps the UX simple.
- Avoids risk of data loss.
- A “replace with confirmation” option can be added later if needed.

---

## 6. WrappedVaultKey Structure

### Status
Correctly defined in `05_data_models.md`:

```text
WrappedVaultKey
├── version
├── nonce
├── ciphertext
└── authenticationTag
```

This structure must be preserved and kept separate from Vault Encryption (two independent encryption operations with separate nonces).

---

## 7. Repeated Security Concepts

Many rules (e.g. “Master Password must never be stored”) are repeated across multiple documents.

### Decision
This repetition is **intentional and useful**, because each document has a different audience.

However, for Cursor:
- Primary implementation document = `09_implementation_rules.md` (cleaned version)
- Other documents = specialized references

Cursor should not become confused by the repetition. Priority belongs to document 09.

---

## 8. Summary of Final Decisions

| Topic                             | Final Decision                                                               |
| --------------------------------- | ---------------------------------------------------------------------------- |
| Authentication Tag in VaultRecord | Prefer inside ciphertext (Option A) unless the package returns it separately |
| Salt on Master Password change    | **Do not change**                                                            |
| Argon2id parameters               | 64 MB / time=3 / parallelism=4 / output=32 / salt=16                         |
| PIN Rate Limit                    | 5 failed attempts → require Master Password                                  |
| User ID conflict on Restore       | Reject restore (no overwrite)                                                |
| Primary document for Cursor       | `09_implementation_rules.md`                                                 |

---

## 9. Rule for Cursor

If a contradiction between two documents is found during implementation:

1. First check this document (`00_architecture_consistency.md`).
2. If a decision is recorded here, follow it.
3. If no decision exists here → **stop and ask**. 
4. ask question for decision

Never invent a new architectural decision on your own.
