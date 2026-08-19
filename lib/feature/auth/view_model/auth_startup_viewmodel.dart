import 'package:get/get.dart';
import 'package:keyva/core/exceptions/result.dart';
import 'package:keyva/core/routes/app_routing.dart';
import 'package:keyva/core/session/session_service.dart';
import 'package:keyva/feature/auth/repository/auth_repository.dart';

class AuthStartupViewModel extends GetxController {
  AuthStartupViewModel({
    required SessionService session,
    required AuthRepository auth,
  }) : _session = session,
       _auth = auth;

  final SessionService _session;
  final AuthRepository _auth;

  Future<String> resolveInitialRoute() async {
    if (_session.isAuthenticated) {
      return AppRoutes.shell;
    }
    final result = await _auth.hasAnyAccount();
    if (result is FailureResult<bool>) {
      return AppRoutes.authLogin;
    }
    if (result is Success<bool> && result.data) {
      return AppRoutes.authLogin;
    }
    return AppRoutes.onBoarding;
  }
}
