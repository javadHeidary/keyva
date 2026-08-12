import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keyva/feature/category/view/category_list_view.dart';
import 'package:keyva/feature/home/view/home_view.dart';
import 'package:keyva/feature/password_generator/view/password_generator_view.dart';
import 'package:keyva/feature/settings/view/settings_view.dart';
import 'package:keyva/feature/shell/viewmodel/main_shell_viewmodel.dart';
import 'package:keyva/feature/shell/widget/keyva_bottom_navigation_bar.dart';
import 'package:keyva/shared/icons/app_icons.dart';

class MainShellView extends GetView<MainShellController> {
  const MainShellView({super.key});

  static final _navItems = [
    KeyvaBottomNavItem(
      label: 'خانه',

      icon: AppIcon.home,

      selectedIcon: AppIcon.home,
    ),

    KeyvaBottomNavItem(
      label: 'تولید رمز',

      icon: AppIcon.password,

      selectedIcon: AppIcon.password,
    ),

    KeyvaBottomNavItem(
      label: 'دسته‌بندی‌ها',

      icon: AppIcon.folder,

      selectedIcon: AppIcon.folder,
    ),

    KeyvaBottomNavItem(
      label: 'تنظیمات',

      icon: AppIcon.settings,

      selectedIcon: AppIcon.settings,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final index = controller.currentIndex.value;

      return Scaffold(
        extendBody: true,

        body: Stack(
          fit: StackFit.expand,

          children: [
            IndexedStack(
              index: index,

              children: const [
                HomeView(),
                PasswordGeneratorView(embeddedInShell: true),
                CategoryListView(),
                SettingsView(),
              ],
            ),

            Align(
              alignment: Alignment.bottomCenter,

              child: KeyvaBottomNavigationBar(
                items: _navItems,

                selectedIndex: index,

                onItemSelected: controller.setTab,
              ),
            ),
          ],
        ),
      );
    });
  }
}
