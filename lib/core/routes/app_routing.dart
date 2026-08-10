import 'package:get/get_navigation/src/routes/get_route.dart';
import 'package:keyva/core/theme/design_system_example.dart';
import 'package:keyva/feature/auth/bindings/auth_bindings.dart';
import 'package:keyva/feature/auth/view/auth_login_view.dart';
import 'package:keyva/feature/auth/view/auth_register_view.dart';
import 'package:keyva/feature/category/bindings/category_bindings.dart';
import 'package:keyva/feature/category/view/category_create_view.dart';
import 'package:keyva/feature/home/bindings/home_bindings.dart';
import 'package:keyva/feature/shell/bindings/main_shell_bindings.dart';
import 'package:keyva/feature/shell/view/main_shell_view.dart';
import 'package:keyva/feature/home/view/type_list_item_view.dart';
import 'package:keyva/feature/onboarding/bindings/onboarding_bindings.dart';
import 'package:keyva/feature/onboarding/view/onboarding_view.dart';
import 'package:keyva/feature/splash/view/splash_view.dart';
import 'package:keyva/feature/type/login/bindings/login_bindings.dart';
import 'package:keyva/feature/type/login/view/login_create_view.dart';
import 'package:keyva/feature/type/login/view/login_details_view.dart';
import 'package:keyva/feature/type/login/view/login_edit_view.dart';
import 'package:keyva/feature/type/bank_card/bindings/bank_card_bindings.dart';
import 'package:keyva/feature/type/bank_card/view/bank_card_create_view.dart';
import 'package:keyva/feature/type/bank_card/view/bank_card_details_view.dart';
import 'package:keyva/feature/type/bank_card/view/bank_card_edit_view.dart';
import 'package:keyva/feature/type/note/bindings/note_bindings.dart';
import 'package:keyva/feature/type/note/view/note_create_view.dart';
import 'package:keyva/feature/type/note/view/note_details_view.dart';
import 'package:keyva/feature/type/note/view/note_edit_view.dart';
import 'package:keyva/feature/password_generator/bindings/password_generator_bindings.dart';
import 'package:keyva/feature/password_generator/view/password_generator_view.dart';
import 'package:keyva/feature/password_generator/view/password_history_view.dart';
import 'package:keyva/feature/settings/bindings/settings_bindings.dart';
import 'package:keyva/feature/settings/view/settings_view.dart';
import 'package:keyva/feature/widget_builder_test.dart';

class AppRoutes {
  static const String themeDemo = '/theme-demo';
  static const String splash = '/splash';
  static const String onBoarding = '/on-boarding';
  static const String authLogin = '/authLogin';
  static const String authRegister = '/authRegister';
  static const String widgetBuilderTest = '/widgetBuilderTest';
  static const String home = '/home';
  static const String typeList = '/type-list';
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
    GetPage(
      name: home,
      page: () => const MainShellView(),
      binding: MainShellBindings(),
    ),
    GetPage(
      name: typeList,
      page: () => const TypeListItemView(),
      binding: HomeBindings(),
    ),
    GetPage(
      name: loginCreate,
      page: () => const LoginCreateView(),
      binding: LoginCreateBindings(),
    ),
    GetPage(
      name: loginEdit,
      page: () => const LoginEditView(),
      binding: LoginEditBindings(),
    ),
    GetPage(
      name: loginDetails,
      page: () => const LoginDetailsView(),
      binding: LoginDetailsBindings(),
    ),
    GetPage(
      name: bankCardCreate,
      page: () => const BankCardCreateView(),
      binding: BankCardCreateBindings(),
    ),
    GetPage(
      name: bankCardEdit,
      page: () => const BankCardEditView(),
      binding: BankCardEditBindings(),
    ),
    GetPage(
      name: bankCardDetails,
      page: () => const BankCardDetailsView(),
      binding: BankCardDetailsBindings(),
    ),
    GetPage(
      name: noteCreate,
      page: () => const NoteCreateView(),
      binding: NoteCreateBindings(),
    ),
    GetPage(
      name: noteEdit,
      page: () => const NoteEditView(),
      binding: NoteEditBindings(),
    ),
    GetPage(
      name: noteDetails,
      page: () => const NoteDetailsView(),
      binding: NoteDetailsBindings(),
    ),
    GetPage(
      name: passwordGenerator,
      page: () => const PasswordGeneratorView(),
      binding: PasswordGeneratorBindings(),
    ),
    GetPage(
      name: passwordGeneratorHistory,
      page: () => const PasswordHistoryView(),
      binding: PasswordHistoryBindings(),
    ),
    GetPage(
      name: settings,
      page: () => const SettingsView(),
      binding: SettingsBindings(),
    ),
    GetPage(
      name: categoryCreate,
      page: () => const CategoryCreateView(),
      binding: CategoryCreateBindings(),
    ),
    GetPage(
      name: categoryEdit,
      page: () => const CategoryEditView(),
      binding: CategoryEditBindings(),
    ),
  ];
}
