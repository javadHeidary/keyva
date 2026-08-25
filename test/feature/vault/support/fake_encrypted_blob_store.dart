import 'dart:typed_data';

import 'package:keyva/core/exceptions/app_failure.dart';
import 'package:keyva/core/exceptions/result.dart';
import 'package:keyva/feature/vault/blob/encrypted_blob_store.dart';

class FakeEncryptedBlobStore implements EncryptedBlobStore {
  FakeEncryptedBlobStore({this.generateId});

  final String Function()? generateId;
  final Map<String, Uint8List> files = {};
  Map<String, Uint8List>? _replaceSnapshot;
  int writeCount = 0;
  int deleteCount = 0;
  int clearCacheCount = 0;
  AppFailure? writeFailure;
  AppFailure? readFailure;
  var nextId = 0;

  @override
  Future<Result<String>> write(Uint8List plaintext) async {
    writeCount++;
    final failure = writeFailure;
    if (failure != null) {
      return FailureResult(failure);
    }
    final blobId = generateId?.call() ?? _nextId();
    files[blobId] = Uint8List.fromList(plaintext);
    return Success(blobId);
  }

  @override
  Future<Result<void>> writeWithId({
    required String blobId,
    required Uint8List plaintext,
  }) async {
    writeCount++;
    final failure = writeFailure;
    if (failure != null) {
      return FailureResult(failure);
    }
    files[blobId] = Uint8List.fromList(plaintext);
    return const Success(null);
  }

  @override
  Future<Result<Uint8List>> read(String blobId) async {
    final failure = readFailure;
    if (failure != null) {
      return FailureResult(failure);
    }
    final bytes = files[blobId];
    if (bytes == null) {
      return const FailureResult(ValidationFailure());
    }
    return Success(Uint8List.fromList(bytes));
  }

  @override
  Future<Result<void>> delete(String blobId) {
    return deleteMany([blobId]);
  }

  @override
  Future<Result<void>> deleteMany(Iterable<String> blobIds) async {
    deleteCount++;
    for (final id in blobIds) {
      files.remove(id);
    }
    return const Success(null);
  }

  @override
  Future<Result<void>> replaceAll(Map<String, Uint8List> blobs) async {
    final installed = await installReplace(blobs);
    if (installed is FailureResult<void>) {
      return installed;
    }
    return finalizeReplace();
  }

  @override
  Future<Result<void>> installReplace(Map<String, Uint8List> blobs) async {
    final failure = writeFailure;
    if (failure != null) {
      return FailureResult(failure);
    }
    _replaceSnapshot = {
      for (final entry in files.entries)
        entry.key: Uint8List.fromList(entry.value),
    };
    files
      ..clear()
      ..addAll({
        for (final entry in blobs.entries)
          entry.key: Uint8List.fromList(entry.value),
      });
    return const Success(null);
  }

  @override
  Future<Result<void>> rollbackReplace() async {
    final snapshot = _replaceSnapshot;
    if (snapshot == null) {
      return const Success(null);
    }
    files
      ..clear()
      ..addAll(snapshot);
    _replaceSnapshot = null;
    return const Success(null);
  }

  @override
  Future<Result<void>> finalizeReplace() async {
    _replaceSnapshot = null;
    return const Success(null);
  }

  @override
  Future<Result<void>> deleteAllForCurrentUser() async {
    files.clear();
    _replaceSnapshot = null;
    return const Success(null);
  }

  @override
  Future<Result<void>> deleteAllForUser(String userId) {
    return deleteAllForCurrentUser();
  }

  @override
  void clearCache() {
    clearCacheCount++;
  }

  String _nextId() {
    nextId++;
    return nextId.toRadixString(16).padLeft(32, '0');
  }
}
