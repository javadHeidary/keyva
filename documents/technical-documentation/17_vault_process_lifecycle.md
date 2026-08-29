# Vault Process / Vault Lifecycle

## 1. Overview

The Keyva vault is an encrypted, per-account blob of structured items (logins, bank cards, secure notes, categories, image folders, image metadata) plus separately encrypted image files. This document describes the implemented lifecycle: account/key creation, unlock, in-memory session, read/write of records, persistence, and lock. It synthesizes the services in `lib/feature/vault/` with crypto, Hive, and session code.

## 2. Purpose

A single encrypted `VaultRecord` per user keeps all item types under one AES-GCM key (the Vault Key). The lifecycle exists so that plaintext `VaultData` exists only while unlocked, mutations always re-encrypt the whole JSON document, and lock wipes both the key and the object graph.

## 3. Architecture

There is no Domain / UseCase layer.

| Layer | Components |
| --- | --- |
| Presentation | Home, type forms, details, search |
| ViewModel | `HomeController`, `VaultHomeViewModel`, `VaultItemViewModel`, type-specific form VMs |
| Services | `VaultUnlockService`, `VaultOperationService`, `VaultDataService`, `ImagePhotoService`, `ImageGalleryExportService` |
| Repository | `VaultRepository` (encrypt/decrypt + Hive vault row); `AuthRepository` (key wrap / session) |
| Serialization | `VaultSerializerImpl` (JSON) |
| Session | `SessionService` (Vault Key); `VaultSession` (`VaultData`) |
| Blobs | `EncryptedBlobStoreImpl` (image files) |
| Data Source | `HiveVaultDataSource`, `HiveUserDataSource` |
| Core crypto | `CryptoService`, `KeyManagementService` |
| Local Storage | Hive `users` / `vaults` / `app_settings`; `vault_blobs/<userId>/` |
| Domain | Not present |

```text
View
    ↓
ViewModel
    ↓
VaultUnlockService / VaultOperationService
    ↓
AuthRepository / VaultDataService / VaultRepository
    ↓
CryptoService + Hive / EncryptedBlobStore
```

## 4. Implementation Flow

High-level (detail in later sections):

```text
createAccount (wrap Vault Key, persist UserRecord, zero keys)
    ↓
unlock (master / PIN / biometric)
    ↓
openSession (Vault Key in memory)
    ↓
loadVaultData or VaultData.initial()
    ↓
VaultSession.unlock
    ↓
CRUD via VaultOperationService → serialize → encrypt → Hive
    ↓
lock / auto-lock / logout → clear cache, drop VaultData, zero Vault Key
```

## 5. Important Classes & Files

| Class / File | Responsibility | Relationship |
| --- | --- | --- |
| `VaultData` — `lib/feature/vault/model/vault_data.dart` | In-memory vault; `currentVersion` 1; `maxPinnedItems` 5; `initial()` seeds default categories | Held by `VaultSession` |
| `LoginItem`, `BankCardItem`, `SecureNoteItem`, `CategoryItem`, `ImageFolder`, `ImageItem` | Item models | Lists on `VaultData` |
| `VaultSession` / `VaultSessionImpl` | `isUnlocked` iff `vaultData != null` | Memory only |
| `VaultUnlockServiceImpl` | Unlock/lock orchestration | Auth + load + deserialize |
| `VaultRepository` / `VaultRepositoryImpl` | Encrypt/decrypt vault JSON; Hive I/O | Needs session key |
| `VaultSerializer` / `VaultSerializerImpl` | UTF-8 JSON | Schema keys in serializer |
| `VaultDataServiceImpl` | Mutate collections; enqueue; persist; refresh session | Serializes whole vault each time |
| `VaultOperationServiceImpl` | Typed `addItem`/`updateItem`/`deleteItem`/`setItemPinned`/`getVault` | Blob deletes on image/folder delete |
| `EncryptedBlobStoreImpl` | AES-GCM image files + memory cache | Path `vault_blobs/<userId>/<blobId>` |
| `ImagePhotoService` | Write blobs then `addItem(ImageItem)` | Rollback blobs if item add fails |
| `ImageGalleryExportService` | Decrypt blob then save bytes via `gal` | User-initiated; does not mutate vault files |
| `UserRecord` / `VaultRecord` | Hive metadata vs ciphertext | Different boxes |
| `AuthRepositoryImpl.createAccount` / `authenticate` / `openSession` / `logout` | Key wrap and session | |

Leftover `LoginVaultStore` / `BankCardVaultStore` / `NoteVaultStore` are registered in Bindings with sample data but are not the persistence path (see [MVVM](12_mvvm_architecture_viewmodels.md)).

## 6. Data Flow

**Raw secrets (passwords, PAN, notes, image pixels):** ViewModel fields and `VaultData` / blob cache while unlocked.

