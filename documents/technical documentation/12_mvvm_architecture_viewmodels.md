# MVVM Architecture & ViewModels

## 1. Overview

Keyva uses MVVM with GetX for UI state and navigation. ViewModels (`GetxController`) call repositories and services. They do not open Hive boxes. There is no Domain, UseCase, or Interactor layer. GetIt supplies long-lived services; GetX `Bindings` construct ViewModels per route.

## 2. Purpose

Keep Flutter widgets free of crypto and persistence details, keep a single DI graph for security types, and use reactive `.obs` fields for screens.

## 3. Architecture

```text
View (GetView / widgets)
    ↓
ViewModel (GetxController)
    ↓
Service (VaultUnlockService, VaultOperationService, BackupService, PinService, …)
    ↓
Repository (AuthRepository, VaultRepository, SettingsRepository)
    ↓
DataSource (HiveUserDataSource, HiveVaultDataSource)
    ↓
Hive / secure storage / blob files
```

| Layer | Present? |
| --- | --- |
| Presentation | Yes |
| ViewModel | Yes |
| Domain / UseCase | **No** |
| Repository | Yes |
| Data Source | Yes |
| Services (application + core) | Yes |
| Core / Security / Crypto / Session | Yes |
| Local Storage | Yes |

Navigation (`Get.toNamed`, `Get.offAllNamed`) occurs in ViewModels and middleware, not in repositories.

## 4. Implementation Flow

Typical vault mutation:

```text
User taps save on LoginCreateView
    ↓
LoginCreateViewModel.submit
    ↓
VaultItemViewModel.create
    ↓
VaultOperationService.addItem
    ↓
VaultDataService.addLogin → serialize → VaultRepository.saveVaultData
    ↓
status = success; navigate to details
```

Typical unlock:

```text
AuthLoginView
    ↓
LoginController.login
    ↓
VaultUnlockService.unlock
    ↓
AuthRepository.authenticate
    ↓
Get.offAllNamed(shell)
```

`HomeController` loads list data through `VaultHomeViewModel.loadVault()` → `VaultOperationService.getVault()` → in-memory `VaultSession`.

## 5. Important Classes & Files

**ViewModels (representative)**

| Class | Path | Role |
| --- | --- | --- |
| `AuthStartupViewModel` | `lib/feature/auth/widget/view_model/auth_startup_viewmodel.dart` | Initial route |
| `AccountSelectionViewModel` | `.../account_selection_viewmodel.dart` | Account list |
| `RegisterController` | `.../auth_register_viewmodel.dart` | Create + unlock |
| `LoginController` | `.../auth_login_viewmodel.dart` | Unlock methods |
| `HomeController` | `lib/feature/home/viewmodel/home_viewmodel.dart` | Home shell, guides, FAB |
| `VaultHomeViewModel` | `lib/feature/vault/viewmodel/vault_home_viewmodel.dart` | List/search/pin/delete |
| `VaultItemViewModel` | `lib/feature/vault/viewmodel/vault_item_viewmodel.dart` | Create/update items |
| `LoginCreateViewModel` / form/details | `lib/feature/type/login/viewmodel/` | Login CRUD UI |
| Bank card / note / image ViewModels | `lib/feature/type/.../viewmodel/` | Type-specific forms |
| `SettingsViewModel` | `lib/feature/settings/viewmodel/settings_viewmodel.dart` | Settings + security |
| `BackupViewModel` / `RestoreViewModel` | `lib/feature/backup/viewmodel/` | Backup/restore |
| `PasswordGeneratorViewModel` | `lib/feature/password_generator/viewmodel/` | Generator |
| `MainShellController` | `lib/feature/shell/viewmodel/main_shell_viewmodel.dart` | Tabs |
| `AppLockController` | `lib/core/session/app_lock_controller.dart` | Lifecycle lock (controller, not a screen VM) |

**Bindings:** `lib/feature/**/bindings/*.dart` plus `lib/core/routes/app_routing.dart`.

