import 'package:get/get.dart';
import 'package:keyva/core/database/models/security_settings.dart';
import 'package:keyva/core/exceptions/result.dart';
import 'package:keyva/core/routes/app_routing.dart';
import 'package:keyva/core/security/auto_lock_policy.dart';
import 'package:keyva/core/session/auto_lock_pause_store.dart';
import 'package:keyva/core/session/session_service.dart';
import 'package:keyva/feature/auth/repository/auth_repository.dart';
import 'package:keyva/feature/vault/service/vault_unlock_service.dart';

class AuthStartupViewModel extends GetxController {
  AuthStartupViewModel({
    required SessionService session,
    required AuthRepository auth,
    VaultUnlockService? unlock,
    AutoLockPauseStore? pauseStore,
    DateTime Function()? clock,
  }) : _session = session,
       _auth = auth,
       _unlock = unlock,
       _pauseStore = pauseStore,
       _clock = clock ?? DateTime.now;

  final SessionService _session;
  final AuthRepository _auth;
  final VaultUnlockService? _unlock;
  final AutoLockPauseStore? _pauseStore;
  final DateTime Function() _clock;

  Future<String> resolveInitialRoute() async {
    if (_session.isAuthenticated) {
      if (await _persistedPauseRequiresLock()) {
        await _unlock?.lock();
        return AppRoutes.authAccounts;
      }
      await _pauseStore?.clearPausedAt();
      return AppRoutes.shell;
    }
    final result = await _auth.hasAnyAccount();
    if (result is FailureResult<bool>) {
      return AppRoutes.authAccounts;
    }
    if (result is Success<bool> && result.data) {
      return AppRoutes.authAccounts;
    }
    return AppRoutes.onBoarding;
  }

  Future<bool> _persistedPauseRequiresLock() async {
    final pausedAt = _pauseStore?.readPausedAt();
    if (pausedAt == null) {
      return false;
    }
    final loaded = await _auth.currentSecuritySettings();
    final timeout = loaded is Success<SecuritySettings>
        ? loaded.data.autoLockTimeout
        : AutoLockPolicy.oneMinute;
    return timeout <= Duration.zero || _clock().difference(pausedAt) >= timeout;
  }
}
