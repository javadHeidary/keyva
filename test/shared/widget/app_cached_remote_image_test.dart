import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keyva/core/di/injection_container.dart';
import 'package:keyva/core/image/cached_remote_image.dart';
import 'package:keyva/shared/widget/app_cached_remote_image.dart';

import '../../core/image/fake_cached_remote_image.dart';
import '../../feature/vault/support/vault_widget_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const fallback = Key('fallback');

  Widget subject({CachedRemoteImage? loader}) {
    return vaultTestApp(
      home: Scaffold(
        body: AppCachedRemoteImage(
          url: 'https://example.test/icon.png',
          width: 40,
          height: 40,
          cacheKey: 'favicon:example.test',
          loader: loader,
          errorWidget: const SizedBox(key: fallback),
        ),
      ),
    );
  }

  tearDown(() async {
    await getIt.reset();
  });

  testWidgets('uses the injected loader', (tester) async {
    setupVaultWidgetSurface(tester);
    final fake = FakeCachedRemoteImage();
    await tester.pumpWidget(subject(loader: fake));
    await pumpVaultFrame(tester);

    expect(find.byKey(const Key('fake-cached-remote-image')), findsOneWidget);
    expect(find.byKey(fallback), findsNothing);
    expect(fake.lastCacheKey, 'favicon:example.test');
  });

  testWidgets('shows error widget when no loader is registered', (tester) async {
    setupVaultWidgetSurface(tester);
    await tester.pumpWidget(subject());
    await pumpVaultFrame(tester);

    expect(find.byKey(fallback), findsOneWidget);
    expect(find.byKey(const Key('fake-cached-remote-image')), findsNothing);
  });

  testWidgets('uses GetIt when registered', (tester) async {
    setupVaultWidgetSurface(tester);
    final fake = FakeCachedRemoteImage();
    getIt.registerSingleton<CachedRemoteImage>(fake);

    await tester.pumpWidget(subject());
    await pumpVaultFrame(tester);

    expect(find.byKey(const Key('fake-cached-remote-image')), findsOneWidget);
  });
}
