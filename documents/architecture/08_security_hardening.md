
# `08_security_hardening.md`

````md
# Keyva Security Hardening

## Purpose

This document defines implementation-level security rules for Keyva.

It complements the existing security, database, cryptography,
authentication, backup, data model, and account lifecycle documents.

This document MUST NOT redefine cryptographic architecture.

It focuses on preventing accidental exposure of sensitive data
during application execution.

---

# 1. Scope

This document covers:

- Sensitive data handling in memory
- Logging
- Exceptions
- Clipboard
- Screenshots
- Screen recording
- Background app snapshots
- Debug vs Release
- Temporary files
- Local storage boundaries
- Secure Storage usage
- Dependency security
- Android security
- iOS security
- Error handling
- Development security rules

---

# 2. Sensitive Data Classification

Keyva MUST classify data into three categories.

## Level 1 — Public

Examples:

```text
App name
App version
Theme
UI preferences
````

These may safely appear in normal application logs.

---

## Level 2 — Private

Examples:

```text
Username
User ID
Category names
Non-sensitive settings
```

These SHOULD NOT be unnecessarily logged.

---

## Level 3 — Highly Sensitive

Examples:

```text
Master Password
Derived Key
Vault Key
PIN
Login Password
Bank Card Number
CVV
Secure Note Content
Decrypted VaultData
Encryption Keys
Backup Contents
```

These MUST NEVER appear in:

- Logs
    
- Debug prints
    
- Crash reports
    
- Analytics
    
- Exception messages
    
- URLs
    
- Clipboard unless explicitly requested by the user
    

---

# 3. Master Password Handling

Master Password MUST:

- Exist only when required.
    
- Never be persisted in plaintext.
    
- Never be logged.
    
- Never be placed in GetX observable state unnecessarily.
    
- Never be included in exceptions.
    
- Never be included in analytics.
    
- Never be copied to Clipboard automatically.
    

After authentication is complete, the plaintext Master Password  
SHOULD become unreachable as soon as practical.

---

# 4. Cryptographic Key Handling

The following MUST NOT be persisted as plaintext:

```text
Vault Key
Derived Key
Encryption Keys
```

Keys MAY temporarily exist in memory during cryptographic operations.

When no longer required, the application SHOULD release references  
to sensitive key material as soon as practical.

---

# 5. Decrypted VaultData

Decrypted VaultData MUST exist only while the vault is unlocked.

Conceptually:

```text
Locked
  ↓
Authenticate
  ↓
Decrypt Vault
  ↓
VaultData in memory
  ↓
User works with vault
  ↓
Lock
  ↓
