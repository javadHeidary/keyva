# Vault Encryption & AES-GCM

## 1. Overview

Vault contents, wrapped Vault Keys, backup payloads, and image blobs are encrypted with AES-256-GCM through `CryptoService.encrypt` / `decrypt`. The implementation uses `package:cryptography` `AesGcm.with256bits()`. The GCM authentication tag is a separate field on `EncryptedPayload` and `WrappedVaultKey`, and is concatenated onto `VaultRecord.ciphertext` for Hive storage.

## 2. Purpose

AES-GCM provides confidentiality and integrity for vault bytes without implementing cryptography in application code. Decryption that fails the MAC returns `VaultDecryptionFailure` (fail closed).

## 3. Architecture

| Layer | Role |
| --- | --- |
| ViewModel | Works with decrypted models (`VaultData`, item types) |
| Service | `VaultDataService` serializes models to bytes |
| Repository | `VaultRepositoryImpl` encrypts/decrypts with session Vault Key |
| Core / Security | `CryptoServiceImpl` AES-GCM |
| Local Storage | Hive `VaultRecord` or blob files |
| Domain | Not present |

Encryption does not happen in the View or ViewModel.

## 4. Implementation Flow

Encrypt:

```text
plaintext Uint8List
    ↓
require key.length == 32
    ↓
AesGcm.newNonce()  (must be 12 bytes)
    ↓
AesGcm.encrypt(plaintext, secretKey, nonce)
    ↓
EncryptedPayload { version: 1, nonce, ciphertext, authenticationTag }
```

Decrypt:

```text
EncryptedPayload
    ↓
validate version, key length 32, nonce 12, tag 16
    ↓
AesGcm.decrypt(SecretBox(ciphertext, nonce, Mac(tag)), key)
    ↓
plaintext  or  SecretBoxAuthenticationError → VaultDecryptionFailure
```

Vault persist path:

```text
VaultData
    ↓
VaultSerializer.serialize → UTF-8 JSON bytes
    ↓
VaultRepositoryImpl.saveVaultData
    ↓
CryptoService.encrypt(key: session.vaultKey)
    ↓
ciphertext || authenticationTag stored as VaultRecord.ciphertext
    ↓
HiveVaultDataSource.create or update
```

## 5. Important Classes & Files

| Class / File | Responsibility | Relationship |
| --- | --- | --- |
| `CryptoService` — `lib/core/crypto/crypto_service.dart` | `encrypt` / `decrypt` / `generateSecureBytes` / `deriveKey` | Core crypto interface |
| `CryptoServiceImpl` — `lib/core/crypto/crypto_service_impl.dart` | AES-256-GCM implementation | Injects optional `AesGcm` for tests |
| `EncryptedPayload` — `lib/core/crypto/encrypted_payload.dart` | `version`, `nonce`, `ciphertext`, `authenticationTag` | In-memory / backup envelope shape |
| `VaultRecord` — `lib/core/database/models/vault_record.dart` | Hive row: nonce + combined ciphertext | Tag not a separate Hive field |
| `VaultRepositoryImpl` — `lib/feature/vault/repository/vault_repository_impl.dart` | Combines/splits tag; requires authenticated session | Uses `SessionService.vaultKey` |
| `WrappedVaultKey` | Same four-field GCM layout as payload | Produced by key wrapping |
| `EncryptedBlobStoreImpl` | Encrypts image bytes with Vault Key to files | Encodes payload with a 1-byte version prefix |
| `SecurityConstants` | `vaultKeyLength` 32, `nonceLength` 12, `authenticationTagLength` 16, `vaultEncryptionVersion` 1 | Validation |

`VaultRepositoryImpl._combineCiphertextAndTag` concatenates ciphertext and tag. `_payloadFromRecord` splits the last 16 bytes as the tag.

Backup envelopes keep nonce, ciphertext, and authenticationTag as **separate JSON fields** (not concatenated).

## 6. Data Flow

