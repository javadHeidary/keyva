import 'package:get/get_navigation/src/routes/get_route.dart';
import 'package:keyva/core/theme/design_system_example.dart';
import 'package:keyva/feature/auth/bindings/auth_bindings.dart';
import 'package:keyva/feature/auth/view/auth_login_view.dart';
import 'package:keyva/feature/auth/view/auth_register_view.dart';
import 'package:keyva/feature/home/bindings/home_bindings.dart';
import 'package:keyva/feature/home/view/home_view.dart';
import 'package:keyva/feature/onboarding/bindings/onboarding_bindings.dart';
import 'package:keyva/feature/onboarding/view/onboarding_view.dart';
import 'package:keyva/feature/splash/view/splash_view.dart';
import 'package:keyva/feature/widget_builder_test.dart';

class AppRoutes {
  static const String themeDemo = '/theme-demo';
  static const String splash = '/splash';
  static const String onBoarding = '/on-boarding';
  static const String authLogin = '/authLogin';
  static const String authRegister = '/authRegister';
  static const String widgetBuilderTest = '/widgetBuilderTest';
  static const String home = '/home';

  static List<GetPage> routes = [
    GetPage(name: themeDemo, page: () => const ThemeDemoPage()),
    GetPage(name: splash, page: () => const SplashView()),
    GetPage(
      name: onBoarding,
      page: () => const OnboardingView(),
      binding: OnboardingBindings(),
    ),
    GetPage(
      name: authLogin,
      page: () => const AuthLoginView(),
      binding: AuthBindings(),
    ),
    GetPage(
      name: authRegister,
      page: () => const AuthRegisterView(),
      binding: AuthBindings(),
    ),
    GetPage(name: widgetBuilderTest, page: () => const WidgetBuilderTest()),
    GetPage(name: home, page: () => const HomeView(), binding: HomeBindings()),
  ];
}