Release VaultData
```

The application MUST NOT persist decrypted VaultData to disk.

---

# 6. GetX State

GetX controllers and reactive variables MUST NOT unnecessarily  
retain sensitive data longer than required.

Avoid long-lived state such as:

```dart
RxString masterPassword;
RxString vaultKey;
RxString decryptedVaultJson;
```

Prefer short-lived variables inside the operation that requires them.

Sensitive state SHOULD be cleared when:

- User logs out
    
- User switches account
    
- App locks
    
- Auto-lock triggers
    
- Authentication fails
    
- Vault is closed
    

---

# 7. Logging Policy

Production builds MUST NOT log sensitive information.

Forbidden:

```dart
print(password);
debugPrint(cardNumber);
log(vaultData.toString());
log(masterPassword);
```

Also forbidden:

```text
Request payload containing credentials
Exception containing password
Serialized VaultData
Encryption keys
Backup contents
```

---

# 8. Logging Allowed

Normal logs MAY contain:

```text
Account created
Vault unlocked
Backup started
Backup completed
Restore failed
Authentication failed
```

But MUST NOT contain sensitive values.

Preferred:

```text
Authentication failed
```

Not:

```text
Authentication failed for password: 123456
```

---

# 9. Production Logging

Release builds SHOULD use a controlled logging mechanism.

Do not leave unrestricted:

```dart
print()
debugPrint()
```

throughout production code.

Logging SHOULD be centralized.

Example conceptual interface:

```dart
abstract class AppLogger {
  void info(String message);
  void warning(String message);
  void error(String message);
}
```

The logger MUST sanitize sensitive information.

---

# 10. Exception Handling

Exceptions MUST NOT contain sensitive data.

Bad:

```dart
throw Exception(
  'Invalid password: $password',
);
```

Good:

```dart
throw AuthenticationException(
  'Authentication failed',
);
```

---

# 11. Error Messages

User-facing errors SHOULD be generic when revealing details  
could help an attacker.

Example:

```text
Incorrect Master Password
```

instead of:

```text
Vault Key unwrap failed because AES-GCM authentication tag
did not match.
```

Technical cryptographic details belong in internal diagnostics,  
not user-facing UI.

---

# 12. Crash Reports

If crash reporting is introduced in the future:

Crash reports MUST NOT include:

```text
Master Password
Vault Key
Derived Key
PIN
VaultData
Login Password
Bank Card Data
Secure Notes
Backup Contents
```

Sensitive application state MUST be excluded from crash metadata.

---

# 13. Clipboard

Clipboard is considered an external data boundary.

Password copying SHOULD be explicit user action only.

When the user copies:

```text
Username
Password
Card Number
```

Keyva SHOULD provide automatic clipboard clearing after a short  
configurable period where supported.

The default behavior SHOULD prioritize security.

---

# 14. Clipboard Rules

Keyva MUST NOT:

- Automatically copy passwords.
    
- Copy sensitive data during app startup.
    
- Copy sensitive data during navigation.
    
- Leave sensitive clipboard content indefinitely when it can be avoided.
    

Clipboard operations SHOULD be centralized.

---

# 15. Screenshots

Keyva SHOULD prevent screenshots and screen recording on  
sensitive screens where platform support allows it.

At minimum, protection SHOULD apply to:

```text
Vault
Login Details
Bank Card Details
Secure Note
Password Generator
Security Settings
Master Password screens
PIN screens
Backup/Restore sensitive flows
```

The exact platform implementation belongs to the platform security layer.

---

# 16. Background App Snapshot

When Keyva moves to the background, sensitive content SHOULD NOT  
remain visible in the operating system's application preview.

The application SHOULD obscure sensitive UI before the OS captures  
the background snapshot.

Conceptually:

```text
App Active
   ↓
App Background
   ↓
Sensitive UI Obscured
   ↓
OS Snapshot
```

---

# 17. Auto Lock and Backgrounding

Backgrounding MAY trigger the configured auto-lock behavior.

The application MUST follow the user's configured security policy.

When locking occurs:

```text
Session
  ↓
Clear
```

and:

```text
Decrypted VaultData
  ↓
Release
```

---

# 18. Temporary Files

Keyva MUST NOT create plaintext temporary files containing:

```text
Passwords
Card Numbers
Secure Notes
VaultData
Encryption Keys
```

If temporary storage is unavoidable:

```text
Create
 ↓
Use
 ↓
Delete
```

Encrypted representations SHOULD be preferred.

---

# 19. File Export

Exported backup files are sensitive.

The application SHOULD:

- Use a dedicated `.keyva` format.
    
- Avoid plaintext export.
    
- Avoid unnecessary duplicate copies.
    
- Delete temporary export files when finished.
    

---

# 20. Secure Storage

Platform secure storage MAY be used for small device-specific  
secrets.

Examples:

```text
Device-specific unlock credential
Local security metadata
Small cryptographic wrapping material
```

Secure Storage MUST NOT be treated as the primary vault database.

The main vault remains in:

```text
Hive
```

and is protected by the cryptographic architecture already defined.

---

# 21. Secure Storage Boundary

Do NOT store the entire vault in platform secure storage.

Avoid:

```text
SecureStorage
 └── Entire Vault
