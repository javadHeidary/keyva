import 'package:flutter/material.dart';
import 'package:get/get_navigation/src/routes/get_route.dart';
import 'package:get/get_navigation/src/routes/route_middleware.dart';
import 'package:get/get_navigation/src/routes/transitions_type.dart';
import 'package:keyva/core/routes/session_guard.dart';
import 'package:keyva/core/theme/design_system_example.dart';
import 'package:keyva/feature/auth/bindings/auth_bindings.dart';
import 'package:keyva/feature/auth/view/auth_login_view.dart';
import 'package:keyva/feature/auth/view/auth_register_view.dart';
import 'package:keyva/feature/category/bindings/category_bindings.dart';
import 'package:keyva/feature/category/view/category_create_view.dart';
import 'package:keyva/feature/category/view/category_edit_view.dart';
import 'package:keyva/feature/home/bindings/home_bindings.dart';
import 'package:keyva/feature/home/view/home_view.dart';
import 'package:keyva/feature/home/view/type_list_item_view.dart';
import 'package:keyva/feature/onboarding/bindings/onboarding_bindings.dart';
import 'package:keyva/feature/onboarding/view/onboarding_view.dart';
import 'package:keyva/feature/password_generator/bindings/password_generator_bindings.dart';
import 'package:keyva/feature/password_generator/view/password_history_view.dart';
import 'package:keyva/feature/search/bindings/search_bindings.dart';
import 'package:keyva/feature/shell/bindings/main_shell_bindings.dart';
import 'package:keyva/feature/shell/view/main_shell_view.dart';
import 'package:keyva/feature/splash/bindings/splash_bindings.dart';
import 'package:keyva/feature/splash/view/splash_view.dart';
import 'package:keyva/feature/type/bank_card/bindings/bank_card_bindings.dart';
import 'package:keyva/feature/type/bank_card/view/bank_card_create_view.dart';
import 'package:keyva/feature/type/bank_card/view/bank_card_details_view.dart';
import 'package:keyva/feature/type/bank_card/view/bank_card_edit_view.dart';
import 'package:keyva/feature/type/login/bindings/login_bindings.dart';
import 'package:keyva/feature/type/login/view/login_create_view.dart';
import 'package:keyva/feature/type/login/view/login_details_view.dart';
import 'package:keyva/feature/type/login/view/login_edit_view.dart';
import 'package:keyva/feature/type/note/bindings/note_bindings.dart';
import 'package:keyva/feature/type/note/view/note_create_view.dart';
import 'package:keyva/feature/type/note/view/note_details_view.dart';
import 'package:keyva/feature/type/note/view/note_edit_view.dart';
import 'package:keyva/shared/icons/app_icon_test.dart';
import 'package:keyva/shared/widget/app_search_widget.dart';

class AppRoutes {
  static const Transition _pageTransition = Transition.rightToLeft;
  static const Curve _pageCurve = Curves.easeOutCubic;
  static const Duration _pageTransitionDuration = Duration(milliseconds: 300);

  static const String themeDemo = '/theme-demo';
  static const String splash = '/splash';
  static const String onBoarding = '/on-boarding';
  static const String authLogin = '/authLogin';
  static const String authRegister = '/authRegister';
  static const String widgetBuilderTest = '/widgetBuilderTest';
  static const String shell = '/shell';

  static const String home = '/home';
  static const String typeList = '/type-list';
  static const String search = '/search';
  static const String loginCreate = '/login/create';
  static const String loginEdit = '/login/edit';
  static const String loginDetails = '/login/details';
  static const String bankCardCreate = '/bank-card/create';
  static const String bankCardEdit = '/bank-card/edit';
  static const String bankCardDetails = '/bank-card/details';
  static const String noteCreate = '/note/create';
  static const String noteEdit = '/note/edit';
  static const String noteDetails = '/note/details';
  static const String passwordGenerator = '/password-generator';
  static const String passwordGeneratorHistory = '/password-generator/history';
  static const String settings = '/settings';
  static const String categoryCreate = '/category/create';
  static const String categoryEdit = '/category/edit';
  static const String appIconTest = '/app-icon-test';

  static final _sessionGuard = <GetMiddleware>[SessionGuard()];
  static final _unlockedRedirect = <GetMiddleware>[
    UnlockedRedirectMiddleware(),
  ];

