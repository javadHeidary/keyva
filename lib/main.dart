import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
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
      locale: const Locale('fa', 'IR'),
      fallbackLocale: const Locale('fa', 'IR'),
      supportedLocales: const [Locale('fa', 'IR'), Locale('en', 'US')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      initialRoute: AppRoutes.widgetBuilderTest,
      getPages: AppRoutes.routes,

      builder: (context, child) {
        AppResponsive.init(context);
        return child!;
      },
    );
  }
}
