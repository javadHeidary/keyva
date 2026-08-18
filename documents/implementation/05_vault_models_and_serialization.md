# Task 05 — Vault Data Models and Serialization

This note describes the **in-memory vault models and schema-strict serializer that are actually in the codebase**.

It is a learning reference and an implementation record. The source of truth is the Dart code and tests, not the architecture proposals.

Related code:

- [`lib/feature/vault/model/vault_data.dart`](../../lib/feature/vault/model/vault_data.dart)
- [`lib/feature/vault/model/login_item.dart`](../../lib/feature/vault/model/login_item.dart)
- [`lib/feature/vault/model/bank_card_item.dart`](../../lib/feature/vault/model/bank_card_item.dart)
- [`lib/feature/vault/model/secure_note_item.dart`](../../lib/feature/vault/model/secure_note_item.dart)
- [`lib/feature/vault/model/category_item.dart`](../../lib/feature/vault/model/category_item.dart)
- [`lib/feature/vault/serialization/vault_serializer.dart`](../../lib/feature/vault/serialization/vault_serializer.dart)
- [`lib/feature/vault/serialization/vault_serializer_impl.dart`](../../lib/feature/vault/serialization/vault_serializer_impl.dart)
- [`lib/core/exceptions/app_failure.dart`](../../lib/core/exceptions/app_failure.dart)
- [`lib/core/di/injection_container.dart`](../../lib/core/di/injection_container.dart)
- [`test/feature/vault/vault_models_test.dart`](../../test/feature/vault/vault_models_test.dart)
- [`test/feature/vault/vault_serializer_test.dart`](../../test/feature/vault/vault_serializer_test.dart)
- [`test/feature/vault/vault_serialization_persistence_test.dart`](../../test/feature/vault/vault_serialization_persistence_test.dart)

---

## 1. Purpose

Task 05 introduces the decrypted vault structure and a dedicated serializer on top of Task 04’s byte-oriented encrypted persistence.

In simple terms, this layer answers:

1. What does an unlocked vault look like in memory?
2. How is that structure turned into bytes before AES-GCM encryption?
3. How are those bytes turned back into models after decryption?
4. How does invalid or future-version data fail closed without leaking contents?

It reuses Task 04 (`VaultRepository` `Uint8List` API, Hive `VaultRecord`, AES-256-GCM) and Task 01 (`Result` / `AppFailure`, GetIt). It does **not** encrypt, decrypt, talk to Hive, or add login/card/note CRUD.

---

## 2. Models

These types live under [`lib/feature/vault/model/`](../../lib/feature/vault/model/). They are **not** Hive models. They have no adapters and are never written to a box.

They are also **not** the existing UI prototype types in `lib/feature/type/` (`LoginItem` with `websites`, `BankCardItem` with `bankTitle`, `NoteItem` with `body`). Those UI classes were left unchanged.

| Class | File | Fields |
|-------|------|--------|
| `VaultData` | `vault_data.dart` | `version`, `logins`, `bankCards`, `secureNotes`, `categories` |
| `LoginItem` | `login_item.dart` | `id`, `title`, `username`, `password`, `website?`, `notes?`, `categoryId?`, `createdAt`, `updatedAt` |
| `BankCardItem` | `bank_card_item.dart` | `id`, `title`, `cardNumber`, `cardHolder`, `expiryDate`, `cvv`, `bankName`, `notes?`, `categoryId?`, `createdAt`, `updatedAt` |
| `SecureNoteItem` | `secure_note_item.dart` | `id`, `title`, `content`, `categoryId?`, `createdAt`, `updatedAt` |
| `CategoryItem` | `category_item.dart` | `id`, `name`, `icon?`, `createdAt` |

`VaultData.currentVersion` is `1`. This is the **plaintext vault structure** version. It is independent of `SecurityConstants.vaultEncryptionVersion`, which versions the AES-GCM envelope on `VaultRecord`.

---

## 3. Model responsibilities

Models only represent decrypted vault data.

They do:

- Hold the fields defined in `documents/architecture/05_data_models.md`
- Copy collections into `List.unmodifiable(...)` so callers cannot mutate vault lists
- Provide value equality (`==` / `hashCode`) for round-trip tests

They do **not**:

