import 'package:flutter_test/flutter_test.dart';
import 'package:keyva/core/store/store_config.dart';
import 'package:keyva/core/store/store_type.dart';

void main() {
  group('StoreConfig.bazaar', () {
    late StoreConfig config;

    setUp(() {
      config = StoreConfig.bazaar();
    });

    test('uses Bazaar store type, package, and review action', () {
      expect(config.store, StoreType.bazaar);
      expect(config.packageId, StoreConfig.defaultPackageId);
      expect(config.storeAppPackage, StoreConfig.bazaarStorePackage);
      expect(config.reviewIntentAction, StoreIntentAction.edit);
    });

    test('selects Bazaar Keyva URLs', () {
      expect(
        config.keyvaStoreUrl,
        'https://cafebazaar.ir/app/${StoreConfig.defaultPackageId}',
      );
      expect(config.detailsWebUrl, config.keyvaStoreUrl);
      expect(
        config.reviewNativeUri,
        'bazaar://details?id=${StoreConfig.defaultPackageId}',
      );
      expect(
        config.detailsNativeUri,
        'bazaar://details?id=${StoreConfig.defaultPackageId}',
      );
    });

    test('does not emit Myket URLs', () {
      expect(config.keyvaStoreUrl, isNot(contains('myket.ir')));
      expect(config.detailsWebUrl, isNot(contains('myket.ir')));
      expect(config.reviewNativeUri, isNot(contains('myket://')));
      expect(config.detailsNativeUri, isNot(contains('myket://')));
      expect(config.otherAppsNativeUri, isNot(contains('myket://')));
      expect(config.otherAppsWebUrl, isNot(contains('myket.ir')));
    });
  });

  group('StoreConfig.myket', () {
    late StoreConfig config;

    setUp(() {
      config = StoreConfig.myket();
    });

    test('uses Myket store type, package, and review action', () {
      expect(config.store, StoreType.myket);
      expect(config.packageId, StoreConfig.defaultPackageId);
      expect(config.storeAppPackage, StoreConfig.myketStorePackage);
      expect(config.reviewIntentAction, StoreIntentAction.view);
    });

    test('selects Myket Keyva URLs', () {
      expect(
        config.keyvaStoreUrl,
        'https://myket.ir/app/${StoreConfig.defaultPackageId}',
      );
      expect(config.detailsWebUrl, config.keyvaStoreUrl);
      expect(
        config.reviewNativeUri,
        'myket://comment?id=${StoreConfig.defaultPackageId}',
      );
      expect(
        config.detailsNativeUri,
        'myket://details?id=${StoreConfig.defaultPackageId}',
      );
    });

    test('does not emit Bazaar URLs', () {
      expect(config.keyvaStoreUrl, isNot(contains('cafebazaar.ir')));
      expect(config.detailsWebUrl, isNot(contains('cafebazaar.ir')));
      expect(config.reviewNativeUri, isNot(contains('bazaar://')));
      expect(config.detailsNativeUri, isNot(contains('bazaar://')));
      expect(config.otherAppsNativeUri, isNot(contains('bazaar://')));
      expect(config.otherAppsWebUrl, isNot(contains('cafebazaar.ir')));
    });
  });

  test('fromEnvironment defaults to Bazaar when STORE is unset', () {
    expect(StoreConfig.fromEnvironment().store, StoreType.bazaar);
  });

  test('forStoreName maps myket and unknown values', () {
    expect(StoreConfig.forStoreName('myket').store, StoreType.myket);
    expect(StoreConfig.forStoreName('MYKET').store, StoreType.myket);
    expect(StoreConfig.forStoreName('bazaar').store, StoreType.bazaar);
    expect(StoreConfig.forStoreName('unknown').store, StoreType.bazaar);
  });

  test('hasOtherAppsListing is false when both listing URLs are empty', () {
    expect(StoreConfig.bazaar().hasOtherAppsListing, isFalse);
    expect(StoreConfig.myket().hasOtherAppsListing, isFalse);
  });
}
