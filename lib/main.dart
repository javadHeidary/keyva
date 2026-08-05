import 'package:flutter/material.dart';
import 'package:get/route_manager.dart';
import 'package:keyva/core/theme/app_responsive.dart';
import 'package:keyva/core/theme/app_theme.dart';
import 'package:keyva/core/theme/design_system_template_grok.dart';

void main() {
  runApp(KeyvaApp());
}

class KeyvaApp extends StatelessWidget {
  const KeyvaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Keyva',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      // initialRoute: Routes.home,
      // getPages: AppPages.routes,
      home: const ThemeDemoPage(),
      builder: (context, child) {
        AppScreen.init(context);
        return child!;
      },
    );
  }
}
