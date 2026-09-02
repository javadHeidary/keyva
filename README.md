
<div align="center">

# 🔐 Keyva (کیوا)
### Privacy-First, Offline Password & Secure Information Vault

[![Flutter](https://img.shields.io/badge/Flutter-%E2%89%A5%203.32.0-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-%E2%89%A5%203.8.1-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Security](https://img.shields.io/badge/Security-AES--256--GCM%20%7C%20Argon2id-critical?style=for-the-badge)](https://en.wikipedia.org/wiki/Argon2)
[![Architecture](https://img.shields.io/badge/Architecture-MVVM%20%2B%20Repository-blue?style=for-the-badge)]()
[![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)](LICENSE)

<p align="center">
  A local-only, zero-knowledge offline vault designed for Android users to store credentials, banking details, secure notes, and encrypted media without cloud dependency.
</p>

</div>

---

## 📌 Overview

**Keyva** is an offline-first, highly secure information vault designed with a strict zero-knowledge architecture. All sensitive data—including passwords, bank cards, personal notes, and private images—is encrypted on-device before storage.

Keyva eliminates cloud vulnerabilities by having **no remote backend, no mandatory accounts, and no sync servers**. Network connectivity is purely optional for cosmetic enhancements (e.g., website favicons and store links).

---

## 📱 Screenshots

<div align="center">

| Home | Categories | Password Generator |
| :---: | :---: | :---: |
| <img src="assets/images/main.jpg" width="240" alt="Home Screen"/> | <img src="assets/images/category.jpg" width="240" alt="Categories Screen"/> | <img src="assets/images/gen_password.jpg" width="240" alt="Password Generator"/> |

| Settings | Dark Theme | Backup & Restore |
| :---: | :---: | :---: |
| <img src="assets/images/settings.jpg" width="240" alt="Settings Screen"/> | <img src="assets/images/theme.jpg" width="240" alt="Dark Theme"/> | <img src="assets/images/backup.jpg" width="240" alt="Backup & Restore"/> |

</div>

---

## ✨ Key Features

- **Multi-Type Encrypted Vault:** Store and manage logins, bank cards, secure text notes, and image folders.
- **Biometric & PIN Fast-Unlock:** Seamless hardware-backed authentication (Fingerprint/Face Unlock) and PIN support alongside Master Password verification.
- **Encrypted Media Storage:** Sidecar image storage under app-private directories with AES-GCM encryption.
- **Smart Password Generator:** Configurable entropy, strength analysis, and a 7-day ephemeral local copy history.
- **Granular Security Controls:** Screenshot prevention (`FLAG_SECURE`), auto-lock on app backgrounding, privacy screen overlay, and lockout after 3 failed attempts.
- **Iranian Banking Support:** Built-in card prefix detection and metadata resolution.
- **Encrypted Backups:** Export and import password-protected `.keyva` archives independent of device credentials.
- **Localization & Theming:** Full RTL (Persian) support, Jalali dates, customizable system/light/dark themes, and onboarding flows.

---

## 🛡 Security & Cryptographic Architecture

Keyva strictly decouples **user authentication** from **underlying cryptographic operations**.

```text
[Random Vault Key (32 bytes)] <--- Wrapped by AES-256-GCM
      ↓ (Held in volatile RAM during active session)
[Encrypted Payload (AES-256-GCM)] <---> Hive CE & Local Blobs
```

### 1[Encrypted Payload (AES-256-GCM)] <---> Hive CE & Local Blobs


### 1. Key Derivation & Vault Key Wrapping
- **Argon2id Parameters:** 64 MiB memory, 3 iterations, parallelism 4, 32-byte derived output with a per-account cryptographically secure salt.
- **Zero-Knowledge Master Password:** The Master Password is never written to disk (neither plaintext nor hash).
- **Key Wrapping Strategy:** A random 32-byte Vault Key encrypts the payload. Changing the Master Password only re-wraps this Vault Key without needing to re-encrypt the entire database.

### 2. Encryption at Rest
- **Data Payload:** Vault JSON objects are encrypted with **AES-256-GCM** (12-byte unique nonces, 16-byte authentication tags) and stored in **Hive CE**.
- **Media Blobs:** Raw image bytes are encrypted with the active session key and saved under isolated app directories (`vault_blobs/`).

### 3. Session & In-Memory Safety
- The decrypted Vault Key lives exclusively in memory during an active session and is zeroed on lock or logout.
- Biometric unlock stores an independent wrap key inside Android Keystore via `flutter_secure_storage`.
- Strict fail-closed policy on cryptographic or authentication anomalies.

---

## 🛠 Tech Stack & Architecture

### **Core Stack**
| Layer | Technology | Purpose |
| :--- | :--- | :--- |
| **Framework** | Flutter (≥ 3.32.0) / Dart (≥ 3.8.1) | Cross-platform core |
| **Architecture** | MVVM + Repository Pattern | Clean separation of business logic and presentation |
| **State & Routing** | GetX | ViewModels, lifecycle, and route navigation |
| **Dependency Injection** | GetIt | Long-lived services and singleton registrations |
| **Local Database** | Hive CE | Encrypted box storage |
| **Cryptography** | `cryptography` package | Argon2id & AES-256-GCM primitives |
| **Secure Key Store** | `flutter_secure_storage` | Platform hardware keystore wrapper |
| **Biometrics** | `local_auth` | OS-level biometric verification |

### **Architecture Flow**
```text
View (GetX UI)
    ↓
ViewModel (GetX Controller)
    ↓
Service / Security Manager
    ↓
Repository Layer (Result<T> Pattern)
    ↓
Local Data Sources (Hive CE / Secure Storage / Encrypted Files)
```

---

## 📁 Project Structure

```text
lib/
├── core/
│   ├── crypto/          # Argon2id, AES-GCM primitives & key-wrapping
│   ├── database/        # Hive CE boxes, adapters & migrations
│   ├── di/              # GetIt dependency injection registry
│   ├── exceptions/      # Result<T> failure handling & custom exceptions
│   ├── routes/          # GetX routing & session-guard middleware
│   ├── security/        # PIN, biometric auth, lockout policies & FLAG_SECURE
│   ├── session/         # Memory-only session state & auto-lock timer
│   ├── store/           # Bazaar / Myket platform channels
│   └── theme/           # Design tokens, typography & color schemes
├── feature/
│   ├── auth/            # Master password & enrollment flows
│   ├── backup/          # .keyva archive export/import
│   ├── category/        # Vault organization & tags
│   ├── home/            # Dashboard & pinned entries
│   ├── password_generator/ # Entropy calculation & temporary history
│   ├── settings/        # Security preferences & theme selection
│   ├── type/            # Form handlers for login, card, note, media
│   └── vault/           # Item CRUD & secure blob pipeline
├── shared/              # Reusable UI components & custom widgets
└── main.dart            # App entry point
```

---

## 🚀 Getting Started

### Prerequisites
- **Flutter SDK:** `≥ 3.32.0`
- **Dart SDK:** `≥ 3.8.1`
- Android Studio / Android SDK (API Level 23+ recommended)

### Installation & Setup

1. **Clone the repository:**
   ```bash
   git clone https://github.com/javadHeidary/keyva.git
   cd keyva
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **(Optional) Code Generation:**
   If you modify database models, regenerate Hive type adapters:
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

### Running with Flavors

Keyva supports build flavors configured for distribution channels:

- **Bazaar (Default):**
  ```bash
  flutter run --flavor bazaar --dart-define=STORE=bazaar
  ```

- **Myket:**
  ```bash
  flutter run --flavor myket --dart-define=STORE=myket
  ```

---

## 🧪 Testing

The test suite covers unit and widget tests for cryptographic verification, key wrapping, repository operations, and state transitions.

Run the test suite:
```bash
flutter test
```

---

## 👤 Author & Contact

**Javad Heidary** — Mobile Application Developer (Flutter & Android)

- ✉️ **Email:** [javadheidary.dev@gmail.com](mailto:javadheidary.dev@gmail.com)
- 💬 **Telegram:** [@JavadHeiDev](https://t.me/JavadHeiDev)
- 🌐 **GitHub:** [@javadHeidary](https://github.com/javadHeidary)

---

<div align="center">
  <sub>Built with precision and security in mind by Javad Heidary</sub>
</div>
```