**UI status:** `VaultUiStatus` (`initial`, `loading`, `loaded`, `empty`, `error`, `submitting`, `success`).

**Naming:** Some ViewModels are named `*Controller` (`LoginController`, `HomeController`, `RegisterController`) but still act as GetX ViewModels.

## 6. Data Flow

Views bind to `.obs` / `Obx`. ViewModels hold form controllers and map `Result` to `errorMessage` / toasts.

Decrypted `VaultData` is not copied into every ViewModel; `VaultHomeViewModel` holds `Rxn<VaultData>` after `getVault()`. Forms build item models and pass them to `VaultItemViewModel`.

`HomeController` may call `getIt` for `VaultUnlockService` / `AuthRepository` when not constructor-injected (production `HomeBindings` does inject auth/unlock/session).

## 7. Security Considerations

- ViewModels receive secrets from text fields and pass them into services; they should not log them. Password fields are cleared in `finally` on register/login.
- ViewModels do not persist Hive records themselves.
- `SessionGuard` blocks vault routes when `SessionService.isAuthenticated` is false.

## 8. Error Handling

Pattern: `if (result is FailureResult) { errorMessage / AppToast; return; }`.

Shared mapper: `vaultUserMessage`. Some screens keep English `failure.message` until the view wraps it (`HomeController.vaultErrorMessage`).

`VaultItemViewModel` sets `VaultUiStatus.error` and `errorMessage` on validation or repository failure.

## 9. Edge Cases

- **In-memory type stores:** `LoginVaultStore`, `BankCardVaultStore`, and `NoteVaultStore` are still `Get.put` in Home/Login/BankCard/Note bindings. They seed sample items in `onInit`. No other production type uses `Get.find<LoginVaultStore>()` (or the bank/note equivalents). Login/bank/note **forms** persist through `VaultItemViewModel`. These stores are leftover registrations, not the encrypted vault source of truth.
- Auth Bindings use `Get.put(..., permanent: true)` to avoid SmartManagement disposing controllers after `offAllNamed`.
- `VaultHomeViewModel` is a GetIt **factory** resolved into GetX `lazyPut`.
- `global_bindigns.dart` is empty.

## 10. Testing

ViewModel and widget tests include (non-exhaustive):

- `test/feature/auth/account_selection_viewmodel_test.dart`
- `test/feature/auth/auth_startup_viewmodel_test.dart`
- `test/feature/vault/vault_home_viewmodel_test.dart`
- `test/feature/vault/vault_item_viewmodel_test.dart`
- `test/feature/home/item_type_guide_viewmodel_test.dart`
- `test/feature/settings/settings_viewmodel_theme_test.dart`
- `test/feature/onboarding/onboarding_viewmodel_test.dart`
- Corresponding `*_view_test.dart` files under `test/feature/`

## 11. Technical Decisions

- MVVM + GetX as required by project rules, not Clean Architecture.
- Services fill the gap where a UseCase would sit (unlock, operations, backup).
- Constructor injection of interfaces; Bindings are the composition root for UI.
- Feature folders (`feature/auth`, `feature/vault`, `feature/type/...`) instead of a `domain/` tree.

## 12. Limitations / Notes

- Mixed naming (`Controller` vs `ViewModel`).
- Some ViewModels (`HomeController`) still resolve GetIt as a fallback.
- Leftover `*VaultStore` GetxServices with sample plaintext items remain registered.
- `SettingsRepository` is only partially implemented; settings ViewModel bypasses stubs for security.

## 13. Summary

Screens talk to GetX ViewModels. ViewModels call services and repositories registered in GetIt. Hive and crypto stay behind data sources and `CryptoService`. There is no UseCase layer. Route Bindings create ViewModels; `SessionGuard` protects vault pages.

Related: [GetIt](11_dependency_injection_getit.md), [Error Handling](15_error_handling_result_pattern.md), [Vault Lifecycle](17_vault_process_lifecycle.md).
