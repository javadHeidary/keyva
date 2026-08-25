# Task 20 — Support Us (Bazaar / Myket)

This note describes the **Settings “حمایت از ما” section that is actually wired in the codebase**.

It is a learning reference and an implementation record. The source of truth is the Dart code and tests, not the architecture proposals.

Related code:

- [`lib/core/store/store_type.dart`](../../lib/core/store/store_type.dart)
- [`lib/core/store/store_config.dart`](../../lib/core/store/store_config.dart)
- [`lib/core/store/store_link_launcher.dart`](../../lib/core/store/store_link_launcher.dart)
- [`lib/core/store/store_link_launcher_impl.dart`](../../lib/core/store/store_link_launcher_impl.dart)
- [`lib/core/di/injection_container.dart`](../../lib/core/di/injection_container.dart)
- [`lib/feature/settings/model/support_us_content.dart`](../../lib/feature/settings/model/support_us_content.dart)
- [`lib/feature/settings/viewmodel/settings_viewmodel.dart`](../../lib/feature/settings/viewmodel/settings_viewmodel.dart)
- [`lib/feature/settings/bindings/settings_bindings.dart`](../../lib/feature/settings/bindings/settings_bindings.dart)
- [`lib/feature/settings/view/settings_view.dart`](../../lib/feature/settings/view/settings_view.dart)
- [`android/app/build.gradle.kts`](../../android/app/build.gradle.kts)
- [`android/app/src/main/AndroidManifest.xml`](../../android/app/src/main/AndroidManifest.xml)
- [`test/core/store/store_config_test.dart`](../../test/core/store/store_config_test.dart)
- [`test/core/store/store_link_launcher_test.dart`](../../test/core/store/store_link_launcher_test.dart)
- [`test/feature/settings/settings_support_us_test.dart`](../../test/feature/settings/settings_support_us_test.dart)

It reuses Task 19’s [`ShareSheetService`](../../lib/feature/vault/share/share_sheet_service.dart) for **app** sharing. It does **not** change vault item share, authentication, Vault encryption, backup/restore, PIN, biometrics, or session lifecycle.

---

## Purpose

Settings includes a Support Us section with three actions. Both Cafe Bazaar and Myket ship from **one codebase**. The current store is selected at compile time. The Settings UI never contains store URLs, package IDs, or `STORE` checks.

Rows (order in UI):

1. امتیاز به Keyva
2. اپلیکیشن‌های دیگر ما
3. اشتراک‌گذاری Keyva

Copy and error strings live in [`SupportUsContent`](../../lib/feature/settings/model/support_us_content.dart). Icons are `AppIcon.star`, `AppIcon.apps`, and `AppIcon.share`.

---

## Store selection

```text
--flavor bazaar|myket
 +
--dart-define=STORE=bazaar|myket
 ↓
StoreConfig.fromEnvironment()
 ↓
SettingsViewModel (no store URLs in the view)
```

- Dart source of truth: `String.fromEnvironment('STORE', defaultValue: 'bazaar')`
- Android flavors: `bazaar` (default) and `myket` in `android/app/build.gradle.kts`, same `applicationId` for now
- GetIt: `StoreConfig` and `StoreLinkLauncher` are lazy singletons
- Bindings pass them into `SettingsViewModel` together with `ShareSheetService`

Adding a third store later: new `StoreType` value, new `StoreConfig` factory, new flavor. Settings UI does not need a rewrite.

Run / build:

```text
flutter run --flavor bazaar --dart-define=STORE=bazaar
flutter run --flavor myket --dart-define=STORE=myket

flutter build apk --flavor bazaar --dart-define=STORE=bazaar
flutter build apk --flavor myket --dart-define=STORE=myket
```

`flutter test` does not pass `--dart-define=STORE`, so tests see Bazaar unless a test injects `StoreConfig.myket()`.

---

## StoreConfig

[`StoreConfig`](../../lib/core/store/store_config.dart) is the only place that knows Bazaar vs Myket URLs.

