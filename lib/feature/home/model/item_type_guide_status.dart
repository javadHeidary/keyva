enum ItemTypeGuideStatus { unseen, acknowledged, dismissed, sampleCreated }

extension ItemTypeGuideStatusX on ItemTypeGuideStatus {
  bool get isVisible => this == ItemTypeGuideStatus.unseen;

  static ItemTypeGuideStatus fromStorage(String? value) {
    if (value == null || value.isEmpty) {
      return ItemTypeGuideStatus.unseen;
    }
    for (final status in ItemTypeGuideStatus.values) {
      if (status.name == value) {
        return status;
      }
    }
    return ItemTypeGuideStatus.unseen;
  }
}