**Derived:** Argon2id output from Master Password or PIN (zeroed after wrap/unwrap). Backup password similarly during backup.

**Encrypted:** `WrappedVaultKey` on `UserRecord`; `VaultRecord.ciphertext`; blob files.

**Persisted unencrypted (not vault secrets):** username, KDF salt/params, security flags, app settings, wrapped-key ciphertext.

**Memory:** `SessionService._vaultKey`; `VaultSession._vaultData`; `EncryptedBlobStoreImpl._cache`.

## 7. Security Considerations

- Vault Key never stored plaintext.
- AES-256-GCM for vault JSON and blobs; GCM MAC fail → `VaultDecryptionFailure`.
- Lock zeros the Vault Key and drops `VaultData`.
- Mutations require `VaultSession.isUnlocked`; encrypt requires session key.
- Whole-document encrypt on every change (no plaintext item rows in Hive).
- Image bytes encrypted with the same Vault Key; metadata (blob ids) lives in JSON.
- Gallery export decrypts in memory and writes to the OS gallery only after an explicit header action; encrypted sidecar files are not modified.
- Fail-closed unlock: decrypt/deserialize failure locks and logs out.
- Pin limit: 5 pinned items (`PinLimitFailure`).

## 8. Error Handling

`Result<T>` throughout. Unlock failures: `AuthenticationFailure` or biometric-specific types. Persistence: `CryptoFailure`, `DatabaseFailure`, `ValidationFailure` (duplicate id, missing item, image without folder). UI: `VaultUiStatus` + `vaultUserMessage`.

`VaultDataServiceImpl._enqueue` chains mutations so overlapping saves do not interleave.

## 9. Edge Cases

- First unlock with no `VaultRecord`: `VaultData.initial()` (default categories). First mutation creates the Hive vault row.
- `createAccount` does not create a `VaultRecord` or a session.
- Deleting an image folder removes child `ImageItem`s from JSON and deletes their blobs.
- `replaceVault` (restore) writes then `VaultSession.unlock(restoredVault)` without going through per-item add.
- `VaultItemViewModel._isValid` rejects empty required fields before `addItem`.
- Blob id must match `[a-f0-9]{32}`.

## 10. Testing

- `test/feature/vault/vault_repository_test.dart`
- `test/feature/vault/vault_data_service_test.dart`
- `test/feature/vault/vault_operation_service_test.dart`
- `test/feature/vault/vault_serializer_test.dart`
- `test/feature/vault/vault_serialization_persistence_test.dart`
- `test/feature/vault/encrypted_blob_store_test.dart`
- `test/feature/vault/vault_unlock_service_test.dart`
- `test/feature/vault/vault_session_test.dart`
- `test/feature/vault/vault_home_viewmodel_test.dart`
- `test/feature/vault/vault_item_viewmodel_test.dart`
- `test/feature/vault/vault_models_test.dart`
- `test/feature/auth/auth_session_lifecycle_test.dart`
- `test/feature/type/image/image_photo_service_test.dart`
- `test/feature/type/image/image_gallery_export_service_test.dart`
- `test/feature/type/image/image_details_viewmodel_test.dart`

## 11. Technical Decisions

- One encrypted JSON document per user rather than per-item Hive objects.
- Vault Key wrapping so password change does not rewrite all ciphertext.
- Images as encrypted files (size) with ids in JSON.
- `VaultDataService` as the write-through layer; `VaultOperationService` as the ViewModel-facing API including pin limits and blob cleanup.
- Mutation queue to serialize writes.

## 12. Limitations / Notes

- Every edit re-serializes and re-encrypts the entire vault.
- Dart does not guarantee `fillRange` wipes copies of keys.
- Leftover in-memory `*VaultStore` services still start with sample items if constructed; they are not read by the encrypted CRUD path.
- `VaultSession.lock` only nulls the reference; it does not walk `VaultData` to zero strings.

## 13. Summary

Create account wraps a random Vault Key and stores it on `UserRecord`. Unlock unwraps that key into `SessionService`, decrypts Hive bytes (or uses an empty `VaultData.initial()`), and holds the graph in `VaultSession`. Reads come from that graph. Writes rebuild `VaultData`, JSON-serialize, AES-GCM-encrypt, and put `VaultRecord`. Images use `EncryptedBlobStore`. Lock clears cache, session data, and the Vault Key.

---

## Vault Creation

**When:** `AuthRepositoryImpl.createAccount`, invoked from `RegisterController.createAccount` or `BackupServiceImpl.restoreIntoNewAccount`.

**Vault Key:** `KeyManagementService.generateVaultKey()` — 32 random bytes.

**Master Password:** Input to `CryptoService.deriveKey` with a new 16-byte salt and `defaultKdfParameters()` (Argon2id). Never stored.