| Field | Bazaar | Myket |
|---|---|---|
| `keyvaStoreUrl` / `detailsWebUrl` | `https://cafebazaar.ir/app/{id}` | `https://myket.ir/app/{id}` |
| `reviewNativeUri` | `bazaar://details?id={id}` | `myket://comment?id={id}` |
| `reviewIntentAction` | `ACTION_EDIT` | `ACTION_VIEW` |
| `detailsNativeUri` | `bazaar://details?id={id}` | `myket://details?id={id}` |
| `storeAppPackage` | `com.farsitel.bazaar` | `ir.mservices.market` |
| Other apps | `bazaarOtherAppsNativeUri` / `WebUrl` | `myketOtherAppsNativeUri` / `WebUrl` |

Package id is `StoreConfig.defaultPackageId` (`com.example.keyva` until store release).

Do **not** use Google Play `in_app_review`. Bazaar’s official rate path is `ACTION_EDIT` on `bazaar://details`. Myket’s official path is `myket://comment?id=...`. WebView is never the primary review mechanism.

Native intents go through `android_intent_plus`. HTTPS fallbacks use existing `url_launcher` (`LaunchMode.externalApplication`).

Android 11+ package visibility: `AndroidManifest.xml` `<queries>` includes store packages and `bazaar` / `myket` schemes (VIEW + Bazaar EDIT).

---

## Rate Keyva

```text
امتیاز به Keyva
 ↓
Official review intent (store app)
 ↓
Keyva details in the store app
 ↓
Keyva https store page
 ↓
AppToast.info — امکان باز کردن صفحه امتیازدهی وجود ندارد.
```

No crash. No raw exception text.

---

## Other Apps

There is **no in-app catalog**. The row opens the developer listing on the **current store** (native URI, then https).

If both listing URLs are empty, nothing is launched. Toast: `لیست اپلیکیشن‌ها در حال حاضر در دسترس نیست.`

If a URL is set but cannot be opened: `امکان باز کردن لیست اپلیکیشن‌ها وجود ندارد.`

Those constants are currently empty and must be filled before store release (see below).

---

## Share Keyva

```text
اشتراک‌گذاری Keyva
 ↓
SupportUsContent.shareText(keyvaStoreUrl)
 ↓
ShareSheetService.shareText
 ↓
Native Android Share Sheet
```

There is **no** confirm dialog (that is vault-item-only, Task 19).

Share body is Persian, with the current store’s Keyva URL injected. Subject: `Keyva`.

`unavailable` → `AppToast.error` with `اشتراک‌گذاری انجام نشد`. Dismissed / shared → no toast.

---

## Error handling

| Case | User sees |
|---|---|
| Review intent and both fallbacks fail | info toast, rate copy |
| Other-apps URLs not configured | info toast, no launch |
| Other-apps URLs set but cannot open | info toast |
| Share service missing / store URL empty / `unavailable` | error toast, share copy |
| Native / URL launcher throws | treated as failure, never logged with payload |

---

## Before store release

Update [`store_config.dart`](../../lib/core/store/store_config.dart):

1. `defaultPackageId` — real application id on Bazaar and Myket
2. `bazaarOtherAppsNativeUri` / `bazaarOtherAppsWebUrl` — Cafe Bazaar developer collection
3. `myketOtherAppsNativeUri` / `myketOtherAppsWebUrl` — Myket developer listing

Keep URLs out of widgets. Change config only.

---

## Tests

```text
flutter test test/core/store test/feature/settings/settings_support_us_test.dart
```

- `store_config_test` — Bazaar vs Myket URLs, review URIs, no cross-store leakage, `fromEnvironment` default
- `store_link_launcher_test` — empty URI/URL, swallowed failures, injected URL launch
- `settings_support_us_test` — review fallback chain, other-apps native then web, missing listing toast, share text + store URL, Settings UI source has no `cafebazaar.ir` / `myket.ir` / `bazaar://` / `myket://`

Device review intents only work if that store app is installed and Keyva is listed. Fallbacks must still be safe.
