# Dependency Injection with GetIt

## 1. Overview

Keyva registers long-lived infrastructure (database, crypto, session, repositories, vault services) in a single GetIt container. GetX `Bindings` then construct ViewModels by resolving those dependencies from GetIt. `lib/core/di/global_bindigns.dart` exists but is empty.

## 2. Purpose

A single registration file keeps construction of security-sensitive services in one place, avoids `new Repository()` inside ViewModels, and lets tests substitute fakes at the GetIt or constructor-injection boundary.

## 3. Architecture

| Layer | Role |
| --- | --- |
| Presentation | GetX routes attach `Bindings` |
| ViewModel | Constructed by Bindings; receives interfaces via constructor |
| Service / Repository / DataSource | Registered in GetIt as lazy singletons |
| Core / Security / Session / Crypto | Registered in GetIt |
| Local Storage | `HiveDatabase` is created in `main()` and passed into `initDependencies` |
| Domain | Not present |

GetIt is the application DI container. GetX is used for navigation, reactive ViewModels, and route-scoped controller lifecycle — not as the service locator for crypto or Hive.

## 4. Implementation Flow

```text
main()
    ↓
HiveDatabase.initialize()
    ↓
initDependencies(database)     // lib/core/di/injection_container.dart
    ↓
ScreenProtectionService.applyPersisted()
    ↓
Get.put(AppLockController(...), permanent: true)
    ↓
runApp(KeyvaApp)
    ↓
GetMaterialApp getPages + Bindings
    ↓
Bindings resolve getIt<T>() and Get.put / Get.lazyPut ViewModels
```

`initDependencies` lives in `lib/core/di/injection_container.dart` and is the only registration function for GetIt.

## 5. Important Classes & Files

| Class / File | Responsibility | Relationship |
| --- | --- | --- |
| `getIt` / `initDependencies` — `lib/core/di/injection_container.dart` | Global `GetIt.instance`; all service registrations | Called once from `main.dart` |
| `main.dart` | Initializes Hive, GetIt, screen protection, `AppLockController` | Owns process startup |
| `global_bindigns.dart` — `lib/core/di/global_bindigns.dart` | Empty file | Not used |
| Feature `Bindings` (e.g. `UnlockBindings`, `SettingsBindings`, `SplashBindings`) | Create ViewModels with `getIt<...>()` | Attached to `GetPage` in `app_routing.dart` |

Registration styles in `initDependencies`:

- `registerSingleton<HiveDatabase>(database)` — the already-opened database.
- `registerLazySingleton<T>(...)` — most services, data sources, repositories (`CryptoService`, `KeyManagementService`, `SessionService`, `AuthRepository`, `VaultRepository`, `VaultUnlockService`, `PinService`, `BiometricService`, `BackupService`, …).
- `registerFactory<VaultHomeViewModel>` / `VaultItemViewModel` / `BackupViewModel` / `RestoreViewModel` — new instance per `getIt` resolve.

`AppLockController` is **not** registered in GetIt. `main()` puts it into GetX with `permanent: true`.

Auth Bindings (`lib/feature/auth/bindings/auth_bindings.dart`) use a local `_replace` helper: if the controller type is already registered, it is force-deleted, then `Get.put(..., permanent: true)` so `offAllNamed` does not dispose the controller during keyboard rebuilds.

`SettingsBindings` and `SplashBindings` use `Get.lazyPut`.

`MainShellBindings` composes Home, Password Generator, Category, and Settings bindings plus `MainShellController`.

## 6. Data Flow

```text
HiveDatabase instance
    ↓
GetIt singletons close over getIt<HiveDatabase>() / getIt<CryptoService>() / …
    ↓
ViewModel constructor parameters (interfaces)
    ↓
Runtime calls
```

ViewModels do not read Hive or GetIt internally for repositories in the Bindings that were inspected; they receive `AuthRepository`, `VaultUnlockService`, `PinService`, and similar interfaces.

`VaultHomeViewModel` and `VaultItemViewModel` can also be resolved from GetIt factories (used by vault screens / tests), while many other ViewModels exist only in GetX.

## 7. Security Considerations

- Crypto, key management, session, PIN, biometric, and vault unlock are constructed once as lazy singletons, so the in-memory Vault Key lives in the same `SessionServiceImpl` instance for the process.
- Bindings pass interfaces, not concrete crypto types, into ViewModels.
- There is no runtime rebinding of `CryptoService` after startup in production `main()`.

## 8. Error Handling

DI itself does not return `Result`. A missing GetIt registration would throw at resolve time (`getIt<T>()`). `SessionGuard` checks `getIt.isRegistered<SessionService>()` before reading `isAuthenticated`.

Startup failures from `HiveDatabase.initialize()` throw `AppFailure` and prevent `initDependencies` from running.

## 9. Edge Cases

- `global_bindigns.dart` filename is misspelled (`bindigns`) and the file is empty.
- Auth controllers are `permanent: true` to survive GetX `SmartManagement` after `offAllNamed`.
- `AppLockController` is GetX-permanent, independent of GetIt.
- `BackupServiceImpl` accepts optional `AuthRepository` / `VaultUnlockService` / data sources; production registration supplies them.

## 10. Testing

No dedicated automated test was found for this feature.

Tests construct services with constructors and fakes (for example `test/feature/auth/support/fake_auth_repository.dart`) rather than asserting on `initDependencies`.

## 11. Technical Decisions

- GetIt for infrastructure, GetX for UI controllers — matches the project rule “one central GetIt file”.
- Lazy singletons for security services so wrap/unwrap and session state share one object graph.
- Factories for a few ViewModels that should not be process-wide singletons.
- Constructor injection into ViewModels; Bindings are the only place that calls `getIt` for those types.

## 12. Limitations / Notes

- Project rules require a single GetIt registration file; that is `injection_container.dart`. Bindings still exist per feature for GetX.
- Some ViewModels (category list, main shell) are created in Bindings without GetIt factories.
- Replacing a singleton in tests requires either not calling `initDependencies` or resetting GetIt; production code never resets the container.

## 13. Summary

GetIt holds the Hive database, crypto, session, repositories, and vault/backup/PIN/biometric services. `initDependencies` is the single registration function. GetX Bindings build ViewModels from those registrations. `global_bindigns.dart` is unused. `AppLockController` is registered in GetX from `main()`, not GetIt.

Related: [MVVM](12_mvvm_architecture_viewmodels.md), [Hive CE](10_hive_ce_local_storage.md), [Vault Lifecycle](17_vault_process_lifecycle.md).
