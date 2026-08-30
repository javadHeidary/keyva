import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:keyva/core/exceptions/app_failure.dart';
import 'package:keyva/core/exceptions/result.dart';
import 'package:keyva/core/security/screen_protection_gateway.dart';

class MethodChannelScreenProtectionGateway implements ScreenProtectionGateway {
  MethodChannelScreenProtectionGateway({MethodChannel? channel})
    : _channel =
          channel ??
          const MethodChannel(MethodChannelScreenProtectionGateway.channelName);

  static const channelName = 'com.keyva.app/screen_protection';
  static const methodSetSecure = 'setSecure';

  final MethodChannel _channel;

  @override
  Future<Result<void>> setSecure(bool enabled) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return const Success(null);
    }
    try {
      await _channel.invokeMethod<void>(methodSetSecure, {'enabled': enabled});
      return const Success(null);
    } on MissingPluginException {
      return const FailureResult(ScreenProtectionFailure());
    } on PlatformException {
      return const FailureResult(ScreenProtectionFailure());
    } catch (_) {
      return const FailureResult(ScreenProtectionFailure());
    }
  }
}
