

---

# `05_data_models.md`

````md
# Keyva Data Models

## Purpose

This document defines the data models used by Keyva.

It specifies:

- User model
- Vault model
- Vault item models
- Security settings
- Backup-related models
- Version fields
- Model responsibilities
- Hive persistence boundaries

This document defines the data structure only.

Cryptographic behavior is defined in:

`03_cryptography.md`

Authentication and session behavior are defined in:

`04_authentication_and_session.md`

---

# 1. Architecture Context

Keyva uses MVVM architecture.

The data models MUST NOT introduce a different architectural pattern.

The application structure MUST remain compatible with:

```text
View
   ↓
ViewModel
   ↓
Repository / Service
   ↓
Data Source
   ↓
Hive
````

Do NOT introduce:

* UseCase layer
* Interactor layer
* Domain layer
* Entity/DTO mapper layer
* Clean Architecture folder structure

unless explicitly requested later.

---

# 2. Model Responsibilities

Models are responsible only for representing data.

Models MUST NOT:

* Perform navigation.
* Access GetX.
* Access Hive directly unless they are persistence adapters explicitly designed for Hive.
* Perform encryption.
* Perform authentication.
* Modify application state.
* Contain UI logic.

---

# 3. UserRecord

`UserRecord` represents one local Keyva account.

Conceptual structure:

```text
UserRecord
├── id
├── username
├── createdAt
├── updatedAt
├── kdfSalt
├── kdfParameters
├── wrappedVaultKey
└── securitySettings
```

---

# 4. UserRecord Fields

## id

Type:

```dart
String
```

Purpose:

Unique identity of the account.

Requirements:

* MUST be unique.
* MUST be generated during account creation.
* SHOULD use UUID v4.
* MUST remain unchanged for the lifetime of the account.

The ID MUST NOT be derived from:

* Username
* Master Password
* Device ID
* Timestamp

---

## username

Type:

```dart
String
```

Purpose:

Display name of the account.

Requirements:

* Persian username.
* Used for UX only.
* NOT an authentication identifier.
* NOT an encryption key.

Changing this value MUST NOT affect:

* User ID
* Vault Key
* Encrypted Vault

---

## createdAt

Type:

```dart
DateTime
```

Purpose:

Account creation timestamp.

---

## updatedAt

Type:

```dart
DateTime
```

Purpose:

Last modification timestamp for account metadata.

---

## kdfSalt

Type:

```dart
List<int>
```

Purpose:

Salt used by Argon2id.

Requirements:

* Cryptographically random.
* Unique per account.
* Not secret.
* Persisted with the account.

---

## kdfParameters

Type:

```dart
KdfParameters
```

Purpose:

Stores the parameters required to reproduce the password-derived key.

---

## wrappedVaultKey

Type:

```dart
WrappedVaultKey
```

Purpose:

Stores the encrypted/wrapped Vault Key.

The plaintext Vault Key MUST NOT exist in `UserRecord`.

---

## securitySettings

Type:

```dart
SecuritySettings
```

Purpose:

Stores non-secret security preferences.

---

# 5. KdfParameters

Conceptual model:

```text
KdfParameters
├── algorithm
├── memoryCost
├── timeCost
├── parallelism
└── outputLength
```

Recommended Dart representation:

```dart
class KdfParameters {
  final String algorithm;
  final int memoryCost;
  final int timeCost;
  final int parallelism;
  final int outputLength;
}
```

The exact Argon2id values are defined in:

`03_cryptography.md`

The model MUST store the values actually used for that account.

---

# 6. WrappedVaultKey

Conceptual model:

```text
WrappedVaultKey
├── version
├── nonce
├── ciphertext
└── authenticationTag
```

Recommended representation:

```dart
class WrappedVaultKey {
  final int version;
  final List<int> nonce;
  final List<int> ciphertext;
  final List<int> authenticationTag;
}
```

The plaintext Vault Key MUST NOT be a field in this model.

---

# 7. SecuritySettings

Conceptual model:

```text
SecuritySettings
├── biometricEnabled
├── pinEnabled
├── autoLockTimeout
└── preventScreenshots
```

Recommended representation:

```dart
class SecuritySettings {
  final bool biometricEnabled;
  final bool pinEnabled;
  final Duration autoLockTimeout;
  final bool preventScreenshots;
}
```

These values are preferences, not cryptographic secrets.

---

# 8. PIN Storage

`SecuritySettings` MUST NOT contain:

```text
pin
plainPin
pinHash
derivedPinKey
```

PIN-related secret material MUST be handled by the secure local unlock mechanism defined by the authentication architecture.

---

# 9. VaultRecord

`VaultRecord` represents the persisted encrypted vault belonging to a UserRecord.

Conceptual:

```text
VaultRecord
├── userId
├── formatVersion
├── nonce
├── ciphertext
└── updatedAt
```

Recommended representation:

```dart
class VaultRecord {
  final String userId;
  final int formatVersion;
  final List<int> nonce;
  final List<int> ciphertext;
  final DateTime updatedAt;
}
```

---

# 10. VaultRecord Ownership

Every `VaultRecord` MUST belong to exactly one user.

Relationship:

```text
UserRecord.id
       ↓
