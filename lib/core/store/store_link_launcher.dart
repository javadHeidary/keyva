abstract interface class StoreLinkLauncher {
  Future<bool> launchNative({
    required String action,
    required String uri,
    String? package,
  });

  Future<bool> launchExternalUrl(String url);
}
