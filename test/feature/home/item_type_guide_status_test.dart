import 'package:flutter_test/flutter_test.dart';
import 'package:keyva/feature/home/model/item_type_guide_status.dart';

void main() {
  test('missing storage values are unseen and visible', () {
    expect(ItemTypeGuideStatusX.fromStorage(null), ItemTypeGuideStatus.unseen);
    expect(ItemTypeGuideStatus.unseen.isVisible, isTrue);
  });

  test('known storage values round-trip and hide the icon', () {
    expect(
      ItemTypeGuideStatusX.fromStorage('acknowledged'),
      ItemTypeGuideStatus.acknowledged,
    );
    expect(
      ItemTypeGuideStatusX.fromStorage('dismissed'),
      ItemTypeGuideStatus.dismissed,
    );
    expect(
      ItemTypeGuideStatusX.fromStorage('sampleCreated'),
      ItemTypeGuideStatus.sampleCreated,
    );
    expect(ItemTypeGuideStatus.acknowledged.isVisible, isFalse);
    expect(ItemTypeGuideStatus.dismissed.isVisible, isFalse);
    expect(ItemTypeGuideStatus.sampleCreated.isVisible, isFalse);
  });

  test('unknown storage values fall back to unseen', () {
    expect(
      ItemTypeGuideStatusX.fromStorage('not-a-status'),
      ItemTypeGuideStatus.unseen,
    );
  });
}
