import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:keyva/core/theme/app_colors.dart';
import 'package:keyva/core/theme/app_sizes.dart';
import 'package:keyva/core/theme/app_spacing.dart';
import 'package:keyva/core/theme/extensions/responsive_extentions.dart';
import 'package:keyva/feature/search/viewmodel/search_viewmodel.dart';
import 'package:keyva/shared/icons/app_icons.dart';
import 'package:keyva/shared/widget/app_header_widget.dart';
import 'package:keyva/shared/widget/app_search_widget.dart';

import '../vault/support/vault_widget_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.testMode = true;
    Get.put(SearchViewModel());
  });

  tearDown(Get.reset);

  Future<void> pumpSearch(
    WidgetTester tester, {
    ThemeMode themeMode = ThemeMode.light,
    Size physicalSize = const Size(1080, 2400),
    double devicePixelRatio = 2.75,
    double topPadding = 82.5,
  }) async {
    tester.view.physicalSize = physicalSize;
    tester.view.devicePixelRatio = devicePixelRatio;
    tester.view.padding = FakeViewPadding(top: topPadding);
    tester.view.viewPadding = FakeViewPadding(top: topPadding);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);

    await tester.pumpWidget(
      vaultTestApp(home: const AppSearchWidget(), themeMode: themeMode),
    );
    await pumpVaultFrame(tester);
    await tester.pump(const Duration(milliseconds: 350));
  }

  testWidgets('search uses AppHeaderWidget inside SafeArea', (tester) async {
    await pumpSearch(tester);

    expect(find.byType(SafeArea), findsWidgets);
    expect(find.byType(AppHeaderWidget), findsOneWidget);
    expect(find.byKey(const Key('vault-search-field')), findsOneWidget);

    final header = tester.widget<AppHeaderWidget>(find.byType(AppHeaderWidget));
    expect(header.padding, isNull);

    final headerPadding = tester
        .widget<Container>(
          find
              .descendant(
                of: find.byType(AppHeaderWidget),
                matching: find.byType(Container),
              )
              .first,
        )
        .padding;

    expect(
      headerPadding,
      EdgeInsets.symmetric(horizontal: 16.s, vertical: 12.s),
    );
    expect(
      headerPadding,
      isNot(
        EdgeInsets.fromLTRB(
          AppSpacing.lg.s,
          AppSpacing.sm.h,
          AppSpacing.lg.s,
          AppSpacing.sm.h,
        ),
      ),
    );
  });

  testWidgets('search header icons match shared header sizing', (tester) async {
    await pumpSearch(tester);

    final backIcon = tester.widget<Icon>(find.byIcon(AppIcon.arrowBack));
    expect(backIcon.size, AppSizes.iconLg.s);

    final searchIcons = tester.widgetList<Icon>(
      find.descendant(
        of: find.byType(TextField),
        matching: find.byIcon(AppIcon.search),
      ),
    );
    expect(searchIcons, isNotEmpty);
    expect(searchIcons.first.size, 22.s);
  });

  testWidgets('RTL places back control to the right of the search field', (
    tester,
  ) async {
    await pumpSearch(tester);

    final backDx = tester.getCenter(find.byIcon(AppIcon.arrowBack)).dx;
    final fieldDx = tester
        .getCenter(find.byKey(const Key('vault-search-field')))
        .dx;

    expect(backDx, greaterThan(fieldDx));
  });

  testWidgets('SafeArea keeps header below status bar on default size', (
    tester,
  ) async {
    await pumpSearch(tester);

    final statusBarHeight =
        tester.view.padding.top / tester.view.devicePixelRatio;
    final headerTop = tester.getTopLeft(find.byType(AppHeaderWidget)).dy;

    expect(headerTop, closeTo(statusBarHeight, 0.5));
  });

  testWidgets('SafeArea keeps header below status bar on a smaller surface', (
    tester,
  ) async {
    await pumpSearch(
      tester,
      physicalSize: const Size(720, 1280),
      devicePixelRatio: 2.0,
      topPadding: 60,
    );

    final statusBarHeight =
        tester.view.padding.top / tester.view.devicePixelRatio;
    final headerTop = tester.getTopLeft(find.byType(AppHeaderWidget)).dy;

    expect(headerTop, closeTo(statusBarHeight, 0.5));
    expect(
      tester
          .widget<Container>(
            find
                .descendant(
                  of: find.byType(AppHeaderWidget),
                  matching: find.byType(Container),
                )
                .first,
          )
          .padding,
      EdgeInsets.symmetric(horizontal: 16.s, vertical: 12.s),
    );
  });

  testWidgets('light theme uses page background', (tester) async {
    await pumpSearch(tester);

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, AppColors.pageBackgroundLight);
  });

  testWidgets('dark theme uses page background', (tester) async {
    await pumpSearch(tester, themeMode: ThemeMode.dark);

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, AppColors.pageBackgroundDark);
  });
}
