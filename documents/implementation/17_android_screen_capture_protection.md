# Task 17 — Android Screen Capture Protection

This note describes the **Android screenshot / screen-recording / Recents protection that is actually wired in the codebase**.

It is a learning reference and an implementation record. The source of truth is the Dart/Kotlin code and tests, not the architecture proposals.

Related code:

- [`android/app/src/main/kotlin/com/example/keyva/MainActivity.kt`](../../android/app/src/main/kotlin/com/example/keyva/MainActivity.kt)
- [`lib/core/security/screen_protection_gateway.dart`](../../lib/core/security/screen_protection_gateway.dart)
- [`lib/core/security/method_channel_screen_protection_gateway.dart`](../../lib/core/security/method_channel_screen_protection_gateway.dart)
- [`lib/core/security/screen_protection_service.dart`](../../lib/core/security/screen_protection_service.dart)
- [`lib/core/security/screen_protection_service_impl.dart`](../../lib/core/security/screen_protection_service_impl.dart)
- [`lib/feature/auth/repository/auth_repository_impl.dart`](../../lib/feature/auth/repository/auth_repository_impl.dart)
- [`lib/feature/settings/viewmodel/settings_viewmodel.dart`](../../lib/feature/settings/viewmodel/settings_viewmodel.dart)
- [`lib/main.dart`](../../lib/main.dart)
- [`test/core/security/screen_protection_service_test.dart`](../../test/core/security/screen_protection_service_test.dart)
- [`test/feature/settings/settings_viewmodel_screen_protection_test.dart`](../../test/feature/settings/settings_viewmodel_screen_protection_test.dart)
- [`test/feature/settings/settings_security_view_test.dart`](../../test/feature/settings/settings_security_view_test.dart)

It extends Task 13 (the Settings screenshot row was a visual prototype). It does **not** change Vault encryption, Vault Key, Master Password, PIN, biometric wrapping, backup/restore, `SessionService`, `VaultData`, or `VaultRepository`.

---

## Android-only scope

Keyva currently ships for Android. This feature uses Android `WindowManager.LayoutParams.FLAG_SECURE` on `MainActivity`.

There is:

- no iOS code
- no iOS screen-protection API
- no new pubspec package (`flutter_windowmanager`, `screen_protector`, etc.)

Non-Android Dart hosts (`MethodChannelScreenProtectionGateway`) return success without invoking a plugin so unit tests and desktop `flutter test` do not depend on a real Activity.

---

## FLAG_SECURE implementation

[`MainActivity`](../../android/app/src/main/kotlin/com/example/keyva/MainActivity.kt) still extends `FlutterFragmentActivity` (required by `local_auth`).

On `onCreate`, **before** `super.onCreate`:

```text
window.addFlags(FLAG_SECURE)
```

That fail-closed default covers the Android launch theme and Flutter engine start, before Hive can be read.

`configureFlutterEngine` registers MethodChannel `com.example.keyva/screen_protection`:

```text
setSecure(enabled: Boolean)
  enabled true  → window.addFlags(FLAG_SECURE)
  enabled false → window.clearFlags(FLAG_SECURE)
```

The only Dart argument is `{enabled: bool}`. Failures return a generic MethodChannel error (`Unable to update screen capture protection`). Nothing sensitive is logged or sent across the channel.

`MainActivity` already lists orientation in `android:configChanges`, so rotation does not recreate the Activity. The same window keeps the current flags.

---

## Settings persistence

`SecuritySettings.preventScreenshots` already existed on Hive `UserRecord` (default `false`). Task 17 wires it.

Same path as auto-lock:

```text
SettingsView
 ↓
SettingsViewModel.setPreventScreenshot
 ↓
AuthRepository.setPreventScreenshots
 ↓
UserDataSource.update(UserRecord.securitySettings)
```

`SettingsRepository` is still unused for security settings. Changes require an authenticated session.

`SettingsViewModel.loadSecuritySettings` copies `preventScreenshots` into `SecuritySettingsUiState.preventScreenshot`.

---

## Startup behavior

