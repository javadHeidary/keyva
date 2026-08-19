import 'package:get/get.dart';
import 'package:keyva/core/di/injection_container.dart';
import 'package:keyva/core/session/session_service.dart';
import 'package:keyva/feature/auth/repository/auth_repository.dart';
import 'package:keyva/feature/auth/view_model/auth_startup_viewmodel.dart';

class SplashBindings extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => AuthStartupViewModel(
        session: getIt<SessionService>(),
        auth: getIt<AuthRepository>(),
      ),
    );
  }
}
