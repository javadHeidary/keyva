import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keyva/core/di/injection_container.dart';
import 'package:keyva/core/image/cached_remote_image.dart';
import 'package:keyva/feature/home/model/vault_models.dart';
import 'package:keyva/feature/type/login/widget/login_favicon_widget.dart';
import 'package:keyva/feature/vault/model/bank_card_item.dart';
import 'package:keyva/feature/vault/model/login_item.dart';
import 'package:keyva/feature/vault/model/secure_note_item.dart';
import 'package:keyva/feature/vault/view/vault_list_item_icon.dart';
import 'package:keyva/shared/icons/app_icons.dart';

import '../../bank_card_seed_pan_test.dart';
import '../../core/image/fake_cached_remote_image.dart';
import 'support/vault_widget_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final createdAt = DateTime.utc(2026, 7, 1, 10);
  final updatedAt = DateTime.utc(2026, 7, 2, 11);

  LoginItem login({String? website = 'https://mail.test'}) {
    return LoginItem(
      id: 'login-1',
      title: 'Mail',
      username: 'user',
      password: 'secret',
      website: website,
      notes: null,
      categoryId: null,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  BankCardItem card({required String cardNumber}) {
    return BankCardItem(
      id: 'card-1',
      title: 'Travel',
      cardNumber: cardNumber,
      cardHolder: 'Nima',
      expiryDate: '06/30',
      cvv: '321',
      bankName: 'Unknown',
      notes: null,
      categoryId: null,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  VaultListItem listItem(VaultItemType type, {String id = 'item-1'}) {
    return VaultListItem(
      id: id,
      type: type,
      title: 'Title',
      subtitle: 'Subtitle',
      categoryId: '',
    );
  }

  Future<void> pumpIcon(
    WidgetTester tester, {
    required VaultListItem item,
    Object? source,
  }) async {
    setupVaultWidgetSurface(tester);
    await tester.pumpWidget(
      vaultTestApp(
        home: Scaffold(
          body: VaultListItemIcon(item: item, source: source),
        ),
      ),
    );
    await pumpVaultFrame(tester);
  }

  tearDown(() async {
    await getIt.reset();
  });

  testWidgets('valid website uses the cached remote image', (tester) async {
    final fake = FakeCachedRemoteImage();
    getIt.registerSingleton<CachedRemoteImage>(fake);

    await pumpIcon(
      tester,
      item: listItem(VaultItemType.login),
      source: login(),
    );

    expect(find.byType(LoginFaviconWidget), findsOneWidget);
    expect(find.byKey(const Key('login-favicon')), findsOneWidget);
    expect(find.byKey(const Key('fake-cached-remote-image')), findsOneWidget);
    expect(fake.lastCacheKey, 'favicon:mail.test');
    expect(fake.lastUrl, contains('mail.test'));
  });

  testWidgets('missing website uses the login fallback icon', (tester) async {
    await pumpIcon(
      tester,
      item: listItem(VaultItemType.login),
      source: login(website: null),
    );

    expect(find.byKey(const Key('login-favicon')), findsNothing);
    expect(find.byIcon(AppIcon.lock), findsOneWidget);
  });

  testWidgets('invalid website uses the login fallback icon', (tester) async {
    await pumpIcon(
      tester,
      item: listItem(VaultItemType.login),
      source: login(website: '   '),
    );

    expect(find.byKey(const Key('login-favicon')), findsNothing);
    expect(find.byIcon(AppIcon.lock), findsOneWidget);
  });

  testWidgets('failed favicon load uses the login fallback icon', (tester) async {
    getIt.registerSingleton<CachedRemoteImage>(FakeCachedRemoteImage(fail: true));

    await pumpIcon(
      tester,
      item: listItem(VaultItemType.login),
      source: login(),
    );

    expect(find.byKey(const Key('login-favicon')), findsOneWidget);
    expect(find.byKey(const Key('fake-cached-remote-image')), findsNothing);
    expect(find.byIcon(AppIcon.lock), findsOneWidget);
  });

  testWidgets('known bank displays the local bank logo', (tester) async {
    await pumpIcon(
      tester,
      item: listItem(VaultItemType.bankCard),
      source: card(cardNumber: kSeedBankCardPan),
    );

    expect(find.byType(SvgPicture), findsOneWidget);
    expect(find.byIcon(AppIcon.creditCard), findsNothing);
  });

  testWidgets('unknown bank uses the bank card fallback icon', (tester) async {
    await pumpIcon(
      tester,
      item: listItem(VaultItemType.bankCard),
      source: card(cardNumber: '0000000000000000'),
    );

    expect(find.byType(SvgPicture), findsNothing);
    expect(find.byIcon(AppIcon.creditCard), findsOneWidget);
  });

  testWidgets('note items use the type icon', (tester) async {
    await pumpIcon(
      tester,
      item: listItem(VaultItemType.secureNote),
      source: SecureNoteItem(
        id: 'note-1',
        title: 'Gate',
        content: 'code',
        categoryId: null,
        createdAt: createdAt,
        updatedAt: updatedAt,
      ),
    );

    expect(find.byIcon(AppIcon.stickyNote), findsOneWidget);
  });
}
