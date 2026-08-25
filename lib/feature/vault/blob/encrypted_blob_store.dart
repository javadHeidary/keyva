import 'dart:typed_data';

import 'package:keyva/core/exceptions/result.dart';

abstract interface class EncryptedBlobStore {
  Future<Result<String>> write(Uint8List plaintext);

  Future<Result<void>> writeWithId({
    required String blobId,
    required Uint8List plaintext,
  });

  Future<Result<Uint8List>> read(String blobId);

  Future<Result<void>> delete(String blobId);

  Future<Result<void>> deleteMany(Iterable<String> blobIds);

  Future<Result<void>> replaceAll(Map<String, Uint8List> blobs);

  /// Writes [blobs] into the live directory after staging. Previous files stay
  /// available for [rollbackReplace] until [finalizeReplace].
  Future<Result<void>> installReplace(Map<String, Uint8List> blobs);

  Future<Result<void>> rollbackReplace();

  Future<Result<void>> finalizeReplace();

  Future<Result<void>> deleteAllForCurrentUser();

  Future<Result<void>> deleteAllForUser(String userId);

  void clearCache();
}
