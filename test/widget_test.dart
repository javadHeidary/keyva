import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:keyva/core/theme/app_responsive.dart';
import 'package:keyva/core/theme/app_theme.dart';

void main() {
  testWidgets('app theme boots without Hive', (tester) async {
    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.light,
        home: const SizedBox(key: Key('theme-smoke')),
        builder: (context, child) {
          AppResponsive.init(context);
          return child!;
        },
      ),
    );

    expect(find.byKey(const Key('theme-smoke')), findsOneWidget);
  });
}
