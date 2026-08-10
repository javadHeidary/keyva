# Shell (Main Navigation)

The shell is the post-authentication root UI: four primary tabs, one shared bottom navigation bar, and preserved tab state while detail routes are pushed on top.

## Route

| Constant | Path | Widget | Bindings |
|----------|------|--------|----------|
| `AppRoutes.home` | `/home` | `MainShellView` | `MainShellBindings` |

After login/register, navigation uses `Get.offAllNamed(AppRoutes.home)`. The app entry before auth is `AppRoutes.authLogin` (`main.dart`).

Detail flows (create/edit/details, type list, password history, etc.) remain separate `GetPage` routes pushed with `Get.toNamed`. They do not include the shell bottom bar.

## Layout

```
MainShellView (Scaffold, extendBody: true)
└── Stack
    ├── IndexedStack                    ← active tab only visible; others kept alive
    │   └── MainShellTabInsets × 4      ← bottom padding for floating nav
    │       ├── HomeView
    │       ├── PasswordGeneratorView(embeddedInShell: true)
    │       ├── CategoryListView
    │       └── SettingsView
    └── Align(bottom) → KeyvaBottomNavigationBar
```

- **IndexedStack** keeps scroll position and controller state when switching tabs.
- **MainShellTabInsets** applies `MainShellLayout.contentBottomGap` so list content is not hidden under the floating bar. This metric must match `KeyvaBottomNavigationBar` (safe area + outer padding + bar height + small gap).
- The nav bar is **not** `Scaffold.bottomNavigationBar`; it is overlaid in a `Stack` so there is no extra scaffold surface behind it.

## State (GetX)

| Type | File | Role |
|------|------|------|
| `MainShellController` | `viewmodel/main_shell_viewmodel.dart` | `currentIndex.obs`, `setTab(int)` |
| `MainShellTab` | same | Tab indices: `home` 0, `passwordGenerator` 1, `categories` 2, `settings` 3 |

`MainShellBindings` registers dependencies for all four features plus `MainShellController` and `CategoryListViewModel`.

### Switching tabs from other features

Use `switchMainShellTab(int)` from `util/main_shell_navigation.dart` (checks `Get.isRegistered<MainShellController>`). Prefer `MainShellTab` constants instead of raw indices.

Example: drawer shortcuts in `HomeView` call `switchMainShellTab(MainShellTab.settings)`.

Do not add a second navigation controller for tab index.

## UI components

| Widget | File | Responsibility |
|--------|------|----------------|
| `KeyvaBottomNavigationBar` | `widget/keyva_bottom_navigation_bar.dart` | Floating bar UI; active tab shows icon + label pill |
| `KeyvaBottomNavItem` | same | Icon/label config per tab |
| `MainShellTabInsets` | `widget/main_shell_tab_insets.dart` | Bottom padding wrapper for tab roots |

Tab labels and icons are defined in `MainShellView._navItems`.

## Feature integration notes

- **Password generator**: `embeddedInShell: true` hides the back button in the header when shown as a tab.
- **FAB** (home, categories): Implemented inside each feature `Scaffold` (e.g. `FloatingActionButton.small`). FAB position is not handled by the shell; tabs rely on `MainShellTabInsets` and feature-level layout.
- **Settings / generator scroll padding**: Feature slivers may add small trailing padding; the main clearance for the nav bar comes from `MainShellTabInsets`.

## Adding a fifth tab (checklist)

1. Add index constant on `MainShellTab` and increase `tabCount`.
2. Register feature bindings in `MainShellBindings`.
3. Add child to `IndexedStack` wrapped in `MainShellTabInsets`.
4. Add `KeyvaBottomNavItem` in `MainShellView._navItems`.
5. Update `contentBottomGap` if the nav bar height changes.

## Files

```
lib/feature/shell/
├── bindings/main_shell_bindings.dart
├── util/main_shell_layout.dart      # contentBottomGap
├── util/main_shell_navigation.dart  # switchMainShellTab
├── view/main_shell_view.dart
├── viewmodel/main_shell_viewmodel.dart
└── widget/
    ├── keyva_bottom_navigation_bar.dart
    └── main_shell_tab_insets.dart
```