```text
MainActivity.onCreate → FLAG_SECURE on
HiveDatabase.initialize
initDependencies
ScreenProtectionService.applyPersisted
runApp → SplashView
```

`applyPersisted` runs **before** `runApp`, so SplashView is not shown unprotected when the setting is on.

Resolution order (no unlock required):

1. Authenticated `SessionService.current.userId`
2. Else `HiveSettingsKeys.activeUserId`
3. Else enable if **any** stored account has `preventScreenshots == true` (fail-closed for multi-account with no active id)
4. Else `false`

If Hive lookup fails, the service **does not** call `setSecure(false)`. Native FLAG_SECURE stays on.

After a successful vault unlock, `VaultUnlockServiceImpl` calls `applyPersisted` again so a different account’s setting is applied in-process.

---

## Runtime toggle

OFF → ON and ON → OFF both:

1. Persist `AuthRepository.setPreventScreenshots`
2. Apply `ScreenProtectionService.setEnabled` (FLAG_SECURE)
3. Update UI only when both succeed

If persist fails, FLAG_SECURE is not changed and the switch stays on the previous value.

If apply fails after persist, Hive is rolled back to the previous bool, UI stays on the previous value, and Settings shows `ScreenProtectionFailure` via `vaultUserMessage`. Success is never reported when the Android flag failed.

---

## Screenshot / recording / Recents behavior

When enabled, Android `FLAG_SECURE` on the Keyva Activity window:

| Action | Typical Android behavior |
|---|---|
| Power + Volume Down | Screenshot blocked / blank |
| Screen recording | Keyva content appears black |
| Recents / Overview | Thumbnail blank/black, not a custom blur |

When disabled, `clearFlags(FLAG_SECURE)` restores normal screenshots for this window.

Lock/unlock and background/foreground stay in the same Activity, so the flag is unchanged until the setting (or another account’s persisted value) is applied again.

---

## Tests

Flutter tests use fakes. They do not take real screenshots.

| File | Scenarios |
|---|---|
| `screen_protection_service_test.dart` | default off; enable/disable; runtime follows persist; last active user; any-account fail-closed; Hive failure does not clear FLAG_SECURE; platform apply failure |
| `method_channel_screen_protection_gateway_test.dart` | non-Android no-op; channel sends only `{enabled}`; plugin error → `ScreenProtectionFailure` |
| `auth_repository_test.dart` | persist on/off for authenticated user; no session fails closed |
| `settings_viewmodel_screen_protection_test.dart` | default; enable; disable; ViewModel recreation; persist failure; platform failure rollback |
| `settings_security_view_test.dart` | toggle defaults off; UI reflects persist; enabling applies |
| `vault_user_message_test.dart` | Persian mapping for screen-protection failure |

---

## Real-device verification

Manual checklist (not covered by `flutter test`):

Protection ON:

- Power + Volume Down does not capture Keyva content
- Android screen recording shows black for Keyva
- Recents thumbnail does not show vault/unlock content
- Still protected after app restart, rotation, lock/unlock, background/foreground

Protection OFF:

- Screenshot works normally after the flag is cleared

---

## Known Android limitations

- `FLAG_SECURE` is the OS window flag. Some OEM screenshot tools, accessibility capture, or `adb shell screencap` on debuggable builds may still capture pixels.
- A physical camera pointed at the display is out of scope.
- Recents shows a blank/black preview; Keyva does not draw a custom blur overlay.
- The flag applies to this Activity window only (Keyva has a single main Activity).
- Dart does not learn that the flag is on until `setEnabled` / `applyPersisted` succeeds. Native still starts fail-closed.

---

## Files changed

New: screen-protection gateway/service, `ScreenProtectionFailure`, Task 17 tests, this note.

Extended: `MainActivity` (`FLAG_SECURE` + MethodChannel), `AuthRepository.setPreventScreenshots`, Settings ViewModel/View/bindings, `main.dart` startup apply, optional `VaultUnlockServiceImpl` hook, `injection_container.dart`.

Hive adapters, Vault encryption, PIN/biometric wrap format, and `SessionService` were not redesigned.
