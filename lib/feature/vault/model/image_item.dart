class ImageItem {
  const ImageItem({
    required this.id,
    required this.folderId,
    required this.note,
    required this.blobId,
    required this.thumbnailBlobId,
    required this.mimeType,
    required this.width,
    required this.height,
    required this.createdAt,
  });

  final String id;
  final String folderId;
  final String? note;
  final String blobId;
  final String thumbnailBlobId;
  final String mimeType;
  final int width;
  final int height;
  final DateTime createdAt;

  ImageItem copyWith({
    String? id,
    String? folderId,
    String? note,
    String? blobId,
    String? thumbnailBlobId,
    String? mimeType,
    int? width,
    int? height,
    DateTime? createdAt,
  }) {
    return ImageItem(
      id: id ?? this.id,
      folderId: folderId ?? this.folderId,
      note: note ?? this.note,
      blobId: blobId ?? this.blobId,
      thumbnailBlobId: thumbnailBlobId ?? this.thumbnailBlobId,
      mimeType: mimeType ?? this.mimeType,
      width: width ?? this.width,
      height: height ?? this.height,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ImageItem &&
        id == other.id &&
        folderId == other.folderId &&
        note == other.note &&
        blobId == other.blobId &&
        thumbnailBlobId == other.thumbnailBlobId &&
        mimeType == other.mimeType &&
        width == other.width &&
        height == other.height &&
        createdAt == other.createdAt;
  }

  @override
  int get hashCode => Object.hash(
    id,
    folderId,
    note,
    blobId,
    thumbnailBlobId,
    mimeType,
    width,
    height,
    createdAt,
  );
}
