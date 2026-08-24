import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:keyva/core/database/models/security_settings.dart';
import 'package:keyva/core/exceptions/result.dart';
import 'package:keyva/core/routes/app_routing.dart';
import 'package:keyva/core/security/auto_lock_policy.dart';
import 'package:keyva/core/session/auto_lock_pause_store.dart';
import 'package:keyva/core/session/session_service.dart';
import 'package:keyva/feature/auth/repository/auth_repository.dart';
import 'package:keyva/feature/vault/service/vault_unlock_service.dart';

class AppLockController extends GetxController with WidgetsBindingObserver {
  AppLockController({
    required SessionService session,
    required VaultUnlockService unlock,
    required AuthRepository auth,
    AutoLockPauseStore? pauseStore,
    DateTime Function()? clock,
    Timer Function(Duration duration, void Function() callback)? startTimer,
    VoidCallback? onLocked,
    String Function()? currentRoute,
    this.observeBinding = true,
  }) : _session = session,
       _unlock = unlock,
       _auth = auth,
       _pauseStore = pauseStore,
       _clock = clock ?? DateTime.now,
       _startTimer = startTimer ?? Timer.new,
       _onLocked = onLocked,
       _currentRoute = currentRoute;

  final SessionService _session;
  final VaultUnlockService _unlock;
  final AuthRepository _auth;
  final AutoLockPauseStore? _pauseStore;
  final DateTime Function() _clock;
  final Timer Function(Duration duration, void Function() callback) _startTimer;
  final VoidCallback? _onLocked;
  final String Function()? _currentRoute;
  final bool observeBinding;

  final overlayVisible = false.obs;

  bool _isBackground = false;
  int _generation = 0;
  DateTime? _pausedAt;
  Duration _cachedTimeout = AutoLockPolicy.oneMinute;
  Duration _pausedTimeout = AutoLockPolicy.oneMinute;
  Timer? _timer;
  bool _locking = false;

  @override
  void onInit() {
    super.onInit();
    if (observeBinding) {
      WidgetsBinding.instance.addObserver(this);
    }
    unawaited(applyPersistedPause());
  }

  @override
  void onClose() {
    if (observeBinding) {
      WidgetsBinding.instance.removeObserver(this);
    }
    _cancelTimer();
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    handleLifecycle(state);
  }

  void handleLifecycle(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        unawaited(_onResumed());
      case AppLifecycleState.inactive:
        _showOverlay();
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _showOverlay();
        unawaited(_onBackground());
    }
  }

  void onTimeoutChanged(Duration timeout) {
    _cachedTimeout = timeout;
    if (!_isBackground) {
      _pausedTimeout = timeout;
      return;
    }
    _pausedTimeout = timeout;
    _scheduleBackgroundLock();
  }

  Future<void> applyPersistedPause() async {
    if (!_session.isAuthenticated) {
      return;
    }
    final pausedAt = _pauseStore?.readPausedAt();
    if (pausedAt == null) {
      return;
    }
    final timeout = await _loadTimeout();
    if (!_session.isAuthenticated) {
      return;
    }
    if (timeout <= Duration.zero || _clock().difference(pausedAt) >= timeout) {
      await _lock();
      return;
    }
    await _pauseStore?.clearPausedAt();
  }

  void _showOverlay() {
    overlayVisible.value = true;
  }

  Future<void> _onResumed() async {
    await _onForeground();
    overlayVisible.value = false;
  }

  Future<void> _onBackground() async {
    if (_isBackground) {
      return;
    }
    _isBackground = true;
    _generation++;
    _pausedAt = _clock();
    _cancelTimer();
    await _pauseStore?.writePausedAt(_pausedAt!);
    if (!_session.isAuthenticated) {
      return;
    }

    final generation = _generation;
    final timeout = await _loadTimeout();
    if (generation != _generation || !_isBackground) {
      return;
    }
    _pausedTimeout = timeout;
    _scheduleBackgroundLock();
  }

  Future<void> _onForeground() async {
    if (!_isBackground) {
      return;
    }
    _isBackground = false;
    _generation++;
    _cancelTimer();
    final pausedAt = _pausedAt;
    _pausedAt = null;
    if (!_session.isAuthenticated || pausedAt == null) {
      await _pauseStore?.clearPausedAt();
      return;
    }
    if (_clock().difference(pausedAt) >= _pausedTimeout) {
      await _lock();
      return;
    }
    await _pauseStore?.clearPausedAt();
  }

  void _scheduleBackgroundLock() {
    _cancelTimer();
    if (!_isBackground || !_session.isAuthenticated) {
      return;
    }
    final timeout = _pausedTimeout;
    if (timeout <= Duration.zero) {
      unawaited(_lock());
      return;
    }
    final pausedAt = _pausedAt;
    final remaining = pausedAt == null
        ? timeout
        : timeout - _clock().difference(pausedAt);
    if (remaining <= Duration.zero) {
      unawaited(_lock());
      return;
    }
    final generation = _generation;
    _timer = _startTimer(remaining, () {
      if (generation != _generation) {
        return;
      }
      unawaited(_lock());
    });
  }

  Future<Duration> _loadTimeout() async {
    final loaded = await _auth.currentSecuritySettings();
    if (loaded is Success<SecuritySettings>) {
      _cachedTimeout = loaded.data.autoLockTimeout;
    }
    return _cachedTimeout;
  }

  Future<void> _lock() async {
    if (_locking || !_session.isAuthenticated) {
      return;
    }
    _locking = true;
    _cancelTimer();
    try {
      await _pauseStore?.clearPausedAt();
      await _unlock.lock();
      _navigateToAccountList();
    } finally {
      _locking = false;
    }
  }

  void _navigateToAccountList() {
    final onLocked = _onLocked;
    if (onLocked != null) {
      onLocked();
      return;
    }
    if (_isAuthRoute(_currentRoute?.call() ?? Get.currentRoute)) {
      return;
    }
    Get.offAllNamed(AppRoutes.authAccounts);
  }

  bool _isAuthRoute(String route) {
    return route == AppRoutes.authAccounts ||
        route == AppRoutes.authUnlock ||
        route == AppRoutes.authLogin ||
        route == AppRoutes.authRegister ||
        route == AppRoutes.authRestore ||
        route == AppRoutes.authRestoreSetup;
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }
}