```

Preferred:

```text
Hive
 └── Encrypted Vault

Secure Storage
 └── Device-specific security material
```

---

# 22. Database Boundary

Hive MUST contain only the persistent data defined by the  
database architecture.

Sensitive vault data MUST remain encrypted at rest.

Do not create convenience boxes such as:

```text
passwordsBox
cardsBox
notesPlaintextBox
```

for storing unencrypted sensitive information.

---

# 23. Database File Access

Keyva MUST assume that local application storage may eventually  
become accessible to an attacker with sufficient device access.

Therefore:

```text
Database security
      +
Cryptographic encryption
```

must work together.

Security MUST NOT rely only on:

```text
"Android app data is private."
```

---

# 24. Debug Mode

Debug builds MAY provide developer diagnostics.

However, sensitive values MUST NOT be printed even in Debug mode.

Do NOT use:

```dart
debugPrint(vaultKey);
debugPrint(masterPassword);
```

simply because the build is Debug.

---

# 25. Release Mode

Release builds MUST:

- Disable verbose diagnostic logging.
    
- Remove development-only debugging behavior.
    
- Avoid test credentials.
    
- Avoid hardcoded passwords.
    
- Avoid hardcoded encryption keys.
    
- Avoid development bypasses.
    

---

# 26. Authentication Bypass

The application MUST NOT contain:

```text
if (kDebugMode) {
   unlockVault();
}
```

or any equivalent authentication bypass.

Debug mode MUST NOT bypass security.

---

# 27. Hardcoded Secrets

Never hardcode:

```text
Master Password
PIN
Vault Key
Encryption Key
API Secret
Private Key
```

inside source code.

---

# 28. Source Control

The repository MUST NOT contain:

```text
.env with secrets
production credentials
private keys
real user backups
real passwords
test accounts containing real data
```

Sensitive local files MUST be excluded using `.gitignore`.

---

# 29. Test Data

Automated tests MUST use fake data.

Example:

```text
test-password-123
fake-card-number
dummy-note
```

Real credentials MUST never be used in tests.

---

# 30. Test Backups

Test backup files MUST contain only synthetic data.

Never commit:

```text
real_user_backup.keyva
```

to source control.

---

# 31. Dependency Security

Keyva SHOULD minimize dependencies.

Before adding a package:

1. Confirm it is necessary.
    
2. Check maintenance status.
    
3. Check package reputation.
    
4. Review permissions.
    
5. Check whether it handles sensitive data.
    
6. Check whether a simpler native implementation is sufficient.
    

Do not add a package only for convenience when it introduces  
unnecessary security or maintenance risk.

---

# 32. Crypto Dependencies

Cryptographic functionality SHOULD use established,  
well-maintained cryptographic libraries.

Do NOT implement cryptographic algorithms manually.

Never implement:

```text
AES
AES-GCM
Argon2id
Random Number Generator
Key Derivation
```

from scratch.

---

# 33. Randomness

Security-sensitive random values MUST use a cryptographically  
secure random source.

Examples:

```text
User ID
Vault Key
Salt
Nonce
```

Do NOT use:

```dart
Random()
```

for cryptographic purposes.

---

# 34. Nonce Reuse

AES-GCM nonce reuse MUST be avoided.

Every encryption operation requiring a nonce MUST generate a  
fresh cryptographically secure nonce according to the crypto  
specification.

Never reuse a nonce with the same encryption key.

---

# 35. Authentication Tag

Encrypted data MUST always be authenticated.

If authentication verification fails:

```text
Reject Data
```

Do NOT attempt to decrypt or use partially authenticated data.

---

# 36. Android Security

Android-specific security behavior MUST be implemented through  
a dedicated platform/security service where appropriate.

Examples:

```text
Screenshot protection
Biometric authentication
Secure Storage
Application lifecycle
```

Platform-specific code MUST NOT leak into ViewModels.

---

# 37. Android Screenshot Protection

Where supported, Keyva SHOULD use Android platform mechanisms to  
prevent screenshots/screen capture for sensitive screens.

The implementation MUST be centralized rather than repeated  
throughout every View.

---

# 38. iOS Security

iOS-specific security behavior MUST use platform-supported APIs.

Examples:

```text
Biometric authentication
Secure Storage / Keychain
Application lifecycle
Sensitive UI protection
```

Platform-specific code MUST remain outside ViewModels.

---

# 39. Platform Abstraction

The architecture SHOULD expose platform security through services.

Conceptual:

```text
ViewModel
    ↓
