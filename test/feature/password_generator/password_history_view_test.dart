import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:keyva/core/theme/app_responsive.dart';
import 'package:keyva/core/theme/app_theme.dart';
import 'package:keyva/feature/password_generator/data/password_history_store.dart';
import 'package:keyva/feature/password_generator/model/password_history_entry.dart';
import 'package:keyva/feature/password_generator/util/password_history_date_format.dart';
import 'package:keyva/feature/password_generator/view/password_history_view.dart';
import 'package:keyva/feature/password_generator/viewmodel/password_history_viewmodel.dart';
import 'package:keyva/shared/widget/toast_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../auth/support/auth_widget_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final now = DateTime(2026, 8, 23, 12, 0, 0);
  final recentCopiedAt = now.subtract(const Duration(days: 1));
  const recentPassword = 'hist-keep-recent';
  const expiredPassword = 'hist-drop-old';

  setUp(() {
    Get.testMode = true;
  });

  tearDown(() {
    AppToast.dismiss();
    Get.reset();
  });

  Future<void> pumpHistory(WidgetTester tester) async {
    setupAuthWidgetSurface(tester);
    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.light,
        locale: const Locale('fa', 'IR'),
        home: const PasswordHistoryView(),
        builder: (context, child) {
          AppResponsive.init(context);
          return Directionality(
            textDirection: TextDirection.rtl,
            child: child!,
          );
        },
      ),
    );
    await pumpAuthSettle(tester);
  }

  Future<void> bindStoreWithEntries(
    List<PasswordHistoryEntry> entries,
  ) async {
    SharedPreferences.setMockInitialValues({
      PasswordHistoryStore.historyKey: jsonEncode(
        entries.map((e) => e.toJson()).toList(),
      ),
    });
    final store = PasswordHistoryStore(clock: () => now);
    await store.init();
    Get.put(store, permanent: true);
    Get.put(PasswordHistoryViewModel());
  }

  testWidgets('shows remaining Jalali dates after cleanup and hides expired rows', (
    tester,
  ) async {
    await bindStoreWithEntries([
      PasswordHistoryEntry(
        password: expiredPassword,
        copiedAt: now.subtract(const Duration(days: 7, milliseconds: 1)),
      ),
      PasswordHistoryEntry(
        password: recentPassword,
        copiedAt: recentCopiedAt,
      ),
    ]);

    await pumpHistory(tester);

    expect(find.text(recentPassword), findsOneWidget);
    expect(find.text(expiredPassword), findsNothing);
    expect(
      find.text(formatPasswordHistoryCopiedAt(recentCopiedAt)),
      findsOneWidget,
    );
  });

  testWidgets('info icon explains the 7-day retention policy', (tester) async {
    await bindStoreWithEntries(const []);
    await pumpHistory(tester);

    await tester.tap(find.byKey(const Key('password-history-info')));
    await pumpAuthSettle(tester);

    expect(find.text('مدت نگهداری'), findsOneWidget);
    expect(
      find.text(
        'رمزهای قبلی فقط به مدت ۷ روز در تاریخچه نگهداری می‌شوند و پس از آن به‌صورت خودکار حذف خواهند شد.',
      ),
      findsOneWidget,
    );
  });
}
