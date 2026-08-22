import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:keyva/core/security/auto_lock_policy.dart';
import 'package:keyva/core/session/app_lock_controller.dart';
import 'package:keyva/core/session/privacy_overlay.dart';
import 'package:keyva/core/session/session_service_impl.dart';
import 'package:keyva/core/theme/app_theme.dart';
import 'package:keyva/feature/vault/model/bank_card_item.dart';
import 'package:keyva/feature/vault/model/category_item.dart';
import 'package:keyva/feature/vault/model/login_item.dart';
import 'package:keyva/feature/vault/model/secure_note_item.dart';
import 'package:keyva/feature/vault/model/vault_data.dart';
import 'package:keyva/feature/vault/session/vault_session_impl.dart';

import '../../feature/auth/support/fake_auth_repository.dart';
import '../../feature/auth/support/fake_vault_unlock_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SessionServiceImpl session;
  late FakeVaultUnlockService unlock;
  late FakeAuthRepository auth;
  late AppLockController lock;
  late VaultSessionImpl vaultSession;
  late VaultData vault;

  setUp(() async {
    Get.testMode = true;
    session = SessionServiceImpl();
    session.setAuthenticated(
      userId: 'user-1',
      username: 'test',
      vaultKey: Uint8List(32),
    );
    unlock = FakeVaultUnlockService(session: session);
    auth = FakeAuthRepository()..autoLockTimeout = AutoLockPolicy.oneMinute;
    lock = AppLockController(
      session: session,
      unlock: unlock,
      auth: auth,
      clock: () => DateTime.utc(2026, 8, 22, 12),
      startTimer: (duration, callback) => _FakeTimer(),
      onLocked: () {},
      observeBinding: false,
    );
    vault = _sampleVault();
    vaultSession = VaultSessionImpl();
    await vaultSession.unlock(vault);
  });

  tearDown(() {
    lock.onClose();
    Get.reset();
  });

  Future<void> pumpOverlay(
    WidgetTester tester, {
    ThemeMode themeMode = ThemeMode.light,
  }) {
    return tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: themeMode,
        home: PrivacyOverlayLayer(
          controller: lock,
          child: const Scaffold(body: Center(child: Text('secret-item'))),
        ),
      ),
    );
  }

  testWidgets('app starts in the foreground with the overlay hidden', (
    tester,
  ) async {
    await pumpOverlay(tester);

    expect(find.byKey(PrivacyOverlay.overlayKey), findsNothing);
    expect(find.text('secret-item'), findsOneWidget);
    expect(find.text('secret-item').hitTestable(), findsOneWidget);
  });

  testWidgets('inactive shows the overlay', (tester) async {
    await pumpOverlay(tester);

    lock.handleLifecycle(AppLifecycleState.inactive);
    await tester.pump();

    expect(find.byKey(PrivacyOverlay.overlayKey), findsOneWidget);
  });

  testWidgets('paused shows the overlay', (tester) async {
    await pumpOverlay(tester);

    lock.handleLifecycle(AppLifecycleState.paused);
    await tester.pump();

    expect(find.byKey(PrivacyOverlay.overlayKey), findsOneWidget);
  });

  testWidgets('overlay stays visible until fully resumed', (tester) async {
    await pumpOverlay(tester);

    lock.handleLifecycle(AppLifecycleState.inactive);
    await tester.pump();
    lock.handleLifecycle(AppLifecycleState.paused);
    await tester.pump();
    lock.handleLifecycle(AppLifecycleState.inactive);
    await tester.pump();

    expect(find.byKey(PrivacyOverlay.overlayKey), findsOneWidget);

    lock.handleLifecycle(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump();

    expect(find.byKey(PrivacyOverlay.overlayKey), findsNothing);
  });

  testWidgets('light theme overlay is white', (tester) async {
    await pumpOverlay(tester, themeMode: ThemeMode.light);

    lock.handleLifecycle(AppLifecycleState.paused);
    await tester.pump();

    final box = tester.widget<ColoredBox>(
      find.byKey(PrivacyOverlay.overlayKey),
    );
    expect(box.color, Colors.white);
  });

  testWidgets('dark theme overlay is black', (tester) async {
    await pumpOverlay(tester, themeMode: ThemeMode.dark);

    lock.handleLifecycle(AppLifecycleState.paused);
    await tester.pump();

    final box = tester.widget<ColoredBox>(
      find.byKey(PrivacyOverlay.overlayKey),
    );
    expect(box.color, Colors.black);
  });

  testWidgets('overlay covers sensitive UI without removing it', (
    tester,
  ) async {
    await pumpOverlay(tester);

    lock.handleLifecycle(AppLifecycleState.paused);
    await tester.pump();

    expect(find.text('secret-item'), findsOneWidget);
    expect(find.text('secret-item').hitTestable(), findsNothing);
    expect(
      tester.getSize(find.byKey(PrivacyOverlay.overlayKey)),
      tester.getSize(find.byType(PrivacyOverlayLayer)),
    );
  });

  testWidgets('backgrounding does not mutate VaultSession or SessionService', (
    tester,
  ) async {
    await pumpOverlay(tester);

    lock.handleLifecycle(AppLifecycleState.inactive);
    await tester.pump();
    lock.handleLifecycle(AppLifecycleState.paused);
    await tester.pump();

    expect(unlock.lockCount, 0);
    expect(session.isAuthenticated, isTrue);
    expect(vaultSession.isUnlocked, isTrue);
    expect(identical(vaultSession.vaultData, vault), isTrue);
  });
}

VaultData _sampleVault() {
  final stamp = DateTime.utc(2026, 8, 22);
  return VaultData(
    version: VaultData.currentVersion,
    logins: [
      LoginItem(
        id: 'login-1',
        title: 'Mail',
        username: 'vault-user',
        password: 'session-secret',
        website: 'https://mail.test',
        notes: 'private-note',
        categoryId: 'cat-1',
        createdAt: stamp,
        updatedAt: stamp,
      ),
    ],
    bankCards: [
      BankCardItem(
        id: 'card-1',
        title: 'Primary',
        cardNumber: '6037991234567890',
        cardHolder: 'Ali Reza',
        expiryDate: '12/28',
        cvv: '456',
        bankName: 'Melli',
        notes: null,
        categoryId: 'cat-1',
        createdAt: stamp,
        updatedAt: stamp,
      ),
    ],
    secureNotes: [
      SecureNoteItem(
        id: 'note-1',
        title: 'WiFi',
        content: 'building-code-42',
        categoryId: 'cat-1',
        createdAt: stamp,
        updatedAt: stamp,
      ),
    ],
    categories: [
      CategoryItem(
        id: 'cat-1',
        name: 'Personal',
        icon: 'home',
        createdAt: stamp,
      ),
    ],
  );
}

class _FakeTimer implements Timer {
  @override
  void cancel() {}

  @override
  bool get isActive => false;

  @override
  int get tick => 0;
}
