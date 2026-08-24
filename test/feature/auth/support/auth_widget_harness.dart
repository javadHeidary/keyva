import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:keyva/core/di/injection_container.dart';
import 'package:keyva/core/routes/app_routing.dart';
import 'package:keyva/core/routes/session_guard.dart';
import 'package:keyva/core/theme/app_responsive.dart';
import 'package:keyva/core/theme/app_theme.dart';
import 'package:keyva/feature/auth/repository/auth_repository.dart';
import 'package:keyva/feature/auth/view/account_selection_view.dart';
import 'package:keyva/feature/auth/view/auth_login_view.dart';
import 'package:keyva/feature/auth/view/auth_register_view.dart';
import 'package:keyva/feature/auth/view_model/account_selection_viewmodel.dart';
import 'package:keyva/feature/auth/view_model/auth_login_viewmodel.dart';
import 'package:keyva/feature/auth/view_model/auth_register_viewmodel.dart';

Widget authTestApp({
  required String initialRoute,
  required LoginController login,
  RegisterController? register,
  List<GetPage>? extraPages,
}) {
  void bindAccounts() {
    if (!Get.isRegistered<AccountSelectionViewModel>()) {
      Get.put(AccountSelectionViewModel(auth: getIt<AuthRepository>()));
    }
  }

  void bindUnlock() {
    if (!Get.isRegistered<LoginController>()) {
      Get.put(login);
    }
  }

  void bindRegister() {
    final controller = register;
    if (controller == null) {
      return;
    }
    if (!Get.isRegistered<RegisterController>()) {
      Get.put(controller);
    }
  }

  return GetMaterialApp(
    theme: AppTheme.light,
    darkTheme: AppTheme.dark,
    locale: const Locale('fa', 'IR'),
    initialRoute: initialRoute,
    getPages: [
      GetPage(
        name: AppRoutes.authLogin,
        page: () => const AccountSelectionView(),
        binding: BindingsBuilder(bindAccounts),
        middlewares: [UnlockedRedirectMiddleware()],
        transition: Transition.noTransition,
      ),
      GetPage(
        name: AppRoutes.authAccounts,
        page: () => const AccountSelectionView(),
        binding: BindingsBuilder(bindAccounts),
        middlewares: [UnlockedRedirectMiddleware()],
        transition: Transition.noTransition,
      ),
      GetPage(
        name: AppRoutes.authUnlock,
        page: () => const AuthLoginView(),
        binding: BindingsBuilder(bindUnlock),
        middlewares: [UnlockedRedirectMiddleware()],
        transition: Transition.noTransition,
      ),
      GetPage(
        name: AppRoutes.authRegister,
        page: () => const AuthRegisterView(),
        binding: BindingsBuilder(bindRegister),
        middlewares: [UnlockedRedirectMiddleware()],
        transition: Transition.noTransition,
      ),
      GetPage(
        name: AppRoutes.shell,
        page: () => const Scaffold(
          key: Key('shell-page'),
          body: SizedBox.shrink(),
        ),
        middlewares: [SessionGuard()],
        transition: Transition.noTransition,
      ),
      GetPage(
        name: AppRoutes.home,
        page: () => const Scaffold(
          key: Key('home-page'),
          body: SizedBox.shrink(),
        ),
        middlewares: [SessionGuard()],
        transition: Transition.noTransition,
      ),
      ...?extraPages,
    ],
    builder: (context, child) {
      AppResponsive.init(context);
      return Directionality(
        textDirection: TextDirection.rtl,
        child: child!,
      );
    },
  );
}

void setupAuthWidgetSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.75;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> pumpAuthFrame(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

Future<void> pumpAuthSettle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}
