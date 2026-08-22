import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:keyva/core/database/hive_database.dart';
import 'package:keyva/core/di/injection_container.dart';
import 'package:keyva/core/routes/app_routing.dart';
import 'package:keyva/core/security/screen_protection_service.dart';
import 'package:keyva/core/session/app_lock_controller.dart';
import 'package:keyva/core/session/privacy_overlay.dart';
import 'package:keyva/core/session/session_service.dart';
import 'package:keyva/core/theme/app_responsive.dart';
import 'package:keyva/core/theme/app_theme.dart';
import 'package:keyva/feature/auth/repository/auth_repository.dart';
import 'package:keyva/feature/vault/service/vault_unlock_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final database = await HiveDatabase.initialize();
  initDependencies(database);
  await getIt<ScreenProtectionService>().applyPersisted();
  Get.put(
    AppLockController(
      session: getIt<SessionService>(),
      unlock: getIt<VaultUnlockService>(),
      auth: getIt<AuthRepository>(),
    ),
    permanent: true,
  );
  runApp(const KeyvaApp());
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
      initialRoute: AppRoutes.splash,
      getPages: AppRoutes.routes,
      builder: (context, child) {
        AppResponsive.init(context);
        return PrivacyOverlayLayer(child: child ?? const SizedBox.shrink());
      },
    );
  }
}
