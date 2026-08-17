# Keyva Implementation Rules

## Purpose

This document defines **how** the approved Keyva architecture must be implemented in Flutter.


All previous architecture documents define **what** Keyva must do.  

This document is mandatory for implementation.


Cursor MUST follow these rules unless explicitly instructed otherwise.

---
  
# 1. Core Architecture

  

Keyva uses:

  

- Flutter + Dart

- **MVVM**

- **GetX** for state management

- **GetIt** for dependency injection

- **Hive CE** for local database

- Repository pattern

- Service abstraction

- Data Source abstraction

  

### Forbidden

  

Keyva MUST NOT be converted into Clean Architecture.

  

Do NOT introduce:

  

- Domain layer

- UseCase / Interactor layer

- Entity / DTO / Mapper architecture

- Excessive abstraction layers

  

unless explicitly requested.

  

---

  

# 2. High-Level Architecture

  

```text

View

  ↓

ViewModel (GetX)

  ↓

Repository / Service (Interface)

  ↓

Implementation

  ↓

DataSource (Interface)

  ↓

Hive CE Implementation

  ↓

Hive CE

```

  

Dependency Injection is handled exclusively by **GetIt**.

  

---

  

# 3. MVVM Responsibilities

  

### View

- Renders UI

- Observes ViewModel state

- Sends user actions to ViewModel

- Displays loading / error / success states

  

**View MUST NOT:**

- Access Hive

- Access repositories directly

- Perform encryption or authentication

- Manage database operations

  

### ViewModel

- Manages UI state

- Validates input

- Calls repositories / services

- Updates observable state

- Coordinates feature workflows

  

**ViewModel MUST NOT:**

- Access Hive directly

- Instantiate repositories or services

- Implement cryptographic algorithms

- Perform long-lived storage of secrets

  

ViewModels receive dependencies **only through constructor injection**.

  

---

  

# 4. Repository Pattern

  

Every repository MUST expose an abstraction.

  


abstract interface class AuthRepository {

  Future<Result<UserRecord>> createAccount(...);

  Future<Result<UserRecord>> authenticate(...);

  Future<Result<void>> logout();

}

```

  

Implementation example:

  

```dart

class AuthRepositoryImpl implements AuthRepository {

  final AuthDataSource _dataSource;

  final CryptoService _cryptoService;

  

  AuthRepositoryImpl(this._dataSource, this._cryptoService);

}

```

  

### Repository MAY

- Coordinate DataSources and Services

- Perform application-level data operations

- Convert persistence data into models

- Handle repository-level errors

  

### Repository MUST NOT

- Contain UI logic

- Navigate pages

- Modify GetX UI state

- Directly manipulate widgets

  

---

  

# 5. Service Pattern

  

Technical responsibilities MUST be isolated into focused services.

  

Examples:

  

```text

CryptoService

SessionService

BiometricService

PinService

ClipboardService

AppSecurityService

SecureStorageService

```

  

Do **not** create a giant `KeyvaService`.

  

Services that are application boundaries MUST also use abstractions.

  

---

  

# 6. Data Source Pattern

  

Persistent storage MUST be accessed only through DataSources.

  

```text

Repository

   ↓

DataSource (Interface)

   ↓

HiveXxxDataSource

   ↓

Hive CE

```

  

Only the DataSource / database layer may directly depend on Hive APIs.

  

---

  

# 7. Dependency Injection (GetIt)

  

- There is **one central DI file**:

  ```text

  lib/core/di/injection_container.dart

  ```

- All registrations happen inside a single `initDependencies()` method.

- `main()` must call `initDependencies()` before `runApp()`.

  

### Registration Order

  

```text

Database

  ↓

DataSources

  ↓

Services

  ↓

Repositories

```

  

### Constructor Injection Rule

  

```dart

// Correct

class VaultRepositoryImpl implements VaultRepository {

  final VaultDataSource _dataSource;

  final CryptoService _cryptoService;

  

  VaultRepositoryImpl(this._dataSource, this._cryptoService);

}

  

// Forbidden

class VaultRepositoryImpl {

  final _crypto = GetIt.I<CryptoService>();

}

```

  

Implementations MUST NOT access GetIt directly.  

GetIt belongs only to the composition root.

  

---

  

# 8. GetX vs GetIt

  

| Tool   | Responsibility                          |

|--------|-----------------------------------------|

| GetX   | Reactive state, Controllers, Navigation, UI lifecycle |

| GetIt  | Dependency Injection (Repositories, Services, DataSources) |

  

Do not use GetX as the primary DI system.

  

---

  

# 9. Result & Failure Contract

  

All repository (and applicable service) operations that can fail MUST return `Result<T>`.

  

```dart

sealed class Result<T> {

  const Result();

}

  

final class Success<T> extends Result<T> {

  final T data;

  const Success(this.data);

}

  

final class FailureResult<T> extends Result<T> {

  final AppFailure failure;

  const FailureResult(this.failure);

}

```

  

### AppFailure

  

All application-level failures derive from a common `AppFailure`.

  

Recommended types (create only what is needed):

  

```text

ValidationFailure

AuthenticationFailure

DatabaseFailure

CryptoFailure

VaultDecryptionFailure

BackupFailure

RestoreFailure

SecurityFailure

SessionFailure

NotFoundFailure

UnknownFailure

```

  

### Failure Mapping Flow

  

```text

