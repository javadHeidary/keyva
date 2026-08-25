import 'package:keyva/core/store/store_type.dart';

class StoreIntentAction {
  const StoreIntentAction._();

  static const view = 'android.intent.action.VIEW';
  static const edit = 'android.intent.action.EDIT';
}

class StoreConfig {
  const StoreConfig({
    required this.store,
    required this.packageId,
    required this.keyvaStoreUrl,
    required this.reviewNativeUri,
    required this.detailsNativeUri,
    required this.detailsWebUrl,
    required this.otherAppsNativeUri,
    required this.otherAppsWebUrl,
    required this.reviewIntentAction,
    required this.storeAppPackage,
  });

  static const defaultPackageId = 'com.example.keyva';

  /// Cafe Bazaar developer listing. Fill before store release.
  static const bazaarOtherAppsNativeUri = '';
  static const bazaarOtherAppsWebUrl = '';

  /// Myket developer listing. Fill before store release.
  static const myketOtherAppsNativeUri = '';
  static const myketOtherAppsWebUrl = '';

  static const bazaarStorePackage = 'com.farsitel.bazaar';
  static const myketStorePackage = 'ir.mservices.market';

  final StoreType store;
  final String packageId;
  final String keyvaStoreUrl;
  final String reviewNativeUri;
  final String detailsNativeUri;
  final String detailsWebUrl;
  final String otherAppsNativeUri;
  final String otherAppsWebUrl;
  final String reviewIntentAction;
  final String storeAppPackage;

  bool get hasOtherAppsListing {
    return otherAppsNativeUri.trim().isNotEmpty ||
        otherAppsWebUrl.trim().isNotEmpty;
  }

  factory StoreConfig.fromEnvironment() {
    const name = String.fromEnvironment('STORE', defaultValue: 'bazaar');
    return StoreConfig.forStoreName(name);
  }

  factory StoreConfig.forStoreName(String name) {
    switch (name.toLowerCase().trim()) {
      case 'myket':
        return StoreConfig.myket();
      default:
        return StoreConfig.bazaar();
    }
  }

  factory StoreConfig.bazaar() {
    return const StoreConfig(
      store: StoreType.bazaar,
      packageId: defaultPackageId,
      keyvaStoreUrl: 'https://cafebazaar.ir/app/$defaultPackageId',
      reviewNativeUri: 'bazaar://details?id=$defaultPackageId',
      detailsNativeUri: 'bazaar://details?id=$defaultPackageId',
      detailsWebUrl: 'https://cafebazaar.ir/app/$defaultPackageId',
      otherAppsNativeUri: bazaarOtherAppsNativeUri,
      otherAppsWebUrl: bazaarOtherAppsWebUrl,
      reviewIntentAction: StoreIntentAction.edit,
      storeAppPackage: bazaarStorePackage,
    );
  }

  factory StoreConfig.myket() {
    return const StoreConfig(
      store: StoreType.myket,
      packageId: defaultPackageId,
      keyvaStoreUrl: 'https://myket.ir/app/$defaultPackageId',
      reviewNativeUri: 'myket://comment?id=$defaultPackageId',
      detailsNativeUri: 'myket://details?id=$defaultPackageId',
      detailsWebUrl: 'https://myket.ir/app/$defaultPackageId',
      otherAppsNativeUri: myketOtherAppsNativeUri,
      otherAppsWebUrl: myketOtherAppsWebUrl,
      reviewIntentAction: StoreIntentAction.view,
      storeAppPackage: myketStorePackage,
    );
  }
}
