# Task 21 — Vault Images

This note describes the **folder-first image albums flow that is actually wired in the codebase**.

It is a learning reference and an implementation record. The source of truth is the Dart code and tests, not the architecture proposals.

Related code:

- [`lib/feature/vault/model/image_folder.dart`](../../lib/feature/vault/model/image_folder.dart)
- [`lib/feature/vault/model/image_item.dart`](../../lib/feature/vault/model/image_item.dart)
- [`lib/feature/vault/blob/encrypted_blob_store.dart`](../../lib/feature/vault/blob/encrypted_blob_store.dart)
- [`lib/feature/vault/blob/encrypted_blob_store_impl.dart`](../../lib/feature/vault/blob/encrypted_blob_store_impl.dart)
- [`lib/feature/type/image/`](../../lib/feature/type/image/)
- [`lib/feature/backup/serialization/backup_payload_codec.dart`](../../lib/feature/backup/serialization/backup_payload_codec.dart)
- [`lib/feature/backup/service/backup_service_impl.dart`](../../lib/feature/backup/service/backup_service_impl.dart)
- [`test/feature/type/image/`](../../test/feature/type/image/)
- [`test/feature/vault/encrypted_blob_store_test.dart`](../../test/feature/vault/encrypted_blob_store_test.dart)
- [`test/feature/backup/backup_images_test.dart`](../../test/feature/backup/backup_images_test.dart)

It does **not** change Master Password handling, Vault Key wrapping, Argon2id / AES-256-GCM primitives, cloud sync, nested folders, or OS photo sharing.

---

## Purpose

Photos are not top-level Home items. The user always creates a **folder** first (for example «عکس‌های شناسنامه»), then adds photos from camera or gallery into that folder.

Home and type list show **folder titles** (subtitle `N عکس`). Tap a folder to open its thumbnail grid. Search matches folder titles, not individual photos. Pin and list delete apply to the folder. Deleting a folder removes child photos and their sidecar files.

---

## Why sidecar blobs

Unlock already decrypts the entire `VaultData` JSON into memory. Full JPEG bytes must not live in that blob.

Hybrid model:

- **Metadata** (`ImageFolder` + `ImageItem`) stays in `VaultData` (same encrypted Hive vault as logins/cards/notes).
- **Bytes** live in app-private files: `getApplicationSupportDirectory()/vault_blobs/{userId}/{blobId}`, encrypted with the session Vault Key (AES-256-GCM). Master password change only rewraps that key.

`VaultData.currentVersion` stays `1`. `imageFolders` and `images` are optional on deserialize so older vaults still open. Both lists default to `const []`.

A photo cannot exist without a `folderId`. One folder level only. Image folders are not `CategoryItem`s; optional `categoryId` still lets them appear under Home category chips.

---

## Capture and limits

`ImageCaptureService` uses `image_picker`. Camera asks for `CAMERA` only. Gallery uses the system photo picker (no `READ_MEDIA_IMAGES`). Cancelled picker is not an error. Permanent denial opens Settings via `AppDialogWidget`.

Longest side is limited to ~1920px in the picker. After prepare, files larger than ~8MB are rejected with a Persian validation message.

Capture is available **inside a folder only**. Home FAB / type-list FAB for `تصاویر` opens **create folder**, then the empty folder contents.

Fail-closed order:

1. Encrypt and write blob(s)
2. Persist `ImageItem`
3. On vault save failure, delete the new blob(s)
4. On photo delete: metadata first, then blobs
5. On folder delete: folder + child metadata, then child blobs
6. Account deletion, lock cache wipe, and restore rollback wipe that user’s blob directory

Restore stages sidecar files beside the live directory, persists `replaceVault`, then swaps. A failed persist rolls blobs back so vault metadata is not left pointing at missing files.

---

## Backup and restore

Images are first-class in `.keyva` files. Task 14 still owns the Backup Password → Argon2id → AES-256-GCM envelope. Task 21 adds the v2 plaintext payload `{ "vault": <VaultData JSON>, "imageBlobs": { blobId: base64 } }`.

Create backup decrypts sidecars with the **session** Vault Key. Missing blobs fail closed. Both restore paths (`restoreVault` and `restoreIntoNewAccount`) rewrite sidecars with the **current** Vault Key after the account is unlocked. v1 files (raw `VaultData`, no images) still restore with empty folders/photos.

Preview copy includes `پوشه تصویر: N` and `تصویر: M`.

See [`14_backup_restore.md`](14_backup_restore.md) for the envelope.

---

## UI

- Folder create / edit
- Folder contents grid + FAB (camera / gallery source sheet)
- Add-photo preview with retake
- Photo detail (decrypted image, optional note, delete)
- No OS share of photos in this slice

Persian strings are hardcoded, same as the rest of the app.

---

## Permissions

- Android: `CAMERA` only. Merged gallery storage permissions from plugins are removed with `tools:node="remove"`.
- iOS: `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription` in Persian. No save-to-library usage.

---

## Tests

Serializer round-trip, legacy JSON without image keys, photo with missing folder, folder CRUD and cascade blobs, `EncryptedBlobStore` temp directory, backup create + `restoreVault` + `restoreIntoNewAccount` with images, v1 compatibility, missing blob at create time, widget tests with a fake capture service (no real camera).
