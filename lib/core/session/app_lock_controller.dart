import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:keyva/core/database/models/security_settings.dart';
import 'package:keyva/core/exceptions/result.dart';
import 'package:keyva/core/routes/app_routing.dart';
import 'package:keyva/core/security/auto_lock_policy.dart';
import 'package:keyva/core/session/session_service.dart';
import 'package:keyva/feature/auth/repository/auth_repository.dart';
import 'package:keyva/feature/vault/service/vault_unlock_service.dart';

class AppLockController extends GetxController with WidgetsBindingObserver {
  AppLockController({
    required SessionService session,
    required VaultUnlockService unlock,
    required AuthRepository auth,
    DateTime Function()? clock,
    Timer Function(Duration duration, void Function() callback)? startTimer,
    VoidCallback? onLocked,
    this.observeBinding = true,
  }) : _session = session,
       _unlock = unlock,
       _auth = auth,
       _clock = clock ?? DateTime.now,
       _startTimer = startTimer ?? Timer.new,
       _onLocked = onLocked;

  final SessionService _session;
  final VaultUnlockService _unlock;
  final AuthRepository _auth;
  final DateTime Function() _clock;
  final Timer Function(Duration duration, void Function() callback) _startTimer;
  final VoidCallback? _onLocked;
  final bool observeBinding;

  bool _isBackground = false;
  int _generation = 0;
  DateTime? _pausedAt;
  Duration _pausedTimeout = AutoLockPolicy.oneMinute;
  Timer? _timer;
  bool _locking = false;

  @override
  void onInit() {
    super.onInit();
    if (observeBinding) {
      WidgetsBinding.instance.addObserver(this);
    }
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
        unawaited(_onForeground());
      case AppLifecycleState.inactive:
        break;
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        unawaited(_onBackground());
    }
  }

  Future<void> _onBackground() async {
    if (_isBackground) {
      return;
    }
    _isBackground = true;
    final generation = ++_generation;
    _pausedAt = _clock();
    _cancelTimer();
    if (!_session.isAuthenticated) {
      return;
    }

    final timeout = await _loadTimeout();
    if (generation != _generation || !_isBackground) {
      return;
    }
    _pausedTimeout = timeout;
    if (timeout <= Duration.zero) {
      await _lock();
      return;
    }
    _timer = _startTimer(timeout, () {
      unawaited(_lock());
    });
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
      return;
    }
    if (_clock().difference(pausedAt) >= _pausedTimeout) {
      await _lock();
    }
  }

  Future<Duration> _loadTimeout() async {
    final loaded = await _auth.currentSecuritySettings();
    if (loaded is Success<SecuritySettings>) {
      return loaded.data.autoLockTimeout;
    }
    return Duration.zero;
  }

  Future<void> _lock() async {
    if (_locking || !_session.isAuthenticated) {
      return;
    }
    _locking = true;
    _cancelTimer();
    try {
      await _unlock.lock();
      final onLocked = _onLocked;
      if (onLocked != null) {
        onLocked();
        return;
      }
      Get.offAllNamed(AppRoutes.authLogin);
    } finally {
      _locking = false;
    }
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }
}
