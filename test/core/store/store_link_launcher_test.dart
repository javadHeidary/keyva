import 'package:flutter_test/flutter_test.dart';
import 'package:keyva/core/store/store_link_launcher_impl.dart';

void main() {
  test('launchNative returns false for an empty URI', () async {
    final launcher = StoreLinkLauncherImpl(
      launchNativeFn: ({required action, required uri, package}) async => true,
    );

    expect(
      await launcher.launchNative(
        action: 'android.intent.action.VIEW',
        uri: '',
      ),
      isFalse,
    );
    expect(
      await launcher.launchNative(action: '', uri: 'bazaar://details?id=x'),
      isFalse,
    );
  });

  test('launchExternalUrl returns false for an empty URL', () async {
    final launcher = StoreLinkLauncherImpl(launchUrlFn: (_) async => true);

    expect(await launcher.launchExternalUrl(''), isFalse);
    expect(await launcher.launchExternalUrl('   '), isFalse);
  });

  test('launchNative swallows failures and returns false', () async {
    final launcher = StoreLinkLauncherImpl(
      launchNativeFn: ({required action, required uri, package}) async {
        throw StateError('unavailable');
      },
    );

    expect(
      await launcher.launchNative(
        action: 'android.intent.action.EDIT',
        uri: 'bazaar://details?id=com.keyva.app',
      ),
      isFalse,
    );
  });

  test('launchExternalUrl uses the injected URL launcher', () async {
    Uri? launched;
    final launcher = StoreLinkLauncherImpl(
      launchUrlFn: (uri) async {
        launched = uri;
        return true;
      },
    );

    expect(
      await launcher.launchExternalUrl(
        'https://cafebazaar.ir/app/com.keyva.app',
      ),
      isTrue,
    );
    expect(launched, Uri.parse('https://cafebazaar.ir/app/com.keyva.app'));
  });
}