**KDF:** Argon2id as in [Argon2id Key Derivation](02_argon2id_key_derivation.md).

**Salt:** Generated, stored on `UserRecord.kdfSalt`.

**Persisted:** `UserRecord` (id, username, timestamps, salt, KDF params, `WrappedVaultKey`, `SecuritySettings.initial()`, avatar). No `VaultRecord` yet. Derived key and Vault Key are `fillRange` zeroed; **session is not opened**.

Register then calls `VaultUnlockService.unlock` with the same password so the user lands in an unlocked shell.

```text
username + masterPassword
    ↓
unique UUID userId
    ↓
salt + KdfParameters
    ↓
derivedKey = Argon2id(masterPassword, salt, params)
    ↓
vaultKey = random 32 bytes
    ↓
wrapped = AES-GCM(vaultKey) under derivedKey
    ↓
zero derivedKey and vaultKey
    ↓
Hive users.put(UserRecord)
```

---

## Vault Unlock

Implemented in `VaultUnlockServiceImpl`. Three authenticators converge on `_openVault`.

**Master Password**

```text
Master Password
    ↓
CryptoService.deriveKey (UserRecord salt + params)
    ↓
KeyManagementService.unwrapVaultKey
    ↓
zero derivedKey
    ↓
SessionService.setAuthenticated (in-memory Vault Key)
    ↓
remember activeUserId
    ↓
reset PIN + biometric attempt counters
    ↓
VaultRepository.loadVaultData
    ↓
null → VaultData.initial()
    else VaultSerializer.deserialize
    ↓
VaultSession.unlock
    ↓
ScreenProtectionService.applyPersisted
```

**PIN:** `PinService.unwrapVaultKey` (Argon2id(PIN) + secure-storage wrap) → `openSession` → `_openVault`. Failures `_failClosed`.

**Biometric:** platform prompt + secure-storage wrap key → unwrap → `openSession` → `_openVault`. Prompt-class failures are **not** `_failClosed`.

**`_failClosed`:** `VaultSession.lock` + `AuthRepository.logout` + return failure.

Wrong master password never distinguishes “no user” vs “bad crypto”; both become `AuthenticationFailure` after `session.clear()`.

---

## Vault Session

**When the Vault Key becomes available:** `openSession` / `setAuthenticated`, after a successful unwrap. Not during `createAccount`.

**What represents locked / unlocked:**

| Signal | Locked | Unlocked |
| --- | --- | --- |
| `SessionService.isAuthenticated` | false | true |
| `SessionService.vaultKey` | null | 32 bytes |
| `VaultSession.isUnlocked` | false | true |
| `VaultSession.vaultData` | null | `VaultData` |

**Session created:** successful unlock path.

**Session destroyed:** `VaultUnlockService.lock` (blob `clearCache`, `VaultSession.lock`, `logout`/`clear`); also `_failClosed`, `deleteAccount`, `_authenticationFailed`.

**Sensitive data:** Vault Key overwritten on clear. `VaultData` reference dropped (strings not explicitly wiped). Blob plaintext cache cleared on lock.

`AuthenticatedSession` holds only `userId` and `username`.

---

## Reading Vault Data

```text
Hive VaultRecord (nonce + ciphertext||tag)
    ↓
VaultRepositoryImpl._payloadFromRecord (split 16-byte tag)
    ↓
CryptoService.decrypt(session.vaultKey)
    ↓
UTF-8 JSON
    ↓
VaultSerializer.deserialize
    ↓
VaultData
    ↓
VaultSession (already populated on unlock)
    ↓
VaultOperationService.getVault
    ↓
VaultHomeViewModel / type ViewModels
    ↓
UI
```

If there is no row, unlock skipped decrypt and used `VaultData.initial()`. Later `getVault` reads memory, not Hive, until a mutation persists.

**Images:** `ImageItem.blobId` / `thumbnailBlobId` in JSON. Bytes: `EncryptedBlobStore.read` → cache or decrypt file with Vault Key. Display uses that read. Save-to-gallery (`ImageGalleryExportService`) uses the same read, then `gal.putImageBytes`; the encrypted sidecar is not rewritten.

---

## Creating / Updating Vault Records

ViewModels build models (`LoginItem`, …) then `VaultItemViewModel.create` / `updateItem` or `ImagePhotoService.addPhoto`.

```text
Input (form fields / image bytes)
    ↓
ViewModel validation (_isValid / form validators)
    ↓
Item model (ids often DateTime.millisecondsSinceEpoch)
    ↓
VaultOperationService.addItem / updateItem
    ↓
VaultDataService._mutate (queued)
    ↓
copy lists; reject duplicate id (add) or missing id (update)
    ↓
VaultSerializer.serialize (full VaultData JSON)
    ↓
VaultRepository.saveVaultData
    ↓
AES-GCM with session Vault Key
    ↓
Hive create or update VaultRecord
    ↓
VaultSession.unlock(candidate)  // memory matches disk
```