SecurityService
    ↓
Android / iOS Implementation
```

Do not write Android-specific code directly inside Flutter UI widgets.

---

# 40. Biometric Authentication

Biometric authentication MUST be treated as a device authentication  
mechanism.

It does not replace the Master Password as the root account secret.

Conceptually:

```text
Master Password
    ↓
Root Account Authentication

Biometric
    ↓
Device Convenience Unlock
```

---

# 41. PIN Authentication

PIN follows the same principle:

```text
Master Password
    ↓
Root Authentication

PIN
    ↓
Device Convenience Unlock
```

PIN MUST NOT become the permanent cryptographic root of the vault.

---

# 42. Sensitive UI

Sensitive screens SHOULD avoid unnecessary persistence of UI state.

Examples:

```text
Password detail
Card detail
Secure note
Master Password
PIN
```

Sensitive fields SHOULD be cleared when the relevant screen or  
session is no longer active.

---

# 43. Text Editing Controllers

Sensitive text fields SHOULD be disposed and cleared when no  
longer required.

Examples:

```text
Master Password TextEditingController
PIN TextEditingController
Password field controller
```

Do not keep sensitive controllers alive globally.

---

# 44. Navigation

Navigation MUST NOT pass sensitive information through route  
arguments when avoidable.

Avoid:

```dart
Get.to(
  () => PasswordDetailsView(),
  arguments: {
    'password': plaintextPassword,
  },
);
```

Prefer:

```text
Pass item ID
      ↓
Load data from active secure session
```

---

# 45. URL Handling

Sensitive data MUST NOT be placed in URLs or query parameters.

Never:

```text
https://example.com?password=123456
```

---

# 46. Analytics

Keyva SHOULD NOT collect sensitive vault analytics.

Never send:

```text
Passwords
Card numbers
Secure Notes
Master Password
Vault contents
```

Analytics MAY contain anonymous product events such as:

```text
screen_opened
backup_created
theme_changed
```

without sensitive payloads.

---

# 47. Network Boundary

Keyva is offline-first.

Core vault operations MUST NOT require network access.

The following MUST work offline:

```text
Create Account
Login
Unlock
View Vault
Create Item
Edit Item
Delete Item
Generate Password
Search Vault
Lock
```

---

# 48. No Automatic Vault Upload

Keyva MUST NOT automatically upload:

```text
VaultData
Backup
Master Password
Encryption Keys
```

to remote servers.

---

# 49. Error Recovery

Security-sensitive failures SHOULD fail closed.

Examples:

```text
Vault decryption failure
Key unwrap failure
Authentication failure
Backup integrity failure
Database corruption
```

Expected behavior:

```text
Reject operation
Clear sensitive session state if necessary
Keep existing valid data unchanged
Require authentication again if necessary
```

---

# 50. Database Corruption

If the encrypted database becomes corrupted:

Keyva MUST NOT attempt unsafe recovery by guessing or modifying  
cryptographic data.

Preferred:

```text
Detect
 ↓
Reject
 ↓
Preserve backup/local copy if possible
 ↓
Inform user
 ↓
