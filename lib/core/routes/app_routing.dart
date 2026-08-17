import 'package:flutter/material.dart';
import 'package:get/get_navigation/src/routes/get_route.dart';
import 'package:get/get_navigation/src/routes/transitions_type.dart';
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
      transition: _pageTransition,
      curve: _pageCurve,
      transitionDuration: _pageTransitionDuration,
    ),

    GetPage(
      name: authRegister,
      page: () => const AuthRegisterView(),
      binding: AuthBindings(),
      transition: _pageTransition,
      curve: _pageCurve,
      transitionDuration: _pageTransitionDuration,
    ),

    GetPage(
      name: shell,
      page: () => const MainShellView(),
      binding: MainShellBindings(),
      transition: _pageTransition,
      curve: _pageCurve,
      transitionDuration: _pageTransitionDuration,
    ),
    GetPage(
      name: home,
      page: () => const HomeView(),
      binding: HomeBindings(),
      transition: _pageTransition,
      curve: _pageCurve,
      transitionDuration: _pageTransitionDuration,
    ),
    GetPage(
      name: typeList,
      page: () => const TypeListItemView(),
      binding: HomeBindings(),
      transition: _pageTransition,
      curve: _pageCurve,
      transitionDuration: _pageTransitionDuration,
    ),
    GetPage(
      name: search,
      page: () => const AppSearchWidget(),
      binding: SearchBindings(),
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
      transition: _pageTransition,
      curve: _pageCurve,
      transitionDuration: _pageTransitionDuration,
    ),

    GetPage(
      name: loginEdit,
      page: () => const LoginEditView(),
      binding: LoginEditBindings(),
      transition: _pageTransition,
      curve: _pageCurve,
      transitionDuration: _pageTransitionDuration,
    ),

    GetPage(
      name: loginDetails,
      page: () => const LoginDetailsView(),
      binding: LoginDetailsBindings(),
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
      transition: _pageTransition,
      curve: _pageCurve,
      transitionDuration: _pageTransitionDuration,
    ),

    GetPage(
      name: bankCardEdit,
      page: () => const BankCardEditView(),
      binding: BankCardEditBindings(),
      transition: _pageTransition,
      curve: _pageCurve,
      transitionDuration: _pageTransitionDuration,
    ),

    GetPage(
      name: bankCardDetails,
      page: () => const BankCardDetailsView(),
      binding: BankCardDetailsBindings(),
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
      transition: _pageTransition,
      curve: _pageCurve,
      transitionDuration: _pageTransitionDuration,
    ),

    GetPage(
      name: noteEdit,
      page: () => const NoteEditView(),
      binding: NoteEditBindings(),
      transition: _pageTransition,
      curve: _pageCurve,
      transitionDuration: _pageTransitionDuration,
    ),

    GetPage(
      name: noteDetails,
      page: () => const NoteDetailsView(),
      binding: NoteDetailsBindings(),
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
      transition: _pageTransition,
      curve: _pageCurve,
      transitionDuration: _pageTransitionDuration,
    ),

    GetPage(
      name: categoryEdit,
      page: () => const CategoryEditView(),
      binding: CategoryEditBindings(),
      transition: _pageTransition,
      curve: _pageCurve,
      transitionDuration: _pageTransitionDuration,
    ),
  ];
}
