import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:keyva/core/di/injection_container.dart';
import 'package:keyva/core/session/session_service.dart';

class SessionGuard extends GetMiddleware {
  SessionGuard();

  @override
  RouteSettings? redirect(String? route) {
    if (_isUnlocked) {
      return null;
    }
    return const RouteSettings(name: '/auth/accounts');
  }
}

class UnlockedRedirectMiddleware extends GetMiddleware {
  UnlockedRedirectMiddleware();

  @override
  RouteSettings? redirect(String? route) {
    if (_isUnlocked) {
      return const RouteSettings(name: '/shell');
    }
    return null;
  }
}

bool get _isUnlocked {
  if (!getIt.isRegistered<SessionService>()) {
    return false;
  }
  return getIt<SessionService>().isAuthenticated;
}
