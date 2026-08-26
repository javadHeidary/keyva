# Vault Key Management

## 1. Overview

The Vault Key is a 32-byte random value that encrypts vault plaintext and image blobs. It is never persisted in plaintext. At rest it exists only as `WrappedVaultKey` (AES-GCM of the Vault Key under a derived key) on `UserRecord`, and optionally as PIN- or biometric-wrapped copies in flutter_secure_storage. In an unlocked session it lives in `SessionServiceImpl` as `Uint8List? _vaultKey`.

## 2. Purpose

Separating the Vault Key from the Master Password lets the app re-wrap the same key when the password, PIN, or biometric wrap material changes, without re-encrypting every vault item. The Master Password only needs to unwrap the Vault Key.

## 3. Architecture

| Layer | Role |
| --- | --- |
| ViewModel | Never holds the Vault Key |
| Repository | `AuthRepositoryImpl` generates, wraps, unwraps, opens session |
| Service | `VaultUnlockService` / `PinService` / `BiometricService` obtain the key then open the vault |
| Core / Security | `KeyManagementServiceImpl` wrap/unwrap; `SessionServiceImpl` in-memory hold |
| Local Storage | `UserRecord.wrappedVaultKey`; PIN/biometric JSON in secure storage |
| Domain | Not present |

## 4. Implementation Flow

**Create (wrap, do not keep key):**

```text
KeyManagementService.generateVaultKey()     // 32 random bytes
    ↓
Argon2id(masterPassword, salt) → derivedKey
    ↓
wrapVaultKey(vaultKey, derivedKey)          // AES-GCM encrypt vault key
    ↓
derivedKey.fillRange(0); vaultKey.fillRange(0)
    ↓
persist WrappedVaultKey on UserRecord
    ↓
no SessionService yet
```

**Unlock (unwrap into session):**

```text
deriveKey(masterPassword, stored salt, stored params)
    ↓
unwrapVaultKey(wrappedVaultKey, derivedKey)
    ↓
zero derivedKey
    ↓
openSession(userId, vaultKey) → SessionService.setAuthenticated
```

`setAuthenticated` zeros any previous key, then stores the new `Uint8List`.

**PIN wrap** (after an unlocked session): Argon2id(PIN, new salt) → wrap the **current session** Vault Key → JSON in `pin.material.$userId`.

**Biometric wrap:** `generateVaultKey()` as a random wrap key → AES-GCM wrap the session Vault Key → JSON `{ wrapKey, wrapped }` in `bio.material.$userId`. The wrap key is stored in that JSON (OS secure storage), not derived from biometrics.

## 5. Important Classes & Files

| Class / File | Responsibility | Relationship |
| --- | --- | --- |
| `KeyManagementService` — `lib/core/crypto/key_management_service.dart` | `generateSalt`, `generateVaultKey`, `wrapVaultKey`, `unwrapVaultKey`, `defaultKdfParameters` | Implemented by `KeyManagementServiceImpl` |
| `KeyManagementServiceImpl` — `lib/core/crypto/key_management_service_impl.dart` | Delegates encrypt/decrypt of the 32-byte key to `CryptoService` | Validates lengths and wrap version |
| `WrappedVaultKey` — `lib/core/database/models/wrapped_vault_key.dart` | `version`, `nonce`, `ciphertext`, `authenticationTag` | Hive field on `UserRecord` |
| `WrappedKeyCodec` — `lib/core/security/wrapped_key_codec.dart` | JSON/base64 for PIN and biometric material | Not used for Hive (Hive adapter serializes the object) |
| `SessionService` / `SessionServiceImpl` | Holds `_vaultKey` in memory; `clear` zeros it | Opened by `AuthRepositoryImpl.openSession` |
| `FastUnlockStorageKeys` | `pin.material.$userId`, `bio.material.$userId` | Secure storage keys |
| `SecurityConstants.wrappedKeyVersion` | `1` | Unwrap rejects other versions |

Wrap algorithm: encrypt the Vault Key bytes with AES-256-GCM using the derived (or biometric wrap) key. Stored version is `wrappedKeyVersion` (1). When unwrapping, the payload version passed to `CryptoService.decrypt` is `vaultEncryptionVersion` (also 1).

## 6. Data Flow

```text
Random Vault Key (memory, create path only until wrap)
    ↓
AES-GCM under derivedKey → WrappedVaultKey
    ↓
Hive UserRecord
```