Offer Restore
```

---

# 51. Memory Exposure

Keyva cannot guarantee that plaintext data can be instantly  
physically erased from memory in every managed-runtime situation.

Therefore the goal is:

- Minimize lifetime.
    
- Minimize copies.
    
- Avoid unnecessary duplication.
    
- Avoid global references.
    
- Clear references when practical.
    
- Lock the vault when inactive.
    

Do not claim that Dart memory can be perfectly zeroized.

---

# 52. Sensitive Data Duplication

Avoid unnecessary conversions such as:

```text
Password
 ↓
String
 ↓
JSON
 ↓
Map
 ↓
String
 ↓
Bytes
```

when a simpler path is available.

Every copy increases exposure lifetime.

---

# 53. Serialization Security

Before serializing VaultData:

```text
Validate
 ↓
Serialize
 ↓
Encrypt
```

Plaintext serialized VaultData MUST NOT be written to persistent  
storage.

---

# 54. Security-Sensitive Operations

The following operations SHOULD be centralized:

```text
Encrypt
Decrypt
Derive Key
Wrap Key
Unwrap Key
Generate Secure Random Data
Clipboard Clear
Screenshot Protection
Secure Storage
Biometric Authentication
```

This prevents inconsistent security behavior across features.

---

# 55. Security Service Structure

Recommended conceptual services:

```text
CryptoService
SecureStorageService
BiometricService
PinService
ClipboardService
AppSecurityService
SessionService
```

Do not create one giant security service.

---

# 56. Security Testing

Security-related tests MUST cover:

### Authentication

```text
Correct Master Password → Success
Wrong Master Password → Failure
```

### Vault

```text
Correct Key → Decrypt
Wrong Key → Fail
Modified Ciphertext → Fail
```

### Session

```text
Lock → Sensitive session data cleared
Logout → Sensitive session data cleared
Switch Account → Previous account unavailable
```

### Backup

```text
Valid Backup → Restore
Wrong Password → Fail
Modified Backup → Fail
```

### Clipboard

```text
Copy Password
→ Clipboard cleared according to policy
```

---

# 57. Security Regression Rule

Any change affecting:

```text
Authentication
Cryptography
Database
Backup
Session
PIN
Biometric
Sensitive UI
```

MUST trigger security regression testing.

---

# 58. Code Review Security Checklist

Before merging security-sensitive code:

```text
[ ] No plaintext secrets persisted
[ ] No sensitive logs
[ ] No hardcoded secrets
[ ] No authentication bypass
[ ] No plaintext temporary files
[ ] No sensitive route arguments
[ ] No unnecessary data copies
[ ] Correct session clearing
[ ] Correct lock behavior
[ ] Correct error handling
[ ] No crypto implementation from scratch
[ ] No insecure random generation
```

---

# 59. Final Security Hardening Principle

Keyva security is not one feature.

It is the combination of:

```text
Cryptography
+
Secure Storage
+
Database Protection
+
Authentication
+
Session Management
+
Memory Discipline
+
UI Protection
+
Backup Security
+
Platform Security
+
Safe Error Handling
```

Every new feature MUST be evaluated against these boundaries.

---

# 60. Final Implementation Rules

Cursor MUST:

- Never log sensitive data.
    
- Never persist plaintext vault data.
    
- Never persist Master Password.
    
- Never hardcode secrets.
    
- Never implement cryptography manually.
    
- Never use insecure randomness for cryptographic values.
    
- Never bypass authentication in Debug mode.
    
- Never pass sensitive data through navigation unnecessarily.
    
- Never create plaintext temporary vault files.
    
- Protect sensitive screens from screenshots where supported.
    
- Protect sensitive content from background snapshots.
    
- Clear active sensitive session state when locking/logging out.
    
- Keep device-specific credentials separate from account cryptography.
    
- Keep platform-specific security code outside ViewModels.
    
- Keep security services focused.
    
- Follow the existing MVVM + GetX architecture.
    
- Do not introduce unnecessary Clean Architecture layers.
    
- Fail closed when a security-sensitive operation cannot be verified.
    

If a security requirement conflicts with another architecture document,  
Cursor MUST stop and report the conflict before implementation.

````