VaultRecord.userId
```

Example:

```text
User A
  id = abc123

Vault A
  userId = abc123
```

A vault MUST NOT be accessible using another user's ID.

---

# 11. VaultData

`VaultData` represents the plaintext vault structure after successful decryption.

Conceptual:

```text
VaultData
├── logins
├── bankCards
├── secureNotes
└── categories
```

Recommended:

```dart
class VaultData {
  final List<LoginItem> logins;
  final List<BankCardItem> bankCards;
  final List<SecureNoteItem> secureNotes;
  final List<CategoryItem> categories;
}
```

`VaultData` MUST NOT be persisted as plaintext.

It exists in memory while the vault is unlocked.

---

# 12. VaultData Security Rule

All fields inside `VaultData` MUST be treated as sensitive unless explicitly classified otherwise.

Examples:

```text
Login password
Bank card number
Secure note content
Username
Website
Card holder
```

All such data MUST be encrypted as part of the vault.

Do NOT create separate plaintext Hive boxes for these items.

---

# 13. LoginItem

Represents a saved login credential.

Conceptual:

```text
LoginItem
├── id
├── title
├── username
├── password
├── website
├── notes
├── categoryId
├── createdAt
└── updatedAt
```

Recommended:

```dart
class LoginItem {
  final String id;
  final String title;
  final String username;
  final String password;
  final String? website;
  final String? notes;
  final String? categoryId;
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

---

# 14. LoginItem Security

The following fields are sensitive:

```text
username
password
website
notes
```

They MUST be stored only inside encrypted `VaultData`.

---

# 15. BankCardItem

Represents a saved bank card.

Conceptual:

```text
BankCardItem
├── id
├── title
├── cardNumber
├── cardHolder
├── expiryDate
├── cvv
├── bankName
├── notes
├── categoryId
├── createdAt
└── updatedAt
```

The exact fields MUST match the approved Bank Card UI/feature requirements.

All card information MUST be considered sensitive.

---

# 16. Bank Card Security

Sensitive fields such as:

```text
cardNumber
cvv
cardHolder
expiryDate
```

MUST only exist inside encrypted `VaultData`.

The application MUST NOT store card information in:

* Plain Hive boxes
* SharedPreferences
* Logs
* Analytics
* Crash reports

---

# 17. SecureNoteItem

Represents a secure note.

Conceptual:

```text
SecureNoteItem
├── id
├── title
├── content
├── categoryId
├── createdAt
└── updatedAt
```

Recommended:

```dart
class SecureNoteItem {
  final String id;
  final String title;
  final String content;
  final String? categoryId;
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

The content MUST be stored inside encrypted `VaultData`.

---

# 18. CategoryItem

Represents a user-defined category.

Conceptual:

```text
CategoryItem
├── id
├── name
├── icon
└── createdAt
```

Recommended:

```dart
class CategoryItem {
  final String id;
  final String name;
  final String? icon;
  final DateTime createdAt;
}
```

Categories are part of the vault and therefore are included inside encrypted `VaultData`.

---

# 19. Item IDs

Every vault item MUST have its own unique ID.

Examples:

```text
LoginItem.id
BankCardItem.id
SecureNoteItem.id
CategoryItem.id
```

IDs MUST:

* Be unique within the relevant collection.
* Be generated independently.
* Not contain sensitive information.
* Not be derived from passwords or card numbers.

UUID v4 is recommended.

---

# 20. Timestamps

Vault items SHOULD contain:

```text
createdAt
updatedAt
```

Timestamps are useful for:

* Sorting
* UI display
* Future migration
* Backup compatibility

Timestamps MUST NOT be used as cryptographic keys.

---

# 21. Optional Values

Optional fields SHOULD use nullable types rather than magic values.

Preferred:

```dart
String?
```

Avoid:

```dart
String = ''
```

when an empty string has a different semantic meaning from "not provided".

---

# 22. Model Immutability

Models SHOULD be immutable.

Preferred:

```dart
class LoginItem {
  final String id;
  ...
}
```

When updating an item, create a new model/state rather than mutating shared state unpredictably.

---

# 23. Serialization

Models that are persisted or serialized MUST provide explicit serialization.

Conceptual:

```dart
toMap()
fromMap()
```

or an equivalent project-standard mechanism.

Serialization MUST be deterministic.

Cryptographic binary fields MUST remain binary-safe.

---

# 24. Hive Persistence

Hive persistence models/adapters MUST be separated conceptually from domain data structures when required by the storage implementation.

However, Keyva MUST NOT introduce a large DTO/entity mapping architecture.

Keep the mapping simple.

The goal is:

```text
ViewModel
 ↓
Repository
 ↓
Model
 ↓
Hive Adapter
```

not:

```text
View
 ↓
ViewModel
 ↓
UseCase
 ↓
Domain Entity
 ↓
DTO
 ↓
Mapper
 ↓
Repository
 ↓
Data Source
 ↓
Hive
```

The second structure is OUT OF SCOPE for Keyva.

---

# 25. MVVM Rule

Keyva uses MVVM.

The intended architecture is:

```text
┌───────────────┐
│      View     │
│   Flutter UI  │
└───────┬───────┘
        ↓
┌───────────────┐
│   ViewModel   │
│     GetX      │
└───────┬───────┘
        ↓
┌────────────────────┐
│ Repository/Service │
└─────────┬──────────┘
          ↓
┌────────────────────┐
│    Data Source     │
└─────────┬──────────┘
          ↓
┌────────────────────┐
│        Hive        │
└────────────────────┘
```

This is the architectural boundary for Keyva.

---

# 26. View Responsibilities

Views MUST:

* Render UI.
* Observe ViewModel state.
* Send user actions to ViewModels.
* Display loading/error/success states.

Views MUST NOT:

* Access Hive.
* Encrypt/decrypt data.
* Generate Vault Keys.
* Perform authentication.
* Modify repositories directly.

---

# 27. ViewModel Responsibilities

ViewModels MUST:

* Manage UI state.
* Validate UI input.
* Call repositories/services.
* Expose observable state to Views.
* Coordinate user actions.

ViewModels MUST NOT:

* Implement AES.
* Implement Argon2id.
* Directly access Hive boxes.
* Store long-lived cryptographic secrets.

---

# 28. Repository Responsibilities

Repositories coordinate application data operations.

Examples:

```text
AuthRepository
VaultRepository
BackupRepository
SettingsRepository
```

Repositories MAY coordinate:

* Local data source
* Crypto service
* Session service
* Model conversion

Repositories MUST NOT contain widget/UI logic.

---

# 29. Service Responsibilities

Dedicated services handle cross-cutting technical concerns.

Examples:

```text
CryptoService
SessionService
BiometricService
PinService
```

Services MUST have focused responsibilities.

Do not create one large `KeyvaService` containing the entire application.

---

# 30. Data Source Responsibilities

The local data source handles:

* Hive initialization
* Box access
* Reading records
* Writing records
* Updating records
* Deleting records

The data source MUST NOT:

* Navigate UI.
* Manage GetX state.
* Implement cryptographic algorithms.

---

# 31. Model Ownership

Models belong to the feature/data layer required by the MVVM implementation.

Do not create a separate Domain Entity layer only for architectural purity.

The project should favor:

```text
Simple
Explicit
Maintainable
```

over unnecessary abstraction.

---

# 32. Future Feature Data

When a future Keyva feature introduces new data:

1. Determine whether it is sensitive.
2. If sensitive, add it to `VaultData`.
3. Define a dedicated model.
4. Add serialization.
5. Update vault format if required.
6. Ensure the data remains encrypted at rest.

Do not create a new plaintext storage mechanism for convenience.

---

# 33. Model Versioning

VaultData MUST have a format version.

Example:

```text
VaultData
├── version
├── logins
├── bankCards
├── secureNotes
└── categories
```

The version allows future migration of the decrypted vault structure.

---

# 34. Backup Models

Backup models MUST be separate from Hive's internal records.

Conceptual:

```text
BackupModel
├── backupVersion
├── exportedAt
├── user
└── vault
```

The backup model is defined in:

`06_backup_and_restore.md`

---

# 35. Data Integrity

Before persisting a model:

* Required fields MUST be valid.
* IDs MUST be valid.
* Lists MUST not contain invalid entries.
* Version numbers MUST be supported.

Invalid models MUST NOT be persisted.

---

# 36. Sensitive Model Rule

Any newly introduced model MUST be classified as one of:

```text
Non-sensitive metadata
Sensitive vault data
Security credential material
```

Security credential material MUST NOT be placed inside normal vault models.

---

# 37. Forbidden Model Design

Cursor MUST NOT:

* Store Master Password in any model.
* Store plaintext Vault Key in any persistent model.
* Store plaintext PIN in any model.
* Store decrypted vault data in persistent storage models.
* Create separate plaintext Hive models for Login, BankCard, or SecureNote.
* Put GetX controllers inside models.
* Put navigation logic inside models.
* Put cryptographic operations inside models.

---

# 38. Final Model Relationship

```text
UserRecord
    │
    └──────────────┐
                   │
                   ▼
              VaultRecord
                   │
                   │ decrypt
                   ▼
               VaultData
                   │
        ┌──────────┼──────────┐
        ▼          ▼          ▼
      Login     BankCard    SecureNote
        │
        └──────────────┐
                       ▼
                    Category
```

---

# 39. Implementation Rule

Cursor MUST implement only the models required by the current Keyva feature set.

Do NOT introduce unnecessary models or abstractions.

The model layer MUST remain simple and compatible with the existing MVVM + GetX architecture.

If a new feature requires a structural change to the vault model, update the relevant documentation before implementing it.
