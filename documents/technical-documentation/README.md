# Keyva Technical Documentation

This directory describes how Keyva is implemented in the current codebase. The source of truth is `lib/` and `test/`, not product plans or the older notes under `documents/architecture/` and `documents/implementation/`.

There is no Domain / UseCase / Interactor layer. The runtime path is:

```text
View (GetX)
  → ViewModel
    → Service (when present)
      → Repository
        → DataSource
          → Hive CE / flutter_secure_storage / EncryptedBlobStore files
```

## Documents

1. [Master Password & Account Lifecycle](01_master_password_account_lifecycle.md)
2. [Argon2id Key Derivation](02_argon2id_key_derivation.md)
3. [Vault Encryption & AES-GCM](03_vault_encryption_aes_gcm.md)
4. [Vault Key Management](04_vault_key_management.md)
5. [Authentication & Session Lifecycle](05_authentication_session_lifecycle.md)
6. [PIN Authentication & Lockout](06_pin_authentication_lockout.md)
7. [Biometric Authentication](07_biometric_authentication.md)
8. [Auto Lock](08_auto_lock.md)
9. [Secure Backup & Restore (`.keyva`)](09_secure_backup_restore.md)
10. [Hive CE Local Storage](10_hive_ce_local_storage.md)
11. [Dependency Injection with GetIt](11_dependency_injection_getit.md)
12. [MVVM Architecture & ViewModels](12_mvvm_architecture_viewmodels.md)
13. [Password Strength Analyzer](13_password_strength_analyzer.md)
14. [Multi-Account Management](14_multi_account_management.md)
15. [Error Handling & Result Pattern](15_error_handling_result_pattern.md)
16. [Security Settings & Master Password Change](16_security_settings_master_password_change.md)
17. [Vault Process / Vault Lifecycle](17_vault_process_lifecycle.md)

Document 17 is the end-to-end synthesis of vault creation, unlock, session, CRUD, lock, and persistence.
