# Task 02 — Cryptography and Key Management

This note describes the **cryptography layer that is actually in the codebase**.

It is a learning reference and an implementation record. The source of truth is the Dart code and tests, not the architecture proposals.

Related code:

- [`lib/core/crypto/`](../../lib/core/crypto/)
- [`lib/core/constants/security_constants.dart`](../../lib/core/constants/security_constants.dart)
- [`lib/core/exceptions/app_failure.dart`](../../lib/core/exceptions/app_failure.dart)
- [`lib/core/di/injection_container.dart`](../../lib/core/di/injection_container.dart)
- [`lib/core/database/models/kdf_parameters.dart`](../../lib/core/database/models/kdf_parameters.dart)
- [`lib/core/database/models/wrapped_vault_key.dart`](../../lib/core/database/models/wrapped_vault_key.dart)
- [`lib/core/database/models/vault_record.dart`](../../lib/core/database/models/vault_record.dart)
- [`test/core/crypto/`](../../test/core/crypto/)

---

## Purpose

Task 02 built the reusable cryptographic foundation that later authentication and vault features will call.

In simple terms, this layer answers:

1. How do we turn a Master Password into a strong key without storing the password?
2. How do we create a random Vault Key that actually encrypts the vault?
3. How do we store that Vault Key safely (wrapped) so it is not sitting on disk in plaintext?
4. How do we encrypt and decrypt vault bytes so tampering is detected?

It is **infrastructure only**. It does not create accounts, unlock sessions, write Hive records, or change any UI.

---

## Why these pieces exist (simple mental model)

Think of three different secrets with three different jobs:

```text
Master Password     →  something the user remembers
        ↓  Argon2id + unique salt
Derived Key         →  only used to lock/unlock the Vault Key
        ↓  AES-256-GCM wrap
Vault Key           →  the real key that encrypts vault contents
        ↓  AES-256-GCM encrypt
Encrypted vault     →  unreadable bytes until the Vault Key is unwrapped
```

They are not interchangeable:

- The Master Password is **never** used as an AES key.
- The Derived Key does **not** encrypt the whole vault.
- The Vault Key is **not** derived from the password. It is random.

If an attacker copies the database, they get salt, KDF settings, a wrapped key, and ciphertext. They still need the Master Password to unwrap the Vault Key.

---

## Library and isolation

