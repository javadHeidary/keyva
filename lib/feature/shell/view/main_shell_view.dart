import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keyva/feature/category/view/category_list_view.dart';
import 'package:keyva/feature/home/view/home_view.dart';
import 'package:keyva/feature/password_generator/view/password_generator_view.dart';
import 'package:keyva/feature/settings/view/settings_view.dart';
import 'package:keyva/feature/shell/viewmodel/main_shell_viewmodel.dart';
import 'package:keyva/feature/shell/widget/keyva_bottom_navigation_bar.dart';

class MainShellView extends GetView<MainShellController> {
  const MainShellView({super.key});

  static const _navItems = [
    KeyvaBottomNavItem(
      label: 'خانه',

      icon: Icons.home_outlined,

      selectedIcon: Icons.home_rounded,
    ),

    KeyvaBottomNavItem(
      label: 'تولید رمز',

      icon: Icons.password_outlined,

      selectedIcon: Icons.password_rounded,
    ),

    KeyvaBottomNavItem(
      label: 'دسته‌بندی‌ها',

      icon: Icons.folder_outlined,

      selectedIcon: Icons.folder_rounded,
    ),

    KeyvaBottomNavItem(
      label: 'تنظیمات',

      icon: Icons.settings_outlined,

      selectedIcon: Icons.settings_rounded,
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