```text
WrappedVaultKey + derivedKey
    ↓
AES-GCM decrypt → Vault Key (memory)
    ↓
SessionService._vaultKey
    ↓
VaultRepository / EncryptedBlobStore encrypt/decrypt
    ↓
clear() → fillRange zeros + null
```

`AuthenticatedSession` stores only `userId` and `username`. The Vault Key is a sibling field on `SessionServiceImpl`, not a property of `AuthenticatedSession`.

Master Password change (`changeMasterPassword`):

1. Derive from current password; unwrap; constant-time compare to session key (`_sameKey` XOR fold).
2. Generate **new salt** and default KDF parameters.
3. Derive from new password; wrap the **existing session** Vault Key; unwrap to verify; persist new wrap + salt + params.
4. Session Vault Key is unchanged. Vault ciphertext is not re-encrypted.
5. PIN/biometric material is not rewritten; those wraps still target the same Vault Key.

## 7. Security Considerations

- Vault Key never written plaintext to Hive.
- After `createAccount`, both derived key and Vault Key are zeroed before return; the new account is still locked until `unlock`.
- `openSession` zeros the provided key and returns `AuthenticationFailure` if the user id is missing.
- `SessionServiceImpl._clearVaultKey` overwrites bytes then nulls the reference.
- Wrap/unwrap require 32-byte keys and wrap version 1; otherwise `CryptoFailure`.
- PIN wrap uses Argon2id; biometric wrap stores a random wrap key in secure storage after a successful prompt.
- `_sameKey` is a constant-time-ish XOR comparison (not `==` on lists).

Master Password is not recoverable from `WrappedVaultKey`.

## 8. Error Handling

`KeyManagementServiceImpl` maps non-`CryptoFailure` encrypt/decrypt failures to `CryptoFailure`.

Auth maps unwrap failure to `AuthenticationFailure` and clears the session.

PIN unwrap failures increment `UnlockAttemptLimiter` and return `AuthenticationFailure`.

Biometric crypto unwrap failure returns `AuthenticationFailure`; missing/invalid stored material returns `BiometricNotConfiguredFailure`.

## 9. Edge Cases

- `createAccount` does not call `openSession`.
- `changeMasterPassword` requires an existing session Vault Key; it cannot run while locked.
- If wrap verification after password change fails, the user record is not updated (`CryptoFailure`).
- Biometric JSON includes `wrapKey` in base64; protection is flutter_secure_storage (`AndroidOptions(encryptedSharedPreferences: true)`), plus an in-app biometric prompt before read.

## 10. Testing

- `test/core/crypto/key_management_service_test.dart`
- `test/core/session/session_service_test.dart` — in-memory key set/clear
- `test/feature/auth/auth_repository_test.dart` — wrap on create, unwrap on authenticate
- `test/feature/auth/auth_change_master_password_test.dart` — re-wrap with new salt
- `test/core/security/pin_service_test.dart` — PIN wrap/unwrap of Vault Key

## 11. Technical Decisions

- Random Vault Key + wrapping, not “use KDF output directly as AES key”, so password change does not require re-encrypting `VaultData`.
- Same AES-GCM primitive for wrapping as for vault payload.
- Separate in-memory session key vs `AuthenticatedSession` DTO.
- PIN and biometric each wrap the Vault Key independently of the Master Password wrap.

## 12. Limitations / Notes

- Best-effort zeroization of `Uint8List` in Dart.
- No hardware-backed wrapping beyond OS secure storage for PIN/biometric material.
- `changeMasterPassword` does not rotate the Vault Key itself.
- Whether flutter_secure_storage on iOS uses the Keychain is determined by the plugin; application code only sets Android `encryptedSharedPreferences`.

## 13. Summary

A 32-byte random Vault Key encrypts vault data. Argon2id(Master Password) wraps that key for Hive. PIN and biometric store additional wraps in secure storage. Only `SessionServiceImpl` holds the plaintext Vault Key, and `clear()` overwrites it. Password change re-wraps the same key with a new salt.

Related: [Argon2id](02_argon2id_key_derivation.md), [AES-GCM](03_vault_encryption_aes_gcm.md), [Session](05_authentication_session_lifecycle.md), [Vault Lifecycle](17_vault_process_lifecycle.md).