| Stage | Data |
| --- | --- |
| In memory (unlocked) | `VaultData` object graph; Vault Key on `SessionService` |
| After serialize | UTF-8 JSON plaintext bytes |
| After encrypt | nonce + ciphertext + tag |
| Persisted (Hive) | `VaultRecord` with combined ciphertext |
| Persisted (blobs) | File bytes: version + nonce + ciphertext + tag (`EncryptedBlobStoreImpl._encode`) |
| On load | Split tag → decrypt → deserialize → `VaultSession` |

Raw item fields (passwords, card numbers, note bodies) exist as Dart strings only after decrypt+deserialize, and in ViewModels/forms while a screen is open.

`generateSecureBytes` uses `randomBytes` from `package:cryptography/helpers.dart`.

## 7. Security Considerations

- Key length must be 32 bytes; otherwise encrypt/decrypt returns `CryptoFailure`.
- Nonce is generated per encrypt (`_aesGcm.newNonce()`). A nonce of unexpected length fails closed.
- MAC failure is `VaultDecryptionFailure`, distinct from generic `CryptoFailure`.
- `VaultRepositoryImpl` refuses to operate without `SessionService.isAuthenticated` and a non-null `vaultKey` (`AuthenticationFailure`).
- `formatVersion` on `VaultRecord` must equal `vaultEncryptionVersion` (1) or load returns `CryptoFailure`.
- Combined ciphertext shorter than 16 bytes is rejected.

The Master Password is never used as the AES key for vault records. The AES key is the Vault Key (see [Vault Key Management](04_vault_key_management.md)).

## 8. Error Handling

- Invalid arguments: `CryptoFailure`.
- GCM auth failure: `VaultDecryptionFailure`.
- Other thrown errors: `CryptoErrorMapper` → `CryptoFailure`.
- Missing session: `AuthenticationFailure` from the repository, before crypto.

Backup decrypt maps `VaultDecryptionFailure` to `WrongBackupPasswordFailure`.

## 9. Edge Cases

- Empty vault: `loadVaultData` returns `Success(null)`; `VaultUnlockServiceImpl` then uses `VaultData.initial()` without decrypting.
- First save uses `create`; later saves `update`.
- `EncryptedPayload.version` is written as `vaultEncryptionVersion` (1), independent of `VaultData.currentVersion` (also 1, but that is the JSON schema version inside plaintext).

## 10. Testing

- `test/core/crypto/crypto_service_test.dart`
- `test/core/crypto/crypto_error_mapper_test.dart`
- `test/feature/vault/vault_repository_test.dart`
- `test/feature/vault/vault_serialization_persistence_test.dart`
- `test/feature/vault/encrypted_blob_store_test.dart`

## 11. Technical Decisions

- AES-256-GCM from `package:cryptography` rather than a custom cipher.
- Authentication tag kept separate in `EncryptedPayload` (library `SecretBox.mac`) and concatenated only for Hive `VaultRecord` to match a two-field storage layout (nonce + ciphertext).
- One AES key (Vault Key) for vault JSON and image blobs; backup uses a **different** key derived from the backup password.

## 12. Limitations / Notes

- Associated data (GCM AAD) is not used; encrypt is called with plaintext and key only.
- There is no ciphertext version migration beyond rejecting unknown `formatVersion`.
- Dart `Uint8List` plaintext is not explicitly zeroed after encrypt in `VaultRepositoryImpl`.

## 13. Summary

`CryptoServiceImpl` encrypts and decrypts with AES-256-GCM. `EncryptedPayload` stores nonce, ciphertext, and tag separately. Hive `VaultRecord` appends the 16-byte tag to ciphertext. The session Vault Key is the AES key. MAC failures become `VaultDecryptionFailure`.

Related: [Argon2id](02_argon2id_key_derivation.md), [Vault Key Management](04_vault_key_management.md), [Hive](10_hive_ce_local_storage.md), [Vault Lifecycle](17_vault_process_lifecycle.md).
