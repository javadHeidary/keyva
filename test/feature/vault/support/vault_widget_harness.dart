import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:keyva/core/theme/app_responsive.dart';
import 'package:keyva/core/theme/app_theme.dart';

Widget vaultTestApp({required Widget home, String? initialRoute, List<GetPage>? getPages}) {
  return GetMaterialApp(
    theme: AppTheme.light,
    darkTheme: AppTheme.dark,
    home: getPages == null ? home : null,
    initialRoute: initialRoute,
    getPages: getPages,
    builder: (context, child) {
      AppResponsive.init(context);
      return Directionality(
        textDirection: TextDirection.rtl,
        child: child!,
      );
    },
  );
}

void setupVaultWidgetSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.75;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> pumpVaultFrame(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}
