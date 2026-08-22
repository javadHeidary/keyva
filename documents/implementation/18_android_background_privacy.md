# Task 18 — Android Background Privacy Overlay

This note describes the **Android background / Recents privacy overlay that is actually wired in the codebase**.

It is a learning reference and an implementation record. The source of truth is the Dart code and tests, not the architecture proposals.

Related code:

- [`lib/core/session/app_lock_controller.dart`](../../lib/core/session/app_lock_controller.dart)
- [`lib/core/session/privacy_overlay.dart`](../../lib/core/session/privacy_overlay.dart)
- [`lib/main.dart`](../../lib/main.dart)
- [`test/core/session/app_lock_controller_test.dart`](../../test/core/session/app_lock_controller_test.dart)
- [`test/core/session/privacy_overlay_test.dart`](../../test/core/session/privacy_overlay_test.dart)

It extends Task 13 (`AppLockController` is the single lifecycle observer) and works alongside Task 17 (`FLAG_SECURE`). It does **not** change Vault encryption, `VaultSerializer`, `VaultRepository`, `VaultDataService`, Vault Key, PIN/biometric crypto, backup/restore, or authentication architecture.

---

## Purpose

When the user leaves Keyva or switches to another app, the last Flutter frame must not show vault items, passwords, cards, notes, search results, or Settings content in Android Recents or during the background transition.

Keyva covers the entire navigator with an opaque theme-aware overlay until the app is fully resumed.

```text
Keyva (vault visible)
 ↓
Home / app switch
 ↓
inactive / hidden / paused
 ↓
Privacy overlay ON
 ↓
Recents sees only the overlay
 ↓
resumed
 ↓
existing auto-lock check (Task 13)
 ↓
Privacy overlay OFF
 ↓
Vault visible again, or Unlock if the session was locked
```

---

## Dependency decision

- Existing package reused: Flutter `WidgetsBindingObserver` / `AppLifecycleState` via `AppLockController`
- New package added: None
- Why: Keyva already observes lifecycle for auto-lock. A second package is not required to detect background/foreground.
- Existing project implementation reused: `AppLockController.handleLifecycle`, `Get.put(..., permanent: true)` in `main.dart`, `GetMaterialApp.builder`

---

## Lifecycle states

[`AppLockController`](../../lib/core/session/app_lock_controller.dart) remains the only `WidgetsBindingObserver`. Screens do not register their own observers.

| State | Overlay | Auto-lock (Task 13, unchanged) |
|---|---|---|
| `inactive` | ON | no-op (biometric / system UI is not treated as background) |
| `hidden` / `paused` / `detached` | ON | `_onBackground()` — Immediate lock, or start the timeout timer |
| `resumed` | OFF **after** `_onForeground()` completes | timeout check / lock if elapsed |

The overlay is hidden only on `resumed`. A later `inactive` while returning from Recents keeps the overlay on so vault UI is not exposed mid-transition.

`_onForeground()` runs before the overlay is cleared so a resume-time lock cannot flash vault content.

---

## Overlay architecture

The overlay is global. It is not added per screen.

```text
GetMaterialApp.builder
 ↓
AppResponsive.init
 ↓
PrivacyOverlayLayer (Stack)
    navigator / routes / dialogs
    Obx → PrivacyOverlay (only this slot rebuilds)
```

[`PrivacyOverlay`](../../lib/core/session/privacy_overlay.dart) is an opaque `ColoredBox` behind `AbsorbPointer`. It does not copy `VaultData`. It does not contain logos or text.

`overlayVisible` is an `RxBool` on `AppLockController`. `Obx` wraps only the overlay slot, not the navigator child. Lifecycle events do not recreate ViewModels, repositories, `VaultSession`, or `VaultData`.

---

## Theme behavior

The overlay color is taken from the current `Theme`, not from a stored `ThemePreference` flag:

```text
Theme.of(context).brightness == Brightness.light → Colors.white
Theme.of(context).brightness == Brightness.dark  → Colors.black
```

Light/dark follow `GetMaterialApp` (`theme` / `darkTheme` / `themeMode`), including Settings theme changes.

---

## AppLockController integration

Privacy overlay and auto-lock share one observer and stay separate:

- Overlay: visual cover
- Auto-lock: `VaultUnlockService.lock()` according to `SecuritySettings.autoLockTimeout`

Showing or hiding the overlay does not unlock the vault. If auto-lock already locked the session, resume still requires Master Password, PIN, or biometric through the existing Unlock flow.

`inactive` shows the overlay without starting the auto-lock timer, so a system biometric prompt does not count as backgrounding.

---

## Relationship with FLAG_SECURE (Task 17)

Task 17 sets Android `WindowManager.LayoutParams.FLAG_SECURE` from Settings (`preventScreenshots`).

These protections are independent:

| Task | What it hides |
|---|---|
| 17 `FLAG_SECURE` | Screenshots, screen recording, and often a blank Recents card when the setting is on |
| 18 Overlay | Flutter UI while backgrounded / in Recents, **whether FLAG_SECURE is on or off** |

If FLAG_SECURE is enabled, it stays enabled. If it is disabled, the overlay still covers content when the app is backgrounded. Task 18 does not call `ScreenProtectionService`.

---

## Relationship with auto-lock

Backgrounding does not clear `VaultSession` or `SessionService` by itself.

If the configured timeout is Immediate, Task 13 still locks while backgrounded. If the timeout is 1 minute and the user returns earlier, the session stays Unlocked and the overlay is removed.

---

## Tests

Flutter tests do not take Recents screenshots. They drive `handleLifecycle` with `observeBinding: false`.

| File | Scenarios |
|---|---|
| `app_lock_controller_test.dart` | overlay hidden at start; inactive overlay without lock; paused/hidden overlay; overlay stays on until resumed; resume before timeout; resume after timeout; timer expiry; overlay hide after lock does not unlock; already-locked session |
| `privacy_overlay_test.dart` | overlay hidden at start; inactive/paused visible; stays until resumed; light = white; dark = black; covered child not hit-testable; `VaultSession` / `SessionService` unchanged |

---

## Real-device verification

Manual checklist (not covered by `flutter test`):

1. Open Keyva with a vault that has sensitive items.
2. Press Home.
3. Open Recents: Keyva preview must show only the white or black overlay (or the FLAG_SECURE blank card when screenshot protection is on).
4. Switch to another app, return to Keyva: content becomes visible again if the session is still unlocked.

Also verify:

- Light theme and dark theme
- Screenshot protection ON and OFF
- Auto-lock Immediate and 1 minute
- Master Password, PIN, and biometric unlock (overlay must not skip Unlock)

---

## Known limitations

- Android may snapshot Recents from the last composed frame. Showing the overlay on `inactive` (before `paused`) reduces the race; a 1-frame leak is still possible without `FLAG_SECURE`.
- The overlay is a Flutter widget. Native launch/window chrome outside the Flutter view is not covered.
- System biometric UI is a native window above Flutter, so the overlay does not block the OS prompt.
- The overlay does not replace Task 17. `FLAG_SECURE` remains the protection against screenshots and recording.
- Dart does not zeroize in-memory vault data when the overlay is shown. Auto-lock (Task 13) is what clears the session.

---

## Files changed

New: `PrivacyOverlay` / `PrivacyOverlayLayer`, Task 18 tests, this note.

Extended: `AppLockController` (`overlayVisible` + lifecycle mapping), `main.dart` `GetMaterialApp.builder`.

Hive adapters, Vault encryption format, PIN/biometric wrap format, `SessionService`, and `ScreenProtectionService` were not redesigned.