The implementation uses [`package:cryptography`](https://pub.dev/packages/cryptography) `2.9.0`.

| Algorithm | Package API |
|-----------|-------------|
| Argon2id | `Argon2id(...)` then `deriveKeyFromPassword` |
| AES-256-GCM | `AesGcm.with256bits()` |
| Secure random bytes | `randomBytes` from `package:cryptography/helpers.dart` |
| AES-GCM nonce | `_aesGcm.newNonce()` |

The project does **not** implement AES, GCM, or Argon2 by hand. `cryptography_flutter` (native acceleration) is **not** a dependency.

Higher layers depend on interfaces and `Uint8List` / existing models. Only [`CryptoServiceImpl`](../../lib/core/crypto/crypto_service_impl.dart) imports `package:cryptography`. [`KeyManagementServiceImpl`](../../lib/core/crypto/key_management_service_impl.dart) talks to `CryptoService`, not to the library.

---

## Two services and their responsibilities

```text
Future AuthRepository / VaultRepository     ← not implemented yet
        ↓
KeyManagementService          CryptoService
        ↓                            ↓
   salt, vault key,           random bytes,
   wrap / unwrap              Argon2id, AES-GCM
        └────────────┬───────────────┘
                     ↓
           package:cryptography
```

### `CryptoService`

Interface: [`crypto_service.dart`](../../lib/core/crypto/crypto_service.dart)  
Implementation: [`crypto_service_impl.dart`](../../lib/core/crypto/crypto_service_impl.dart)

Low-level primitives:

| Method | What it does |
|--------|----------------|
| `generateSecureBytes(length)` | Cryptographically secure random bytes |
| `deriveKey(...)` | Master Password + salt + `KdfParameters` → Derived Key |
| `encrypt(...)` | AES-256-GCM encrypt → `EncryptedPayload` |
| `decrypt(...)` | AES-256-GCM decrypt → plaintext bytes |

### `KeyManagementService`

Interface: [`key_management_service.dart`](../../lib/core/crypto/key_management_service.dart)  
Implementation: [`key_management_service_impl.dart`](../../lib/core/crypto/key_management_service_impl.dart)

Key lifecycle on top of `CryptoService` (constructor-injected):

| Method | What it does |
|--------|----------------|
| `defaultKdfParameters()` | Builds the production `KdfParameters` from `SecurityConstants` |
| `generateSalt()` | 16 random bytes |
| `generateVaultKey()` | 32 random bytes, independent of any password |
| `wrapVaultKey(...)` | Encrypt the Vault Key with the Derived Key → `WrappedVaultKey` |
| `unwrapVaultKey(...)` | Decrypt `WrappedVaultKey` → 32-byte Vault Key |

`KeyManagementService` does **not** derive keys from a password. Callers that need a Derived Key use `CryptoService.deriveKey`.

---

## Central constants

All sizes, algorithm name, and version numbers live in one place: [`SecurityConstants`](../../lib/core/constants/security_constants.dart).

They are not copied through the services.

| Constant | Value | Meaning |
|----------|-------|---------|
| `kdfAlgorithm` | `'Argon2id'` | Only accepted KDF name |
| `kdfMemoryCost` | `65536` | 65536 × 1 KiB blocks = 64 MB |
| `kdfTimeCost` | `3` | Argon2 iterations |
| `kdfParallelism` | `4` | Argon2 lanes |
| `kdfOutputLength` | `32` | Derived Key size in bytes |
| `saltLength` | `16` | Salt size for `generateSalt()` |
| `vaultKeyLength` | `32` | AES-256 key size (Vault Key and Derived Key) |
| `nonceLength` | `12` | AES-GCM nonce size |
| `authenticationTagLength` | `16` | GCM MAC size (128 bits) |
| `wrappedKeyVersion` | `1` | Version stored on `WrappedVaultKey` |
| `vaultEncryptionVersion` | `1` | Version stored on `EncryptedPayload` |

PIN rate-limit numbers are **not** in this file. PIN is not part of this layer.

---

## Master Password → Argon2id → Derived Key

`CryptoService.deriveKey` is the only method that accepts a Master Password.

```text
Master Password (String argument)
        +
Salt (Uint8List)
        +
KdfParameters
        ↓
Argon2id
        ↓
Derived Key (Uint8List)
```

### What Argon2id is doing

A password like `"mypassword"` is too weak and too guessable to use as an encryption key. Argon2id is a **password-based key derivation function**. It is intentionally slow and memory-heavy so guessing passwords offline is expensive.

The same password + same salt + same parameters always produce the **same** Derived Key. A different salt produces a different key. Tests cover both facts.

### What the method actually checks

Before calling the library it fails closed with `CryptoFailure` if:

- `algorithm` is not `'Argon2id'`
- `memoryCost`, `timeCost`, `parallelism`, or `outputLength` is `<= 0`
- `salt` is empty

There is **no** SHA-256 (or any other hash) fallback.

It then constructs:

```dart
Argon2id(
  memory: parameters.memoryCost,
  iterations: parameters.timeCost,
  parallelism: parameters.parallelism,
  hashLength: parameters.outputLength,
)
```

and calls `deriveKeyFromPassword(password: masterPassword, nonce: salt)`.

The password is a method argument only. The service does not store it, return it, or log it. After the call returns, the password is gone unless the **caller** still holds it.

### Salt and stored KDF parameters

`KeyManagementService.generateSalt()` returns 16 random bytes via `generateSecureBytes`.

`defaultKdfParameters()` returns a `KdfParameters` object with the production Argon2id values above.

This layer does **not** write salt or parameters to Hive. `UserRecord` already has fields for them (`kdfSalt`, `kdfParameters`). A later account-creation flow is expected to persist those values. The salt is not secret; it only needs to be unique per account so two users with the same password do not share a Derived Key.

`deriveKey` uses whatever `KdfParameters` the caller passes. It does not force `outputLength == 32` as long as the value is positive. AES-256 wrap/encrypt still require a 32-byte key, so production parameters keep output length at 32.

---

## Vault Key generation

`KeyManagementService.generateVaultKey()` returns 32 cryptographically secure random bytes.

It does **not** use:

- the Master Password
- the username
- timestamps
- Dart’s insecure `Random()`

Why a random Vault Key instead of deriving it from the password? If the user later **changes the Master Password**, Keyva can unwrap the existing Vault Key and wrap it again with a new Derived Key. The vault ciphertext does not need to be re-encrypted. That flow is not implemented yet, but the key hierarchy already supports it.

---

## Key wrapping and unwrapping

Wrapping means: encrypt the Vault Key itself, using the Derived Key as the AES-256-GCM key.

```text
Derived Key  +  Vault Key  +  fresh nonce
                ↓
         AES-256-GCM
                ↓
         WrappedVaultKey
         ├── version
         ├── nonce
         ├── ciphertext
         └── authenticationTag
```

This is a **second** AES-GCM operation, separate from vault encryption. It uses its own nonce.

### Wrap (`wrapVaultKey`)

1. Reject Vault Key or Derived Key whose length is not 32 → `CryptoFailure`
2. Call `CryptoService.encrypt(plaintext: vaultKey, key: derivedKey)`
3. Copy nonce / ciphertext / tag into `WrappedVaultKey` with `version = 1`

If encrypt returns a failure, wrap maps it to `CryptoFailure`.

### Unwrap (`unwrapVaultKey`)

1. Reject unknown `version`, wrong Derived Key length, nonce ≠ 12 bytes, or tag ≠ 16 bytes → `CryptoFailure`
2. Build an `EncryptedPayload` from the wrapped fields (`version` set to `vaultEncryptionVersion`, currently also `1`)
3. Call `CryptoService.decrypt`
4. Any decrypt failure (including GCM authentication failure) becomes `CryptoFailure`
5. Reject a plaintext that is not 32 bytes → `CryptoFailure`

A wrong Master Password produces a wrong Derived Key. Unwrap then fails authentication. The crypto layer does **not** compare passwords. It tries to unwrap and reports a generic crypto failure.

`KeyManagementServiceImpl._asCryptoFailure` exists so wrap/unwrap never surface `VaultDecryptionFailure`. That type is reserved for **vault** decrypt, not for wrapped-key failures. Later login UI can treat both as “unable to unlock” without this layer leaking which step failed.

---

## AES-256-GCM vault encryption and decryption

`CryptoService.encrypt` / `decrypt` operate on raw bytes. They do not know about logins, cards, or Hive.

### Encrypt

1. Key must be 32 bytes, otherwise `CryptoFailure`
2. Generate a **new** 12-byte nonce with `_aesGcm.newNonce()` (not reused)
3. Encrypt with `AesGcm.with256bits()` — **no AAD** is passed
4. Tag must be 16 bytes, otherwise `CryptoFailure`
5. Return `EncryptedPayload` with `version = 1`

AES-GCM gives confidentiality (ciphertext is unreadable) and authentication (the tag proves the bytes were not modified).

### Decrypt

1. Payload version must be `1`
2. Key must be 32 bytes
3. Nonce must be 12 bytes
4. Tag must be 16 bytes  
   Any of those failing → `CryptoFailure` (not a library exception)
5. Rebuild `SecretBox(ciphertext, nonce, Mac(tag))` and decrypt
6. Library `SecretBoxAuthenticationError` → `VaultDecryptionFailure`
7. Other exceptions → `CryptoErrorMapper` → `CryptoFailure`

Unknown cryptographic versions are **not** interpreted with a fallback algorithm.

### Nonce and authentication tag

| Piece | Size | Secret? | Role |
|-------|------|---------|------|
| Nonce | 12 bytes | No | Makes each encryption unique for the same key. Reusing a nonce with the same key is forbidden. This implementation always generates a fresh one. |
| Authentication tag | 16 bytes | No | Detects modification of ciphertext, nonce, or key mismatch. |
| Ciphertext | variable | No | The encrypted bytes **without** the tag in this crypto API. |

The nonce and tag must be stored **with** the ciphertext so decryption can run. They are not encryption keys.

---

## `EncryptedPayload` vs `VaultRecord` vs `WrappedVaultKey`

Three similar-looking structures exist on purpose.

### `EncryptedPayload`

Crypto-layer result of `encrypt`. **Not** a Hive model.

- `version`
- `nonce`
- `ciphertext`
- `authenticationTag` (separate field)

Nothing in this task writes `EncryptedPayload` to disk.

### `WrappedVaultKey`

Hive persistence model (Task 01) for the wrapped Vault Key. Same four-field shape as `EncryptedPayload`, but it is the type stored on `UserRecord.wrappedVaultKey`. Wrap/unwrap use this type.

### `VaultRecord`

Hive persistence model for the encrypted vault blob:

- `userId`
- `formatVersion`
- `nonce`
- `ciphertext`
- `updatedAt`

There is **no** `authenticationTag` field on `VaultRecord`. Task 01 documented that as Option A (tag inside `ciphertext`). This crypto layer does **not** concatenate the tag into `ciphertext` and does **not** write `VaultRecord`. Mapping `EncryptedPayload` → `VaultRecord` is left to a later vault-persistence task.

---

## Failures: `CryptoFailure` and `VaultDecryptionFailure`

Added on the existing sealed `AppFailure` hierarchy in [`app_failure.dart`](../../lib/core/exceptions/app_failure.dart).

| Type | Default message | Used when |
|------|-----------------|-----------|
| `CryptoFailure` | `Cryptographic operation failed` | Bad inputs, unknown version, KDF rejection, wrap/unwrap failure, unexpected crypto exceptions |
| `VaultDecryptionFailure` | `Unable to decrypt vault data` | AES-GCM authentication failure on `CryptoService.decrypt` |

Operations that can fail return `Result<T>` (`Success` / `FailureResult`). They do **not** throw `package:cryptography` exceptions to callers.

`generateSecureBytes`, `generateSalt`, `generateVaultKey`, and `defaultKdfParameters` return values directly (not `Result`).

### Error mapping

[`CryptoErrorMapper.map`](../../lib/core/crypto/crypto_error_mapper.dart):

| Incoming value | Result |
|----------------|--------|
| already an `AppFailure` | returned unchanged |
| anything else | `CryptoFailure` with the generic message |

The mapper **does not** copy exception text. Keys, passwords, salts, nonces, tags, and ciphertext must not appear in `AppFailure.message`.

### Fail closed

“Fail closed” here means:

- Do not return plaintext after a failed authentication tag check
- Do not ignore tampering
- Do not fall back to another algorithm or version
- Do not leak which cryptographic step failed in the message string

Wrong wrapping key, flipped ciphertext, and flipped nonce all fail. Vault decrypt reports `VaultDecryptionFailure`. Unwrap reports `CryptoFailure`.

---

## What is persisted vs kept only in memory

This task **does not persist anything**. It only produces values that later code may store.

### Safe to persist later (already modeled on `UserRecord` / `VaultRecord`)

- KDF salt
- `KdfParameters`
- `WrappedVaultKey` (version, nonce, ciphertext, tag)
- Encrypted vault nonce and ciphertext
- Non-secret `SecuritySettings`

### Must never be persisted by this design

| Value | Where it exists today |
|-------|------------------------|
| Master Password | `deriveKey` argument only |
| Derived Key | `Uint8List` returned to the caller; not stored by these services |
| Plaintext Vault Key | Returned by `generateVaultKey` / `unwrapVaultKey`; wrap encrypts it before it would be stored |
| Vault plaintext | Returned by `decrypt`; not a Hive model |

There is no `SessionService` yet, so nothing holds the Vault Key for an unlocked session. Callers own the returned bytes until they drop them.

---

## GetIt dependency injection

Still one composition root: [`injection_container.dart`](../../lib/core/di/injection_container.dart).

```text
initDependencies(HiveDatabase database)
        ↓
registerSingleton<HiveDatabase>
        ↓
registerLazySingleton<CryptoService>          → CryptoServiceImpl
        ↓
registerLazySingleton<KeyManagementService>   → KeyManagementServiceImpl(getIt<CryptoService>())
```

- `HiveDatabase` is the already-initialized instance.
- Crypto services are **lazy singletons** (created on first resolve).
- `GetIt` is used in this file to wire `KeyManagementServiceImpl`. Implementations do not look up other services themselves except through that constructor argument.
- No GetX Binding was changed.

`main()` still initializes Hive first, then `initDependencies`, then `runApp`. Crypto is available after DI, but nothing in startup encrypts or decrypts a vault.

---

## Security decisions and why they exist

1. **Interfaces in front of the library.** Features must not import `package:cryptography`. Swapping or testing the primitive layer stays local.
2. **`package:cryptography` for randomness.** Architecture docs require a CSPRNG and forbid `Random()`. They do not name `Random.secure()`. Salts and Vault Keys use `randomBytes`; GCM nonces use `AesGcm.newNonce()`.
3. **Random Vault Key, not password-derived.** Password changes can re-wrap without re-encrypting the vault. The password never becomes the AES key.
4. **Argon2id with centralized parameters.** Guessing the Master Password should be costly. Values live in `SecurityConstants` so they are not duplicated.
5. **Two AES-GCM operations.** Wrapping the key and encrypting vault bytes are separate, each with its own nonce.
6. **No AAD.** The architecture forbids inventing additional authenticated metadata. Encrypt/decrypt pass none.
7. **Separate authentication tag on crypto results.** `EncryptedPayload` and `WrappedVaultKey` store the 16-byte GCM tag beside ciphertext, matching the library’s `SecretBox.mac`.
8. **Generic failure messages.** UI and logs must not receive `SecretBoxAuthenticationError` or Argon2 details.
9. **Unwrap failures are `CryptoFailure`.** Distinguishes “vault blob failed auth” from “could not obtain the Vault Key,” without describing the library error.
10. **Unknown version fails.** `EncryptedPayload.version` and `WrappedVaultKey.version` must be `1`.

---

## Tests and what they verify

Tests use the **production** Argon2id parameters (64 MB). KDF cases use a 2-minute timeout instead of weaker parameters.

| Test file | What it actually checks |
|-----------|-------------------------|
| [`test/core/crypto/crypto_service_test.dart`](../../test/core/crypto/crypto_service_test.dart) | Same password + salt + params → identical 32-byte Derived Key; different salt → different key; encrypt → decrypt round trip with version `1`, 12-byte nonce, 16-byte tag; flipped ciphertext → `VaultDecryptionFailure`; flipped nonce → `VaultDecryptionFailure`; failure messages do not contain `SecretBox`, `GCM`, or `Argon2` |
| [`test/core/crypto/key_management_service_test.dart`](../../test/core/crypto/key_management_service_test.dart) | `generateVaultKey` is 32 bytes, two calls differ, and the key is not all zeros; wrap → unwrap restores the same Vault Key (`version` 1, nonce 12, tag 16); flipped wrapped ciphertext → `CryptoFailure`; a different wrapping key → `CryptoFailure` with message `Cryptographic operation failed` |
| [`test/core/crypto/crypto_error_mapper_test.dart`](../../test/core/crypto/crypto_error_mapper_test.dart) | Unexpected errors become `CryptoFailure` without copying the original text; an existing `AppFailure` is returned unchanged |
| [`test/core/hive_database_test.dart`](../../test/core/hive_database_test.dart) | `initDependencies` registers `CryptoService` and `KeyManagementService` (in addition to the Task 01 Hive checks) |

Wrap/unwrap tests use a random 32-byte key as the wrapping key. They do **not** run Argon2 for those cases. That is enough: wrapping only needs a 32-byte AES key, and the Derived Key is exactly that.

---

## What is not implemented yet

This cryptography layer does **not** provide:

- Account creation or Master Password registration
- Login / unlock / verification flows
- Session management (holding an unwrapped Vault Key in memory after unlock)
- PIN or biometric unlock
- Vault CRUD, vault repositories, or vault JSON/serialization
- Writing `UserRecord` or `VaultRecord` as part of a user flow
- Mapping `EncryptedPayload` onto `VaultRecord.ciphertext` (Option A concatenate vs a future separate tag field)
- Master Password change (re-wrap) or KDF parameter upgrade
- Backup / restore
- UI changes or GetX Binding changes
- `SessionService`, `SecureStorageService`, `PinService`, `BiometricService`
- Running Argon2id on a background isolate (it currently runs on the calling isolate)
- `cryptography_flutter` native acceleration
- Feature failure types such as `AuthenticationFailure`

Feature screens still use in-memory GetX stores. They do not call `CryptoService` yet.