- Encrypt, decrypt, or derive keys
- Access Hive, GetIt, GetX, or `SessionService`
- Carry UI state or Hive annotations
- Expose mutation methods (`copyWith`, add/remove)

Nullable fields are constructor parameters that must be passed explicitly, including `null`. That matches the serializer’s “absence is not null” rule at the JSON layer.

---

## 4. Serialization format

The format is **canonical UTF-8 JSON**: `jsonEncode` of ordered maps, then `utf8.encode`. Compact (no indent). `jsonEncode` includes JSON `null` for nullable keys.

Root object key order:

```text
version, logins, bankCards, secureNotes, categories
```

Item key order:

```text
LoginItem:      id, title, username, password, website, notes, categoryId, createdAt, updatedAt
BankCardItem:   id, title, cardNumber, cardHolder, expiryDate, cvv, bankName, notes, categoryId, createdAt, updatedAt
SecureNoteItem: id, title, content, categoryId, createdAt, updatedAt
CategoryItem:   id, name, icon, createdAt
```

Timestamps are UTC ISO-8601 strings (`DateTime.toUtc().toIso8601String()`).

The format is deterministic: serializing the same `VaultData` twice produces identical bytes.

### Schema-strict contract

Every object has a **closed, exact key set**.

- Every expected key must be present, including nullable keys.
- Nullable keys are written as JSON `null`. Omitting a key is not treated as null.
- Unknown keys are rejected at every object level.
- No implicit defaults: missing lists are not `[]`, missing version is not `1`, missing nullables are not filled in.
- JSON `null` is valid only for declared nullable strings. Required `int` / `String` / `List` values that are `null` fail.
- Collections must be JSON arrays of objects. Each item is checked against its own exact key set.

---

## 5. Versioning

`VaultData.version` must equal `VaultData.currentVersion` (`1`) on both serialize and deserialize.

- Supported version `1` → parse normally
- Any other integer (including future versions) → `ValidationFailure`
- Missing version, non-int version, or `null` version → `ValidationFailure`

There is **no migration** in this task. `VaultRecord.formatVersion` was not changed.

---

## 6. Serialization flow

```text
VaultData
        ↓
validate version == 1
validate non-empty unique IDs per collection
        ↓
ordered Map (nullable fields as JSON null)
        ↓
jsonEncode (compact)
        ↓
utf8.encode
        ↓
Success(Uint8List)
```

If validation or encoding throws, the result is `FailureResult(ValidationFailure())`. The catch path does not copy `error.toString()`.

---

## 7. Deserialization flow

```text
Uint8List
        ↓
utf8.decode
        ↓
jsonDecode
        ↓
require JSON object
require exact root keys
        ↓
type-check version, lists, and every item
require exact item keys
parse timestamps as UTC
        ↓
construct VaultData (unmodifiable lists)
validate version and unique IDs again
        ↓
Success(VaultData)
```

Malformed UTF-8, malformed JSON, missing keys, extra keys, wrong types, duplicate IDs, empty IDs, invalid timestamps, and unsupported versions all fail closed as `ValidationFailure`.

---

## 8. Failure handling

Existing `Result<T>` / `FailureResult<T>` is reused.

New failure type only:

```dart
final class ValidationFailure extends AppFailure {
  const ValidationFailure({
    super.message = 'Vault data is invalid',
  });
}
```

This is the architecture-09 recommended type for structural validation. It is **not** used for AES-GCM failures (`VaultDecryptionFailure` / `CryptoFailure` stay on the repository/crypto boundary).

The message is always the generic default. Tests assert it does not contain passwords, serialized JSON, or exception class names such as `FormatException`.

`VaultSerializerImpl` uses a private `_VaultSchemaException` for control flow. That type has no message and is never returned to callers.

---

## 9. Security boundary

The serializer converts `VaultData` ↔ `Uint8List` only.

It does **not**:

- Derive keys
- Encrypt or decrypt
- Read `SessionService`
- Access Hive
- Call GetIt
- Know the Master Password or Vault Key

Plaintext JSON exists only as the in-memory `Uint8List` passed into or returned from `VaultRepository`. Hive still stores AES-GCM ciphertext.

---

## 10. Repository integration

[`VaultRepository`](../../lib/feature/vault/repository/vault_repository.dart) is still byte-oriented:

