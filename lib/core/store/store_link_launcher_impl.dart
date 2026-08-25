import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/foundation.dart';
import 'package:keyva/core/store/store_link_launcher.dart';
import 'package:url_launcher/url_launcher.dart';

typedef StoreNativeLaunch =
    Future<bool> Function({
      required String action,
      required String uri,
      String? package,
    });

typedef StoreUrlLaunch = Future<bool> Function(Uri uri);

class StoreLinkLauncherImpl implements StoreLinkLauncher {
  StoreLinkLauncherImpl({
    StoreNativeLaunch? launchNativeFn,
    StoreUrlLaunch? launchUrlFn,
  }) : _launchNative = launchNativeFn ?? _defaultNativeLaunch,
       _launchUrl = launchUrlFn ?? _defaultUrlLaunch;

  final StoreNativeLaunch _launchNative;
  final StoreUrlLaunch _launchUrl;

  static Future<bool> _defaultNativeLaunch({
    required String action,
    required String uri,
    String? package,
  }) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }

    try {
      final intent = AndroidIntent(action: action, data: uri, package: package);
      await intent.launch();
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> _defaultUrlLaunch(Uri uri) {
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Future<bool> launchNative({
    required String action,
    required String uri,
    String? package,
  }) async {
    if (uri.trim().isEmpty || action.trim().isEmpty) {
      return false;
    }

    try {
      return await _launchNative(
        action: action,
        uri: uri.trim(),
        package: package,
      );
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> launchExternalUrl(String url) async {
    final trimmed = url.trim();
    if (trimmed.isEmpty) {
      return false;
    }

    try {
      return await _launchUrl(Uri.parse(trimmed));
    } catch (_) {
      return false;
    }
  }
}