HiveException / CryptoException / PlatformException

          ↓

DataSource or Service

          ↓

AppFailure

          ↓

FailureResult<T>

          ↓

ViewModel

          ↓

UI-friendly error state

```

  

- UI MUST NOT receive raw technical exceptions.

- Security-sensitive failures MUST use generic user-facing messages.

- Do not nest `Result<Result<T>>`.

- Expected failures (wrong password, invalid backup, etc.) SHOULD be returned as `FailureResult`, not thrown.

  

---

  

# 10. Session Management

  

Session state MUST be centralized in a `SessionService`.

  

It manages:

  

- Active User ID

- Active Vault Key (in memory only)

- Active decrypted VaultData

- Lock / Unlock state

  

Sensitive session data MUST be released on Lock / Logout / Account Switch.

  

---

  

# 11. Cryptography Boundary

  

Cryptographic operations MUST be centralized in `CryptoService`.

  

ViewModels and Repositories MUST NOT directly call:

  

- Argon2id

- AES-GCM

- Key Wrapping / Unwrapping

- Secure Random Generation

  

```text

ViewModel → Repository → CryptoService

```

  

---

  

# 12. Security Boundary

  

Platform-specific security operations MUST be isolated:

  

```text

BiometricService

PinService

SecureStorageService

AppSecurityService

ClipboardService

```

  

Platform code MUST NOT leak into ViewModels.

  

---

  

# 13. Models

  

Models represent data only.

  

Models MUST NOT:

  

- Navigate

- Access GetX

- Access repositories

- Perform encryption

- Contain UI logic

  

Models SHOULD be immutable.

  

---

  

# 14. Hive Rules

  

- Only DataSources may talk to Hive.

- Hive adapters must be registered during database initialization.

- Sensitive vault data MUST be stored only as encrypted `VaultRecord`.

- Never create plaintext boxes for passwords, cards, or notes.

  

---

  

# 15. Database Initialization Order

  

```text

WidgetsFlutterBinding.ensureInitialized()

        ↓

Hive CE initialization + adapters

        ↓

Open required boxes

        ↓

initDependencies()

        ↓

runApp()

```

  

---

  

# 16. Feature Organization

  

```text

features/

├── auth/

├── vault/

├── bank_card/

├── secure_note/

├── password_generator/

├── categories/

├── settings/

└── backup/

```

  

Cross-feature infrastructure belongs in `core/`:

  

```text

core/

├── crypto/

├── database/

├── di/

├── errors/

├── security/

├── session/

├── theme/

└── utils/

```

  

---

  

# 17. Naming Conventions

  

| Type              | Example                     |

|-------------------|-----------------------------|

| Interface         | `AuthRepository`            |

| Implementation    | `AuthRepositoryImpl`        |

| DataSource        | `HiveVaultDataSource`       |

| Service           | `CryptoService` / `CryptoServiceImpl` |

| ViewModel         | `LoginViewModel`            |

| View              | `LoginView`                 |

  

Avoid generic names: `Helper`, `Manager`, `Utils`, `AppManager`, `DataManager`.

  

---

  

# 18. Implementation Order (Mandatory)

  

### Phase 1 — Infrastructure

- Database + Hive CE

- Models + Adapters

- DI

- Result / AppFailure

  

### Phase 2 — Security Core

- CryptoService

- Key management

- SessionService

- SecureStorageService

  

### Phase 3 — Authentication

- Account creation

- Login / Unlock

- Lock / Logout

- Account switching

  

### Phase 4 — Vault

- Vault repository

- Login items

- Bank cards

- Secure notes

- Categories

  

### Phase 5 — Security Settings

- Master Password change

- PIN

- Biometric

- Auto-lock

- Screenshot protection

  

### Phase 6 — Backup

- Backup

- Restore

- Validation

  

### Phase 7 — Hardening

- Clipboard auto-clear

- Logging policy

- Background protection

- Platform security

  

---

  

# 19. Non-Negotiable Rules

  

1. MVVM is the primary architecture.

2. GetX = state management, GetIt = dependency injection.

3. One central DI file only.

4. `main()` initializes dependencies before `runApp()`.

5. Repositories, Services, and DataSources use abstractions.

6. ViewModels MUST NOT access Hive or instantiate dependencies.

7. Repositories MUST NOT navigate.

8. Cryptographic operations MUST be centralized.

9. Sensitive data MUST NEVER be logged.

10. Plaintext vault data MUST NEVER be persisted.

11. Master Password MUST NEVER be persisted.

12. Vault Key MUST NEVER be persisted in plaintext.

13. PIN / Biometric credentials are device-specific.

14. Backup MUST preserve the encrypted vault architecture.

15. Security-sensitive operations MUST fail closed.

16. Do NOT introduce Clean Architecture layers.

17. Do NOT perform unrelated refactoring.

18. Existing UI and Design System MUST be preserved.

19. When documentation conflicts with implementation needs → **STOP and ask**.

  

---

  

# 20. Final Principle

  

Keyva implementation must remain:

  

```text

Secure + Simple + Testable + Maintainable + Consistent

```

  

Priority when conflicts arise:

  

1. Security

2. Correctness of architecture

3. Simplicity

4. Performance

  

```text

GetX          → Presentation / State

GetIt         → Dependency Injection

Repositories  → Application Data Operations

Services      → Technical Capabilities

DataSources   → Persistence Boundary

Hive CE       → Local Database

```