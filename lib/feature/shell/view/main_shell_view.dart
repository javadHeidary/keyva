import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keyva/core/theme/app_sizes.dart';
import 'package:keyva/core/theme/extensions/responsive_extentions.dart';
import 'package:keyva/core/theme/extensions/theme_extentions.dart';
import 'package:keyva/feature/category/view/category_list_view.dart';
import 'package:keyva/feature/home/view/home_view.dart';
import 'package:keyva/feature/shell/viewmodel/main_shell_viewmodel.dart';

class MainShellView extends GetView<MainShellController> {
  const MainShellView({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Obx(() {
      final index = controller.currentIndex.value;

      return Scaffold(
        body: IndexedStack(
          index: index,
          children: const [
            HomeView(),
            CategoryListView(),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: controller.setTab,
          height: AppSizes.bottomNavHeight.h,
          backgroundColor: colors.card,
          indicatorColor: colors.primary.withValues(alpha: 0.12),
          destinations: [
            NavigationDestination(
              icon: Icon(Icons.home_outlined, size: AppSizes.iconMd.s),
              selectedIcon: Icon(Icons.home_rounded, size: AppSizes.iconMd.s),
              label: 'خانه',
            ),
            NavigationDestination(
              icon: Icon(Icons.folder_outlined, size: AppSizes.iconMd.s),
              selectedIcon: Icon(Icons.folder_rounded, size: AppSizes.iconMd.s),
              label: 'دسته‌بندی‌ها',
            ),
          ],
        ),
      );
    });
  }
}
