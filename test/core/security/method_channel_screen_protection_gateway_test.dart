import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keyva/core/exceptions/app_failure.dart';
import 'package:keyva/core/exceptions/result.dart';
import 'package:keyva/core/security/method_channel_screen_protection_gateway.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
  });

  test('non-Android platforms succeed without a plugin', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    final gateway = MethodChannelScreenProtectionGateway();
    expect(await gateway.setSecure(true), isA<Success<void>>());
  });

  test('Android MethodChannel sends only the enabled flag', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    const channel = MethodChannel(
      MethodChannelScreenProtectionGateway.channelName,
    );
    MethodCall? captured;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          captured = call;
          return null;
        });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    final gateway = MethodChannelScreenProtectionGateway(channel: channel);
    expect(await gateway.setSecure(true), isA<Success<void>>());
    expect(captured!.method, MethodChannelScreenProtectionGateway.methodSetSecure);
    expect(captured!.arguments, {'enabled': true});
  });

  test('Android plugin failure maps to ScreenProtectionFailure', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    const channel = MethodChannel(
      MethodChannelScreenProtectionGateway.channelName,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          throw PlatformException(
            code: 'screen_protection_failed',
            message: 'Unable to update screen capture protection',
          );
        });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    final gateway = MethodChannelScreenProtectionGateway(channel: channel);
    final result = await gateway.setSecure(false);
    expect(result, isA<FailureResult<void>>());
    expect(
      (result as FailureResult<void>).failure,
      isA<ScreenProtectionFailure>(),
    );
  });
}
