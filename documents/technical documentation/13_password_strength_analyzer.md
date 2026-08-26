# Password Strength Analyzer

## 1. Overview

Keyva shows a visual password strength score (0.0–1.0) on several screens. The score is a local heuristic based on length and character classes. It is **not** zxcvbn, NIST entropy, or a library analyzer. Acceptance of a Master Password or backup password is controlled separately by `MasterPasswordPolicy` (non-empty, minimum 8 characters).

## 2. Purpose

Give immediate feedback while typing. It does not gate account creation except insofar as the policy validator also runs on the same fields.

## 3. Architecture

| Layer | Role |
| --- | --- |
| Presentation | `PasswordStrengthBarWidget` |
| ViewModel / util | Scoring functions in login util, generator util, inline in `RegisterController` / `RestoreViewModel` |
| Repository / crypto | Not involved |
| Domain | Not present |

There is no `PasswordStrengthAnalyzer` class.

## 4. Implementation Flow

```text
Text field onChanged / listener
    ↓
double score = heuristic(password)
    ↓
Rx / widget parameter
    ↓
PasswordStrengthBarWidget maps score to 5 levels and Persian labels
```

**Login-item scoring** (`calculateLoginPasswordStrength`):

- empty → 0
- length ≥ 8 → +0.2; ≥ 12 → +0.1; ≥ 16 → +0.05
- has `[a-z]` → +0.15; `[A-Z]` → +0.15; `[0-9]` → +0.15; non-alphanumeric → +0.15
- clamp 0..1

**Generator scoring** (`calculatePasswordGeneratorStrength`): starts from login score, +0.05 if ≥3 classes, +0.05 if 4 classes, +0.05 if length ≥ 20, −0.15 if `_isPredictablePattern` (repeated char or prefixes like `0123`, `qwer`, …).

**Register / restore setup:** `RegisterController._visualPasswordStrength` and `RestoreViewModel._visualPasswordStrength` use a slightly different length rule ( ≥8 and ≥12 each +0.2, no +0.05 at 16) plus the same four character-class bonuses.

## 5. Important Classes & Files

| Class / File | Responsibility | Relationship |
| --- | --- | --- |
| `calculateLoginPasswordStrength` — `lib/feature/type/login/util/login_password_util.dart` | Login form + details | Also labels/colors |
| `calculatePasswordGeneratorStrength` — `lib/feature/password_generator/util/password_generator_strength.dart` | Generator meter | Calls login scorer then adjusts |
| `PasswordStrengthBarWidget` — `lib/shared/widget/password_strengthbar_widget.dart` | UI bar + enum `PasswordStrength` | Thresholds 0.2 / 0.4 / 0.6 / 0.8 |
| `RegisterController` | Inline `_visualPasswordStrength` | Register view |
| `RestoreViewModel` | Inline `_visualPasswordStrength` | Restore account setup |
| `LoginFormViewModel` | `_updatePasswordStrength` | Login create/edit |
| `LoginDetailsViewModel` | `calculateLoginPasswordStrength(login.password)` | Details screen |
| `MasterPasswordPolicy` | Hard requirement min 8 | Not a strength meter |

Bar labels: خیلی ضعیف / ضعیف / متوسط / قوی / خیلی قوی. Generator labels use `خوب` instead of `متوسط` for the middle band (`passwordGeneratorStrengthLabel`).

Color helper `loginPasswordStrengthColor`: below 0.4 error, below 0.6 warning, else success.

## 6. Data Flow

Passwords remain in `TextEditingController` / item models. The analyzer only produces a `double` and display strings. Nothing is persisted as a strength value.

## 7. Security Considerations

- Strength UI does not replace Argon2id or AES-GCM.
- A “very strong” meter score can still fail policy if somehow under 8 characters (the length bonuses make that unlikely for the register heuristic once length ≥ 8).
- Policy does not require mixed character classes.
- Generator subtracts score for a small set of predictable prefixes; this is not a dictionary attack model.

## 8. Error Handling

Scoring functions do not return `Result`. Invalid input is empty → 0. Form validation errors come from `MasterPasswordPolicy.fieldError` / confirm-match, not from the meter.

## 9. Edge Cases

- Three similar but not identical heuristics (login util vs register/restore vs generator).
- `PasswordStrengthBarWidget` middle label is `متوسط`; generator percent label uses `خوب` at the same numeric band.
- Login details show a text label via `loginPasswordStrengthLabel`.
- Restore setup tests assert the bar appears when typing (`backup_restore_view_test.dart`).

## 10. Testing

No dedicated automated test was found for strength **scoring**.

- `test/feature/type/login/login_password_util_test.dart` covers favicon/URL helpers in the same file, not `calculateLoginPasswordStrength`.
- `test/feature/backup/backup_restore_view_test.dart` asserts `PasswordStrengthBarWidget` visibility on restore setup.
- `test/core/security/master_password_policy_test.dart` covers the separate policy.

## 11. Technical Decisions

- Heuristic meter for UX; policy kept minimal (length) for Master/Backup passwords.
- Shared widget for the bar; scoring duplicated in a few ViewModels rather than one injected service.

## 12. Limitations / Notes

- Not a cryptographic strength estimate.
- Register heuristic is duplicated instead of calling `calculateLoginPasswordStrength`.
- Persian labels are hardcoded in Dart, not ARB files.

## 13. Summary

Password strength in Keyva is a 0–1 heuristic shown by `PasswordStrengthBarWidget`. Login items and the generator use util functions; register and restore setup use inline scorers. Account passwords are accepted based on `MasterPasswordPolicy`, not the meter.

Related: [Master Password](01_master_password_account_lifecycle.md), [Backup](09_secure_backup_restore.md), [MVVM](12_mvvm_architecture_viewmodels.md).
