import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:keyva/core/exceptions/app_failure.dart';
import 'package:keyva/feature/type/login/view/login_create_view.dart';
import 'package:keyva/feature/type/login/view/login_edit_view.dart';
import 'package:keyva/feature/type/login/viewmodel/login_create_viewmodel.dart';
import 'package:keyva/feature/type/login/viewmodel/login_edit_viewmodel.dart';
import 'package:keyva/feature/vault/model/login_item.dart';
import 'package:keyva/feature/vault/model/vault_data.dart';
import 'package:keyva/feature/vault/viewmodel/vault_home_viewmodel.dart';
import 'package:keyva/feature/vault/viewmodel/vault_item_viewmodel.dart';
import 'package:keyva/feature/vault/viewmodel/vault_ui_status.dart';

import 'support/fake_vault_operation_service.dart';
import 'support/vault_widget_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeVaultOperationService operations;
  late VaultItemViewModel items;

  final createdAt = DateTime.utc(2026, 7, 1, 10);
  final updatedAt = DateTime.utc(2026, 7, 2, 11);

  LoginItem existingLogin() {
    return LoginItem(
      id: 'login-1',
      title: 'Mail',
      username: 'keep-this-user',
      password: 'keep-this-password',
      website: 'https://mail.test',
      notes: null,
      categoryId: null,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  setUp(() {
    Get.testMode = true;
    operations = FakeVaultOperationService();
    items = VaultItemViewModel(operations: operations);
    Get.put(items);
  });

  tearDown(Get.reset);

  Future<void> pumpCreate(WidgetTester tester) async {
    setupVaultWidgetSurface(tester);
    Get.put(LoginCreateViewModel(items: items));
    await tester.pumpWidget(vaultTestApp(home: const LoginCreateView()));
    await pumpVaultFrame(tester);
  }

  Future<void> fillRequiredLoginFields(WidgetTester tester) async {
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Work Mail');
    await tester.enterText(fields.at(2), 'user@test.com');
    await tester.enterText(fields.at(3), 'secret-pass');
  }

  testWidgets('create form fields render', (tester) async {
    await pumpCreate(tester);

    expect(find.text('ایجاد ورود'), findsWidgets);
    expect(find.text('نام اپلیکیشن'), findsOneWidget);
    expect(find.text('نام کاربری / ایمیل'), findsOneWidget);
    expect(find.text('رمز عبور'), findsOneWidget);
    expect(find.text('آدرس وب'), findsOneWidget);
  });

  testWidgets('validation errors render', (tester) async {
    await pumpCreate(tester);

    await tester.scrollUntilVisible(
      find.byKey(const Key('vault-form-submit')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('vault-form-submit')));
    await pumpVaultFrame(tester);

    expect(find.text('عنوان ورود الزامی است'), findsOneWidget);
    expect(find.text('نام کاربری الزامی است'), findsOneWidget);
    expect(find.text('رمز عبور الزامی است'), findsOneWidget);
    expect(operations.addCount, 0);
  });

  testWidgets('submitting state renders', (tester) async {
    operations.addGate = Completer<void>();
    await pumpCreate(tester);

    await fillRequiredLoginFields(tester);

    await tester.scrollUntilVisible(
      find.byKey(const Key('vault-form-submit')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('vault-form-submit')));
    await tester.pump();

    expect(items.status.value, VaultUiStatus.submitting);
    expect(find.byKey(const Key('vault-form-submit')), findsOneWidget);

    operations.addGate!.complete();
    await pumpVaultFrame(tester);
  });

  testWidgets('successful submission completes correctly', (tester) async {
    operations.vault = VaultData(
      version: VaultData.currentVersion,
      logins: const [],
      bankCards: const [],
      secureNotes: const [],
      categories: const [],
    );
    await pumpCreate(tester);

    await fillRequiredLoginFields(tester);

    await tester.scrollUntilVisible(
      find.byKey(const Key('vault-form-submit')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('vault-form-submit')));
    await pumpVaultFrame(tester);

    expect(operations.addCount, 1);
    expect(items.status.value, VaultUiStatus.success);
    expect(operations.lastAdded, isA<LoginItem>());
    final added = operations.lastAdded! as LoginItem;
    expect(added.title, 'Work Mail');
    expect(added.username, 'user@test.com');
    expect(added.password, 'secret-pass');
  });

  testWidgets('failure state renders correctly', (tester) async {
    operations.addFailure = const CryptoFailure();
    await pumpCreate(tester);

    await fillRequiredLoginFields(tester);

    await tester.scrollUntilVisible(
      find.byKey(const Key('vault-form-submit')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('vault-form-submit')));
    await pumpVaultFrame(tester);

    expect(find.byKey(const Key('vault-form-error')), findsOneWidget);
    expect(find.textContaining('CryptoException'), findsNothing);
    expect(find.text('ایجاد ورود'), findsWidgets);
  });

  testWidgets('edit form hydrates fields from the loaded vault item', (tester) async {
    final home = VaultHomeViewModel(operations: operations);
    operations.vault = VaultData(
      version: VaultData.currentVersion,
      logins: [existingLogin()],
      bankCards: const [],
      secureNotes: const [],
      categories: const [],
    );
    await home.loadVault();
    Get.put(home);
    Get.put(LoginEditViewModel(loginId: 'login-1', items: items));

    setupVaultWidgetSurface(tester);
    await tester.pumpWidget(vaultTestApp(home: const LoginEditView()));
    await pumpVaultFrame(tester);

    expect(find.text('ویرایش ورود'), findsWidgets);
    expect(find.text('Mail'), findsOneWidget);
    expect(find.text('keep-this-user'), findsOneWidget);
    expect(find.text('https://mail.test'), findsOneWidget);
  });
}