```dart
Future<Result<Uint8List?>> loadVaultData();
Future<Result<void>> saveVaultData(Uint8List plaintext);
Future<Result<void>> deleteVault();
```

`VaultSerializer` is registered **beside** the repository, not injected into `VaultRepositoryImpl`. Task 04 tests still construct the repository with `vaults`, `crypto`, and `session` only.

The composed path used by the integration test:

```text
VaultData
  → VaultSerializer.serialize
  → Uint8List
  → VaultRepository.saveVaultData
  → AES-256-GCM
  → VaultRecord / Hive
  → VaultRepository.loadVaultData
  → Uint8List
  → VaultSerializer.deserialize
  → VaultData
```

---

## 11. GetIt registration

Still one composition root: [`injection_container.dart`](../../lib/core/di/injection_container.dart).

```text
...
registerLazySingleton<SessionService>       → SessionServiceImpl
registerLazySingleton<VaultSerializer>      → VaultSerializerImpl   ← new
registerLazySingleton<AuthRepository>       → AuthRepositoryImpl
registerLazySingleton<VaultRepository>      → VaultRepositoryImpl   (unchanged constructor)
```

`VaultSerializerImpl` has a zero-argument constructor. Implementations still do not look up GetIt themselves.

---

## 12. Tests

| Test file | What it actually checks |
|-----------|-------------------------|
| [`vault_models_test.dart`](../../test/feature/vault/vault_models_test.dart) | Valid construction; field preservation; explicit null optionals; value equality; mutating source lists after construction does not change `VaultData`; exposed lists throw `UnsupportedError` |
| [`vault_serializer_test.dart`](../../test/feature/vault/vault_serializer_test.dart) | Empty vault; one/many logins; card; note; category; mixed vault with IDs, timestamps, and `categoryId`; explicit JSON `null` round-trip; determinism; fail closed for empty/malformed/UTF-8 bytes, unsupported version, omitted version, omitted lists, missing nullable keys, unknown keys, wrong types, `null` on required fields, invalid timestamps, duplicate IDs; serialize rejects version `2` and duplicate IDs; failure messages stay generic |
| [`vault_serialization_persistence_test.dart`](../../test/feature/vault/vault_serialization_persistence_test.dart) | Real Hive + `CryptoServiceImpl` + `SessionServiceImpl` + `VaultRepositoryImpl`: serialize → save → load → deserialize equals the original; stored ciphertext does not contain the plaintext JSON |
| [`hive_database_test.dart`](../../test/core/hive_database_test.dart) | `initDependencies` also registers `VaultSerializer` |

Task 04 [`vault_repository_test.dart`](../../test/feature/vault/vault_repository_test.dart) was not rewritten and still passes.

---

## 13. Persisted vs in-memory data

### In memory (this task)

- `VaultData` and item models after deserialize / before serialize
- UTF-8 JSON bytes only as the serializer output / repository plaintext argument

### Persisted (unchanged from Task 04)

Hive `vaults` box still stores `VaultRecord`: `userId`, `formatVersion`, nonce, ciphertext including the AES-GCM tag, `updatedAt`.

### Never persisted as plaintext

- Login passwords, card numbers, CVVs, note content, usernames
- `VaultData` JSON
- Vault Key / Master Password

---

## 14. Current limitations

- ViewModels and the prototype UI still use in-memory type stores. They do not call `VaultSerializer` or `VaultRepository` yet.
- There is no mapping between UI prototype models and these vault models.
- `SessionService` still does not hold decrypted `VaultData`.
- Empty-ID and duplicate-ID checks are per collection. Cross-collection ID uniqueness is not required.
- Referential integrity of `categoryId` is not validated (orphan category IDs round-trip as stored).
- Version `1` only. No schema migration.

---

## 15. Explicit non-goals

This task does **not** provide:

- Login / bank card / secure note / category CRUD
- Wiring GetX ViewModels or Bindings
- Changing `VaultRepository` to accept `VaultData`
- Changes to Argon2id, AES-GCM, `SecurityConstants`, `UserRecord`, `WrappedVaultKey`, or Hive adapters
- A UseCase / Domain / Interactor layer
- Backup / restore, PIN, biometrics, auto-lock, Master Password change
- A second DI file or GetIt lookups inside the serializer
