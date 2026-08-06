import 'package:flutter/material.dart';
import 'package:get/route_manager.dart';
import 'package:keyva/core/routes/app_routing.dart';
import 'package:keyva/core/theme/app_responsive.dart';
import 'package:keyva/core/theme/app_theme.dart';

void main() {
  runApp(KeyvaApp());
}

class KeyvaApp extends StatelessWidget {
  const KeyvaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Keyva',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      initialRoute: AppRoutes.splash,
      getPages: AppRoutes.routes,
      builder: (context, child) {
        AppResponsive.init(context);
        return child!;
      },
    );
  }
}
