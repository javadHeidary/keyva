import 'package:get/get_navigation/src/routes/get_route.dart';
import 'package:keyva/core/theme/design_system_example.dart';
import 'package:keyva/feature/splash/view/splash_view.dart';

class AppRoutes {
  static const String splash = '/splash';
  static const String themeDemo = '/theme-demo';
  static List<GetPage> routes = [
    GetPage(name: themeDemo, page: () => const ThemeDemoPage()),
    GetPage(name: splash, page: () => const SplashView()),
  ];
}