**Delete:** `deleteItem` finds the collection, `VaultDataService.delete*`, persist; for images/folders also `EncryptedBlobStore.deleteMany`.

**Pin:** `setItemPinned` enforces `VaultData.maxPinnedItems` (5) on logins, cards, notes, image folders.

**Images create:** encrypt bytes to new blob ids, then add `ImageItem` (folder must exist). Failure after blob write deletes blobs.

There is no partial Hive update of a single field; the document is atomic from the app’s point of view (one `put` of `VaultRecord`). Concurrent mutations are serialized in `VaultDataServiceImpl._tail`.

---

## Vault Lock

`VaultUnlockServiceImpl.lock`:

```text
EncryptedBlobStore.clearCache
    ↓
VaultSession.lock   // _vaultData = null
    ↓
AuthRepository.logout → SessionService.clear  // zero Vault Key
```

**Triggers implemented in code:**

| Trigger | Path |
| --- | --- |
| Manual lock / logout | `SettingsViewModel.lock`, `onLogoutConfirmed` |
| Auto lock | `AppLockController._lock` (background timer, resume after timeout, immediate timeout, persisted pause) |
| Startup pause | `AuthStartupViewModel` if authenticated and pause expired |
| Failed unlock (master/PIN/crypto) | `_failClosed` or `_authenticationFailed` |
| Account delete | `session.clear` then ViewModel also calls `lock` |

Not implemented as auto-lock: foreground idle timer, failed master-password attempt count.

After lock, `Get.offAllNamed(authAccounts)` from settings or `AppLockController` (skipped if already on auth routes). `SessionGuard` sends unauthenticated navigation to `/auth/accounts`.

UI overlay during background: `PrivacyOverlay` (see [Auto Lock](08_auto_lock.md)).

---

## Vault Persistence

**Hive CE boxes**

| Box | Contents |
| --- | --- |
| `users` | `UserRecord` including wrapped Vault Key |
| `vaults` | `VaultRecord` per userId |
| `app_settings` | version, activeUserId, theme, onboarding, lockout counters, lastBackgroundedAt |

Hive is not box-encrypted. Application encryption:

- **Layer:** `VaultRepositoryImpl` for JSON; `EncryptedBlobStoreImpl` for files.
- **Repository role:** obtain session key, encrypt/decrypt, map to `VaultRecord`. Does not parse JSON.
- **Serializer:** `VaultSerializerImpl` maps `VaultData` ↔ UTF-8 JSON with required keys `version`, `logins`, `bankCards`, `secureNotes`, `categories`; optional `imageFolders`, `images`.

**Blob files:** `{appSupport}/vault_blobs/{userId}/{blobId}` with layout `version(1) || nonce(12) || tag(16) || ciphertext`. Staging dirs `.next` / `.prev` used during restore replace.

---

## Vault Lifecycle Diagram

```text
Register / restore-new-account
    ↓
Generate Vault Key (32 random bytes)
    ↓
Argon2id(Master Password, new Salt, default KDF params) → Derived Key
    ↓
AES-GCM wrap Vault Key → persist UserRecord
    ↓
Zero Derived Key and Vault Key  (vault still locked)
    ↓
User Authentication (Master Password | PIN | Biometric)
    ↓
Unwrap Vault Key → SessionService.setAuthenticated
    ↓
Decrypt Hive VaultRecord if present, else VaultData.initial()
    ↓
Deserialize JSON → VaultSession.unlock
    ↓
Read items from VaultSession / getVault
    ↓
Create / Update / Delete / Pin
    ↓
Serialize full VaultData → AES-GCM → Hive VaultRecord
    (+ EncryptedBlobStore for image bytes)
    ↓
Manual Lock | Auto-Lock | Logout | Fail-closed auth
    ↓
clearCache + drop VaultData + zero Vault Key
    ↓
Vault locked (UserRecord + ciphertext remain on disk)
```

Related: [Master Password](01_master_password_account_lifecycle.md), [Argon2id](02_argon2id_key_derivation.md), [AES-GCM](03_vault_encryption_aes_gcm.md), [Vault Key](04_vault_key_management.md), [Session](05_authentication_session_lifecycle.md), [PIN](06_pin_authentication_lockout.md), [Biometric](07_biometric_authentication.md), [Auto Lock](08_auto_lock.md), [Backup](09_secure_backup_restore.md), [Hive](10_hive_ce_local_storage.md), [GetIt](11_dependency_injection_getit.md), [MVVM](12_mvvm_architecture_viewmodels.md).