  static List<GetPage> routes = [
    GetPage(
      name: themeDemo,
      page: () => const ThemeDemoPage(),
      transition: _pageTransition,
      curve: _pageCurve,
      transitionDuration: _pageTransitionDuration,
    ),

    GetPage(
      name: splash,
      page: () => const SplashView(),
      binding: SplashBindings(),
      transition: _pageTransition,
      curve: _pageCurve,
      transitionDuration: _pageTransitionDuration,
    ),

    GetPage(
      name: appIconTest,
      page: () => const AppIconTestPage(),
      transition: _pageTransition,
      curve: _pageCurve,
      transitionDuration: _pageTransitionDuration,
    ),

    GetPage(
      name: onBoarding,
      page: () => const OnboardingView(),
      binding: OnboardingBindings(),
      transition: _pageTransition,
      curve: _pageCurve,
      transitionDuration: _pageTransitionDuration,
    ),

    GetPage(
      name: authLogin,
      page: () => const AuthLoginView(),
      binding: AuthBindings(),
      middlewares: _unlockedRedirect,
      transition: _pageTransition,
      curve: _pageCurve,
      transitionDuration: _pageTransitionDuration,
    ),

    GetPage(
      name: authRegister,
      page: () => const AuthRegisterView(),
      binding: AuthBindings(),
      middlewares: _unlockedRedirect,
      transition: _pageTransition,
      curve: _pageCurve,
      transitionDuration: _pageTransitionDuration,
    ),

    GetPage(
      name: shell,
      page: () => const MainShellView(),
      binding: MainShellBindings(),
      middlewares: _sessionGuard,
      transition: _pageTransition,
      curve: _pageCurve,
      transitionDuration: _pageTransitionDuration,
    ),
    GetPage(
      name: home,
      page: () => const HomeView(),
      binding: HomeBindings(),
      middlewares: _sessionGuard,
      transition: _pageTransition,
      curve: _pageCurve,
      transitionDuration: _pageTransitionDuration,
    ),
    GetPage(
      name: typeList,
      page: () => const TypeListItemView(),
      binding: HomeBindings(),
      middlewares: _sessionGuard,
      transition: _pageTransition,
      curve: _pageCurve,
      transitionDuration: _pageTransitionDuration,
    ),
    GetPage(
      name: search,
      page: () => const AppSearchWidget(),
      binding: SearchBindings(),
      middlewares: _sessionGuard,
      transition: _pageTransition,
      curve: _pageCurve,
      transitionDuration: _pageTransitionDuration,
    ),

    // -------------------------------------------------------------------------
    // Login
    // -------------------------------------------------------------------------
    GetPage(
      name: loginCreate,
      page: () => const LoginCreateView(),
      binding: LoginCreateBindings(),
      middlewares: _sessionGuard,
      transition: _pageTransition,
      curve: _pageCurve,
      transitionDuration: _pageTransitionDuration,
    ),

    GetPage(
      name: loginEdit,
      page: () => const LoginEditView(),
      binding: LoginEditBindings(),
      middlewares: _sessionGuard,
      transition: _pageTransition,
      curve: _pageCurve,
      transitionDuration: _pageTransitionDuration,
    ),

    GetPage(
      name: loginDetails,
      page: () => const LoginDetailsView(),
      binding: LoginDetailsBindings(),
      middlewares: _sessionGuard,
      transition: _pageTransition,
      curve: _pageCurve,
      transitionDuration: _pageTransitionDuration,
    ),

    // -------------------------------------------------------------------------
    // Bank Card
    // -------------------------------------------------------------------------
    GetPage(
      name: bankCardCreate,
      page: () => const BankCardCreateView(),
      binding: BankCardCreateBindings(),
      middlewares: _sessionGuard,
      transition: _pageTransition,
      curve: _pageCurve,
      transitionDuration: _pageTransitionDuration,
    ),

    GetPage(
      name: bankCardEdit,
      page: () => const BankCardEditView(),
      binding: BankCardEditBindings(),
      middlewares: _sessionGuard,
      transition: _pageTransition,
      curve: _pageCurve,
      transitionDuration: _pageTransitionDuration,
    ),

    GetPage(
      name: bankCardDetails,
      page: () => const BankCardDetailsView(),
      binding: BankCardDetailsBindings(),
      middlewares: _sessionGuard,
      transition: _pageTransition,
      curve: _pageCurve,
      transitionDuration: _pageTransitionDuration,
    ),

    // -------------------------------------------------------------------------
    // Note
    // -------------------------------------------------------------------------
    GetPage(
      name: noteCreate,
      page: () => const NoteCreateView(),
      binding: NoteCreateBindings(),
      middlewares: _sessionGuard,
      transition: _pageTransition,
      curve: _pageCurve,
      transitionDuration: _pageTransitionDuration,
    ),

    GetPage(
      name: noteEdit,
      page: () => const NoteEditView(),
      binding: NoteEditBindings(),
      middlewares: _sessionGuard,
      transition: _pageTransition,
      curve: _pageCurve,
      transitionDuration: _pageTransitionDuration,
    ),

    GetPage(
      name: noteDetails,
      page: () => const NoteDetailsView(),
      binding: NoteDetailsBindings(),
      middlewares: _sessionGuard,
      transition: _pageTransition,
      curve: _pageCurve,
      transitionDuration: _pageTransitionDuration,
    ),

    // -------------------------------------------------------------------------
    // Password Generator
    // -------------------------------------------------------------------------
    GetPage(
      name: passwordGeneratorHistory,
      page: () => const PasswordHistoryView(),
      binding: PasswordHistoryBindings(),
      middlewares: _sessionGuard,
      transition: _pageTransition,
      curve: _pageCurve,
      transitionDuration: _pageTransitionDuration,
    ),

    // -------------------------------------------------------------------------
    // Category
    // -------------------------------------------------------------------------
    GetPage(
      name: categoryCreate,
      page: () => const CategoryCreateView(),
      binding: CategoryCreateBindings(),
      middlewares: _sessionGuard,
      transition: _pageTransition,
      curve: _pageCurve,
      transitionDuration: _pageTransitionDuration,
    ),

    GetPage(
      name: categoryEdit,
      page: () => const CategoryEditView(),
      binding: CategoryEditBindings(),
      middlewares: _sessionGuard,
      transition: _pageTransition,
      curve: _pageCurve,
      transitionDuration: _pageTransitionDuration,
    ),
  ];
}
